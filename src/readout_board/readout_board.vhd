-- TODO: connect tx_dis to control path
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library lpgbt_fpga;
use lpgbt_fpga.lpgbtfpga_package.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_ctrl.all;

library work;
use work.types.all;
use work.lpgbt_pkg.all;
use work.components.all;

library ipbus;
use ipbus.ipbus.all;

library etroc;

entity readout_board is
  generic(
    INST            : integer := 0;
    C_DEBUG         : boolean := true;
    NUM_LPGBTS_DAQ  : integer := 1;
    NUM_LPGBTS_TRIG : integer := 1;
    NUM_DOWNLINKS   : integer := 1;
    NUM_SCAS        : integer := 1
    );
  port(

    clk40  : in std_logic;
    clk320 : in std_logic;

    reset : in std_logic;

    --tx_ready : in std_logic;
    --rx_ready : in std_logic;

    trigger_i : in std_logic;
    trigger_o : out std_logic;

    ctrl_clk : in  std_logic;
    mon      : out READOUT_BOARD_MON_t;
    ctrl     : in  READOUT_BOARD_CTRL_t;

    daq_wb_in  : in  ipb_wbus_array(0 downto 0);
    daq_wb_out : out ipb_rbus_array(0 downto 0);

    uplink_bitslip          : out std_logic_vector (NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG-1 downto 0);
    uplink_mgt_word_array   : in  std32_array_t (NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG-1 downto 0);
    downlink_mgt_word_array : out std32_array_t (NUM_DOWNLINKS-1 downto 0)

    );
end readout_board;

architecture behavioral of readout_board is

  constant NUM_UPLINKS : integer := NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG;

  constant FREQ : integer := 320;       -- uplink frequency

  constant DOWNWIDTH  : integer := 8;
  constant UPWIDTH    : integer := FREQ/40;
  constant NUM_ELINKS : integer := 224/UPWIDTH;  -- FIXME: account for fec5/12

  signal valid : std_logic;

  --------------------------------------------------------------------------------
  -- FEC Error Counters
  --------------------------------------------------------------------------------

  constant COUNTER_WIDTH : integer := 16;
  type counter_array_t is array (integer range <>)
    of std_logic_vector(COUNTER_WIDTH-1 downto 0);

  -- counters
  signal uplink_fec_err_cnt : counter_array_t(NUM_UPLINKS-1 downto 0);

  --------------------------------------------------------------------------------
  -- LPGBT Glue
  --------------------------------------------------------------------------------

  signal uplink_data_aligned : lpgbt_uplink_data_rt_array (NUM_UPLINKS-1 downto 0);
  signal uplink_data         : lpgbt_uplink_data_rt_array (NUM_UPLINKS-1 downto 0);
  signal uplink_reset        : std_logic_vector (NUM_UPLINKS-1 downto 0);
  signal uplink_ready        : std_logic_vector (NUM_UPLINKS-1 downto 0);
  signal uplink_fec_err      : std_logic_vector (NUM_UPLINKS-1 downto 0);

  signal downlink_data         : lpgbt_downlink_data_rt_array (NUM_DOWNLINKS-1 downto 0);
  signal downlink_data_aligned : lpgbt_downlink_data_rt_array (NUM_DOWNLINKS-1 downto 0);
  signal downlink_reset        : std_logic_vector (NUM_DOWNLINKS-1 downto 0);
  signal downlink_ready        : std_logic_vector (NUM_DOWNLINKS-1 downto 0);

  -- master

  signal prbs_err_counters  : std32_array_t (NUM_UPLINKS*NUM_ELINKS-1 downto 0);
  signal upcnt_err_counters : std32_array_t (NUM_UPLINKS*NUM_ELINKS-1 downto 0);

  signal counter : integer range 0 to 255        := 0;
  signal cnt_slv : std_logic_vector (7 downto 0) := (others => '0');

  signal prbs_gen         : std_logic_vector (DOWNWIDTH-1 downto 0) := (others => '0');
  signal prbs_gen_reverse : std_logic_vector (DOWNWIDTH-1 downto 0) := (others => '0');

  signal prbs_ff  : std_logic_vector (31 downto 0) := (others => '0');
  signal upcnt_ff : std_logic_vector (31 downto 0) := (others => '0');

  -- don't care too much about bus coherence here.. the counters should just be zero
  -- and exact numbers don't really matter..
  attribute ASYNC_REG             : string;
  attribute ASYNC_REG of prbs_ff  : signal is "true";
  attribute ASYNC_REG of upcnt_ff : signal is "true";

  signal fast_cmd_fw : std_logic_vector (7 downto 0) := (others => '0');

  --------------------------------------------------------------------------------
  -- FIFO
  --------------------------------------------------------------------------------

  signal fifo_full  : std_logic_vector (1 downto 0) := (others => '0');
  signal fifo_empty : std_logic_vector (1 downto 0) := (others => '0');
  signal fifo_armed : std_logic_vector (1 downto 0) := (others => '0');

  type int_array_t is array (integer range <>) of integer;

  signal elink_sel : integer range 0 to 27;
  signal lpgbt_sel : integer range 0 to 1;
  signal link_sel  : integer range 0 to 28*2-1;

  --------------------------------------------------------------------------------
  -- TTC
  --------------------------------------------------------------------------------

  signal trigger_rate   : std_logic_vector (31 downto 0);
  signal packet_rx_rate : std_logic_vector (31 downto 0);
  signal packet_cnt     : std16_array_t(28*NUM_UPLINKS-1 downto 0);
  signal err_cnt        : std16_array_t(28*NUM_UPLINKS-1 downto 0);

  signal l1a_gen    : std_logic               := '0';
  signal l1a        : std_logic               := '0';
  signal bc0        : std_logic               := '0';
  signal link_reset : std_logic               := '0';
  signal bxn        : natural range 0 to 3563 := 0;

  --------------------------------------------------------------------------------
  -- ETROC RX
  --------------------------------------------------------------------------------

  type rx_frame_array_t is array (integer range <>) of std_logic_vector(39 downto 0);
  type rx_state_array_t is array (integer range <>) of std_logic_vector(2 downto 0);

  signal rx_frame_mon_arr  : rx_frame_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_state_mon_arr  : rx_state_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_data_arr  : rx_frame_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_wr_en_arr : std_logic_vector(28*NUM_UPLINKS-1 downto 0);

  -- ETROC CRC
  constant CRCBITS : integer := 8;
  type rx_crc_array_t is array (integer range <>) of std_logic_vector(CRCBITS-1 downto 0);
  signal rx_crc_arr      : rx_crc_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_crc_calc_arr : rx_crc_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_crc          : std_logic_vector(CRCBITS-1 downto 0);
  signal rx_crc_calc     : std_logic_vector(CRCBITS-1 downto 0);
  signal rx_crc_match    : std_logic := '0';

  signal rx_locked          : std_logic_vector(28*NUM_UPLINKS-1 downto 0);
  signal rx_start_of_packet : std_logic_vector(28*NUM_UPLINKS-1 downto 0);
  signal rx_end_of_packet   : std_logic_vector(28*NUM_UPLINKS-1 downto 0);
  signal rx_busy            : std_logic_vector (28*NUM_UPLINKS-1 downto 0);
  signal rx_idle            : std_logic_vector (28*NUM_UPLINKS-1 downto 0);
  signal rx_err             : std_logic_vector (28*NUM_UPLINKS-1 downto 0);

  signal rx_fifo_data, rx_fifo_data_mux   : std_logic_vector (39 downto 0) := (others => '0');
  signal rx_fifo_wr_en, rx_fifo_wr_en_mux : std_logic;

begin


  --------------------------------------------------------------------------------
  -- create 1/8 strobe synced to 40MHz clock
  --------------------------------------------------------------------------------

  clock_strobe_inst : entity work.clock_strobe
    generic map (
      RATIO => 8
      )
    port map (
      fast_clk_i => clk320,
      slow_clk_i => clk40,
      strobe_o   => valid
      );

  --------------------------------------------------------------------------------
  -- Downlink Data Generation
  --------------------------------------------------------------------------------

  -- up counter

  cnt_slv <= std_logic_vector (to_unsigned(counter, cnt_slv'length));
  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (counter = 255) then
        counter <= 0;
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;

  -- prbs generation

  prbs_any_gen : entity work.prbs_any
    generic map (
      chk_mode    => false,
      inv_pattern => false,
      poly_lenght => 7,
      poly_tap    => 6,
      nbits       => 8
      )
    port map (
      rst      => reset,
      clk      => clk40,
      data_in  => (others => '0'),
      en       => '1',
      data_out => prbs_gen
      );

  -- need to reverse the prbs vector to match lpgbt


  --------------------------------------------------------------------------------
  -- lpgbt downlink multiplexing
  --------------------------------------------------------------------------------
  --
  -- Choose between different data sources
  --
  --  + up count
  --  + prbs-7 generation
  --  + programmable fast command

  dl_assign : for I in 0 to NUM_DOWNLINKS-1 generate

    function repeat_byte (x : std_logic_vector) return std_logic_vector is
      variable result : std_logic_vector(x'length*4-1 downto 0);
    begin
      result := x & x & x & x;
      return result;
    end;

    signal dl_src : integer;

  begin

    dl_src <= to_integer(unsigned(ctrl.lpgbt.daq.downlink.dl_src));

    process (clk40) is
    begin
      if (rising_edge(clk40)) then
        case dl_src is

          when 0 =>
            downlink_data(I).data <= repeat_byte(fast_cmd_fw);
          when 1 =>
            downlink_data(I).data <= repeat_byte(cnt_slv);
          when 2 =>
            downlink_data(I).data <= repeat_byte(prbs_gen_reverse);
          when 3 =>
            downlink_data(I).data <= repeat_byte(fast_cmd_fw);
          when others =>
            downlink_data(I).data <= repeat_byte(fast_cmd_fw);

        end case;
      end if;
    end process;
  end generate;

  etroc_tx_inst : entity etroc.etroc_tx
    port map (
      clock      => clk40,
      reset      => reset,
      l1a        => l1a,
      bc0        => bc0,
      link_reset => link_reset,
      data_o     => fast_cmd_fw
      );

  trig_gen_inst : entity work.trig_gen
    port map (
      sys_clk    => clk40,
      sys_rst    => reset,
      sys_bx_stb => '1',
      rate       => ctrl.l1a_rate,
      trig       => l1a_gen
      );


  bc0 <= '1' when bxn = 0 else '0';

  l1a        <= ctrl.l1a_pulse or l1a_gen or (trigger_i and ctrl.en_ext_trigger);
  link_reset <= ctrl.link_reset_pulse;

  trigger_o <= l1a;

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (bxn = 3563) then
        bxn <= 0;
      else
        bxn <= bxn + 1;
      end if;
    end if;
  end process;

  rate_counter_inst : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => x"02638e98",
      g_COUNTER_WIDTH => 32
      )
    port map (
      clk_i   => clk40,
      reset_i => reset,
      en_i    => l1a,
      rate_o  => trigger_rate
      );

  pkt_counter_inst : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => x"02638e98",
      g_COUNTER_WIDTH => 32
      )
    port map (
      clk_i   => clk40,
      reset_i => reset,
      en_i    => or_reduce(rx_end_of_packet),
      rate_o  => packet_rx_rate
      );

  etroc_rx_cnt_gen : for I in rx_end_of_packet'range generate
  begin

    pkt_counter  : entity work.counter
      generic map (width => 16)
      port map (
        clk    => clk40,
        reset  => reset or ctrl.packet_cnt_reset,
        enable => '1',
        event  => rx_end_of_packet(I),
        count  => packet_cnt(I),
        at_max => open
        );

    err_counter  : entity work.counter
      generic map (width => 16)
      port map (
        clk    => clk40,
        reset  => reset or ctrl.err_cnt_reset,
        enable => '1',
        event  => rx_err(I),
        count  => err_cnt(I),
        at_max => open
        );

  end generate;

  mon.l1a_rate_cnt   <= trigger_rate;
  mon.packet_rx_rate <= packet_rx_rate;
  mon.packet_cnt     <= packet_cnt(link_sel);
  mon.error_cnt      <= err_cnt(link_sel);

  --------------------------------------------------------------------------------
  -- Record mapping
  --
  --   + dumb mapping to/from records and internal signals
  --
  --------------------------------------------------------------------------------

  mon.lpgbt.daq.uplink.ready     <= uplink_ready(0);
  mon.lpgbt.daq.downlink.ready   <= downlink_ready(0);
  mon.lpgbt.trigger.uplink.ready <= uplink_ready(1);
  downlink_reset(0)              <= ctrl.lpgbt.daq.downlink.reset;
  uplink_reset(0)                <= ctrl.lpgbt.daq.uplink.reset;

  trg : if (NUM_LPGBTS_TRIG > 0) generate
    uplink_reset(NUM_LPGBTS_DAQ) <= ctrl.lpgbt.trigger.uplink.reset;
  end generate;

  --------------------------------------------------------------------------------
  -- GBT Slow Control
  --------------------------------------------------------------------------------

  gbt_controller_wrapper_inst : entity work.gbt_controller_wrapper
    generic map (g_SCAS_PER_LPGBT => NUM_SCAS)
    port map (

      reset_i => reset,

      ctrl_clk => ctrl_clk,
      mon      => mon.sc,
      ctrl     => ctrl.sc,

      clk40 => clk40,

      -- TODO: parameterize these outputs in an array to avoid hardcoded sizes
      ic_data_i => uplink_data(0).ic,
      ic_data_o => downlink_data_aligned(0).ic,

      sca0_data_i => uplink_data(0).ec,
      sca0_data_o => downlink_data_aligned(0).ec
      );

  --------------------------------------------------------------------------------
  -- LPGBT Cores
  --------------------------------------------------------------------------------

  lpgbt_link_wrapper : entity work.lpgbt_link_wrapper
    generic map (
      g_UPLINK_FEC    => FEC12,
      g_NUM_DOWNLINKS => NUM_DOWNLINKS,
      g_NUM_UPLINKS   => NUM_UPLINKS
      )
    port map (
      reset => reset,

      downlink_clk => clk320,
      uplink_clk   => clk320,

      downlink_reset_i => downlink_reset,
      uplink_reset_i   => uplink_reset,

      downlink_data_i => downlink_data_aligned,
      uplink_data_o   => uplink_data,

      downlink_mgt_word_array_o => downlink_mgt_word_array,
      uplink_mgt_word_array_i   => uplink_mgt_word_array,

      downlink_ready_o => downlink_ready,
      uplink_ready_o   => uplink_ready,

      uplink_bitslip_o => uplink_bitslip,
      uplink_fec_err_o => uplink_fec_err
      );


  --------------------------------------------------------------------------------
  -- FEC Counters
  --------------------------------------------------------------------------------

  mon.lpgbt.daq.uplink.fec_err_cnt     <= uplink_fec_err_cnt(0);
  mon.lpgbt.trigger.uplink.fec_err_cnt <= uplink_fec_err_cnt(1);

  ulfeccnt : for I in 0 to NUM_UPLINKS-1 generate
  begin
    uplink_fec_counter : entity work.counter
      generic map (width => 16)
      port map (
        clk    => clk40,
        reset  => reset or ctrl.lpgbt.fec_err_reset,
        enable => '1',
        event  => uplink_fec_err(I),
        count  => uplink_fec_err_cnt(I),
        at_max => open
        );
  end generate;

  --------------------------------------------------------------------------------
  -- Downlink Frame Aligner
  --------------------------------------------------------------------------------

  dlvalid : for I in 0 to NUM_DOWNLINKS-1 generate
  begin

    downlink_data_aligned(I).valid <= valid;
  end generate;

  downlink_aligners : for IBYTE in 0 to 3 generate
    signal align_cnt :
      std_logic_vector (integer(ceil(log2(real(DOWNWIDTH))))-1 downto 0);
    -- don't care about bus coherence here..
    -- switching doesn't need to be glitchless
    attribute ASYNC_REG              : string;
    attribute ASYNC_REG of align_cnt : signal is "true";
  begin

    process (clk40) is
    begin
      if (rising_edge(clk40)) then
        case IBYTE is
          when 0 => align_cnt <= ctrl.lpgbt.daq.downlink.align_0;
          when 1 => align_cnt <= ctrl.lpgbt.daq.downlink.align_1;
          when 2 => align_cnt <= ctrl.lpgbt.daq.downlink.align_2;
          when 3 => align_cnt <= ctrl.lpgbt.daq.downlink.align_3;
        end case;
      end if;
    end process;

    dlaligner : for IDOWN in 0 to NUM_DOWNLINKS-1 generate
    begin
      frame_aligner_inst : entity work.frame_aligner
        generic map (WIDTH => DOWNWIDTH)
        port map (
          clock => clk40,
          cnt   => align_cnt,
          din   => downlink_data(IDOWN).data(DOWNWIDTH*(IBYTE+1)-1 downto DOWNWIDTH*IBYTE),
          dout  => downlink_data_aligned(IDOWN).data(DOWNWIDTH*(IBYTE+1)-1 downto DOWNWIDTH*IBYTE)
          );
    end generate;

  end generate;

  --------------------------------------------------------------------------------
  -- Uplink Frame Aligner
  --------------------------------------------------------------------------------

  uplink_aligner_inst : entity work.uplink_aligner
    generic map (
      UPWIDTH     => UPWIDTH,
      NUM_UPLINKS => NUM_UPLINKS,
      NUM_ELINKS  => NUM_ELINKS
      )
    port map (
      clk40            => clk40,
      daq_uplink_ctrl  => ctrl.lpgbt.daq.uplink,
      trig_uplink_ctrl => ctrl.lpgbt.trigger.uplink,
      data_i           => uplink_data,
      data_o           => uplink_data_aligned
      );

  --------------------------------------------------------------------------------
  -- Elink Multiplexer
  --------------------------------------------------------------------------------

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      elink_sel <= to_integer(unsigned(ctrl.fifo_elink_sel0));
      lpgbt_sel <= to_integer(unsigned(std_logic_vector'("" & ctrl.fifo_lpgbt_sel0)));  -- vhdl qualify operator
      link_sel  <= lpgbt_sel*28+elink_sel;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- PRBS/Upcnt Pattern Checking
  --
  -- Look at data coming from the LPGBT, see it it matches expected prbs /
  -- upcount patterns
  --
  --------------------------------------------------------------------------------

  -- TODO: generalize this so the loop doesn't need to be copy pasted for
  -- additional lpgbts just cat together the data field into n*daq + trig inputs
  -- and put it in a loop

  uplink_prbs_checkers : for I in 0 to NUM_UPLINKS-1 generate
    signal prbs_en  : std_logic_vector (31 downto 0) := (others => '0');
    signal upcnt_en : std_logic_vector (31 downto 0) := (others => '0');
  begin
    pat_checker : for J in 0 to NUM_ELINKS-1 generate
      signal data : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
    begin

      g0 : if (I = 0) generate
        prbs_en  <= ctrl.lpgbt.pattern_checker.check_prbs_en_0;
        upcnt_en <= ctrl.lpgbt.pattern_checker.check_upcnt_en_0;
      end generate;

      g1 : if (I = 1) generate
        prbs_en  <= ctrl.lpgbt.pattern_checker.check_prbs_en_1;
        upcnt_en <= ctrl.lpgbt.pattern_checker.check_upcnt_en_1;
      end generate;

      -- copy for timing and align to system 40MHz
      process (clk40) is
      begin
        if (rising_edge(clk40)) then
          data <= uplink_data_aligned(I).data(8*(J+1)-1 downto 8*J);
        end if;
      end process;

      pattern_checker_inst : entity work.pattern_checker
        generic map (
          DEBUG         => false,
          COUNTER_WIDTH => 32,
          WIDTH         => UPWIDTH
          )
        port map (
          clock          => clk40,
          reset          => reset or ctrl.lpgbt.pattern_checker.reset,
          cnt_reset      => reset or ctrl.lpgbt.pattern_checker.cnt_reset,
          data           => data,
          check_prbs     => prbs_en(J),
          check_upcnt    => upcnt_en(J),
          prbs_errors_o  => prbs_err_counters(I*NUM_ELINKS+J),
          upcnt_errors_o => upcnt_err_counters(I*NUM_ELINKS+J)
          );

    end generate;
  end generate;

  -- multiplex the outputs into one register for readout

  process (ctrl_clk) is
    variable sel : integer;
  begin
    if (rising_edge(ctrl_clk)) then
      sel := to_integer(unsigned(ctrl.lpgbt.pattern_checker.sel));

      prbs_ff  <= prbs_err_counters(sel);
      upcnt_ff <= upcnt_err_counters(sel);

      mon.lpgbt.pattern_checker.prbs_errors  <= prbs_ff;
      mon.lpgbt.pattern_checker.upcnt_errors <= upcnt_ff;
    end if;
  end process;

  -- create a long (64 bit) timer to record how long the prbs tests have been running

  timer : entity work.counter
    generic map (
      roll_over   => false,
      async_reset => false,
      width       => 64
      )
    port map (
      clk                 => clk40,
      reset               => reset or ctrl.lpgbt.pattern_checker.reset or ctrl.lpgbt.pattern_checker.cnt_reset,
      enable              => '1',
      event               => '1',
      count(31 downto 0)  => mon.lpgbt.pattern_checker.timer_lsbs,
      count(63 downto 32) => mon.lpgbt.pattern_checker.timer_msbs,
      at_max              => open
      );

  --------------------------------------------------------------------------------
  -- Data Decoder
  --------------------------------------------------------------------------------

  etroc_rx_lpgbt_gen : for ilpgbt in 0 to NUM_UPLINKS-1 generate
    etroc_rx_elink_gen : for ielink in 0 to 27 generate
      signal locked        : std_logic := '0';
      signal bitslip       : std_logic := '0';
      signal zero_suppress : std_logic := '1';
      signal raw_data_mode : std_logic := '0';
      signal data_i        : std_logic_vector (31 downto 0);
    begin

      data_i <= x"000000" & uplink_data_aligned(ilpgbt).data(8*(ielink+1)-1 downto 8*ielink);

      etroc_rx_1 : entity etroc.etroc_rx
        port map (
          clock             => clk40,
        -- FIXME: this should not be shared across both lpgbts
          reset             => reset or ctrl.reset_etroc_rx(ielink),
          data_i            => data_i,
          bitslip_i         => bitslip,
          bitslip_auto_i    => ctrl.bitslip_auto_en,
          zero_suppress     => zero_suppress,
          raw_data_mode     => raw_data_mode,
          fifo_wr_en_o      => rx_fifo_wr_en_arr(ilpgbt*28+ielink),
          fifo_data_o       => rx_fifo_data_arr(ilpgbt*28+ielink),
          frame_mon_o       => rx_frame_mon_arr(ilpgbt*28+ielink),
          state_mon_o       => rx_state_mon_arr(ilpgbt*28+ielink),
          bcid_o            => open,
          type_o            => open,
          event_cnt_o       => open,
          cal_o             => open,
          tot_o             => open,
          toa_o             => open,
          col_o             => open,
          row_o             => open,
          ea_o              => open,
          data_en_o         => open,
          stat_o            => open,
          hitcnt_o          => open,
          crc_o             => rx_crc_arr(ilpgbt*28+ielink),
          crc_calc_o        => rx_crc_calc_arr(ilpgbt*28+ielink),
          chip_id_o         => open,
          start_of_packet_o => rx_start_of_packet(ilpgbt*28+ielink),
          end_of_packet_o   => rx_end_of_packet(ilpgbt*28+ielink),
          err_o             => rx_err(ilpgbt*28+ielink),
          busy_o            => rx_busy(ilpgbt*28+ielink),
          idle_o            => rx_idle(ilpgbt*28+ielink),
          locked_o          => rx_locked(ilpgbt*28+ielink)
          );

      lpgbt0 : if (ilpgbt = 0) generate
        bitslip       <= ctrl.etroc_bitslip(ielink);
        zero_suppress <= ctrl.zero_supress(ielink);
        raw_data_mode <= ctrl.raw_data_mode(ielink);
      end generate;

      lpgbt1 : if (ilpgbt = 1) generate
        bitslip       <= ctrl.etroc_bitslip_slave(ielink);
        zero_suppress <= ctrl.zero_supress_slave(ielink);
        raw_data_mode <= ctrl.raw_data_mode_slave(ielink);
      end generate;

    end generate;
  end generate;

  mon.etroc_locked(27 downto 0)       <= rx_locked(27 downto 0);
  mon.etroc_locked_slave(27 downto 0) <= rx_locked(55 downto 28);

  process (clk40) is
  begin
    if (rising_edge(clk40)) then

      rx_fifo_data  <= rx_fifo_data_arr(link_sel);
      rx_fifo_wr_en <= rx_fifo_wr_en_arr(link_sel);
      rx_crc        <= rx_crc_arr(link_sel);
      rx_crc_calc   <= rx_crc_calc_arr(link_sel);
    end if;
  end process;

  rx_crc_match <= '1' when rx_crc = rx_crc_calc else '0';

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (ctrl.rx_fifo_data_src = '1') then
        rx_fifo_data_mux <= x"AAAAAAAAAA";
        rx_fifo_wr_en_mux <= '1';
      else
        rx_fifo_data_mux  <= rx_fifo_data;
        rx_fifo_wr_en_mux <= rx_fifo_wr_en;
      end if;

    end if;
  end process;


  etroc_fifo_inst : entity work.etroc_fifo
    generic map (
      DEPTH => 32768*4,
      LOST_CNT_WIDTH => mon.rx_fifo_lost_word_cnt'length
      )
    port map (
      clk40         => clk40,
      reset         => reset,
      fifo_reset_i  => ctrl.fifo_reset,
      lost_word_cnt => mon.rx_fifo_lost_word_cnt,
      full_o        => mon.rx_fifo_full,
      fifo_data_i   => rx_fifo_data_mux,
      fifo_wr_en    => rx_fifo_wr_en_mux,
      fifo_wb_in    => daq_wb_in(0),
      fifo_wb_out   => daq_wb_out(0)
      );

  -- --------------------------------------------------------------------------------
  -- -- Histogrammer
  -- --------------------------------------------------------------------------------

  -- histogrammer_inst : entity work.histogrammer
  --   generic map (
  --     NBINS => 28*2,
  --     DEPTH =>
  --     )
  --   port map (
  --     clock        => clk40,
  --     reset        => histo_reset,
  --     freeze_i     => histo_freeze,
  --     enable_i     => histo_enable,
  --     bin_select_i => to_integer(unsigned(histo_bin_select)),
  --     count_o      => histo_count
  --     );

  --------------------------------------------------------------------------------
  -- DEBUG ILAS
  --------------------------------------------------------------------------------

  debug : if (C_DEBUG) generate

    signal ila_uplink_data    : std_logic_vector (223 downto 0);
    signal ila_uplink_valid   : std_logic;
    signal ila_uplink_ready   : std_logic;
    signal ila_uplink_reset   : std_logic;
    signal ila_uplink_fec_err : std_logic;
    signal ila_uplink_ic      : std_logic_vector (1 downto 0);
    signal ila_uplink_ec      : std_logic_vector (1 downto 0);

    signal rx_locked_mon          : std_logic;
    signal rx_err_mon             : std_logic;
    signal rx_idle_mon            : std_logic;
    signal rx_start_of_packet_mon : std_logic;
    signal rx_end_of_packet_mon   : std_logic;
    signal rx_frame_mon           : std_logic_vector (39 downto 0) := (others => '0');
    signal rx_state_mon           : std_logic_vector (2 downto 0)  := (others => '0');

  begin

    process (clk40) is
    begin
      if (rising_edge(clk40)) then

        ila_uplink_data    <= uplink_data_aligned(lpgbt_sel).data;
        ila_uplink_valid   <= uplink_data_aligned(lpgbt_sel).valid;
        ila_uplink_ready   <= uplink_ready(lpgbt_sel);
        ila_uplink_reset   <= uplink_reset(lpgbt_sel);
        ila_uplink_fec_err <= uplink_fec_err(lpgbt_sel);
        ila_uplink_ic      <= uplink_data(lpgbt_sel).ic;
        ila_uplink_ec      <= uplink_data(lpgbt_sel).ec;

        rx_state_mon           <= rx_state_mon_arr(link_sel);
        rx_frame_mon           <= rx_frame_mon_arr(link_sel);
        rx_locked_mon          <= rx_locked(link_sel);
        rx_err_mon             <= rx_err(link_sel);
        rx_idle_mon            <= rx_idle(link_sel);
        rx_start_of_packet_mon <= rx_start_of_packet(link_sel);
        rx_end_of_packet_mon   <= rx_end_of_packet(link_sel);

      end if;
    end process;

    ila_lpgbt_inst : ila_lpgbt
      port map (
        clk                   => clk40,
        probe0(7 downto 0)    => rx_crc,
        probe0(15 downto 8)   => rx_crc_calc,
        probe0(16)            => l1a,
        probe0(17)            => l1a_gen,
        probe0(18)            => ctrl.l1a_pulse,
        probe0(19)            => trigger_i,
        probe0(20)            => rx_start_of_packet_mon,
        probe0(21)            => rx_end_of_packet_mon,
        probe0(22)            => rx_crc_match,
        probe0(223 downto 23) => (others => '0'),
        probe1(0)             => ila_uplink_valid,
        probe2(0)             => ila_uplink_ready,
        probe3(0)             => ila_uplink_reset,
        probe4(0)             => ila_uplink_fec_err,
        probe5(1 downto 0)    => ila_uplink_ic,
        probe6(1 downto 0)    => ila_uplink_ec,
        probe7(39 downto 0)   => rx_frame_mon,
        probe8(39 downto 0)   => rx_fifo_data_mux,
        probe9(0)             => rx_fifo_wr_en_mux,
        probe10(2 downto 0)   => rx_state_mon,
        probe11(0)            => rx_locked_mon,
        probe12(0)            => rx_err_mon,
        probe13(0)            => rx_idle_mon
        );
  end generate;

end behavioral;
