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
    NUM_UPLINKS     : integer := 2;
    NUM_DOWNLINKS   : integer := 1;
    NUM_SCAS        : integer := 1
    );
  port(

    clk40  : in std_logic;
    clk320 : in std_logic;

    reset : in std_logic;

    strobe : in std_logic;

    bc0 : in std_logic;
    l1a : in std_logic;

    --tx_ready : in std_logic;
    --rx_ready : in std_logic;

    ctrl_clk : in  std_logic;
    mon      : out READOUT_BOARD_MON_t;
    ctrl     : in  READOUT_BOARD_CTRL_t;

    daq_wb_in  : in  ipb_wbus_array(0 downto 0);
    daq_wb_out : out ipb_rbus_array(0 downto 0);

    uplink_bitslip          : out std_logic_vector (NUM_UPLINKS-1 downto 0);
    uplink_mgt_word_array   : in  std32_array_t (NUM_UPLINKS-1 downto 0);
    downlink_mgt_word_array : out std32_array_t (NUM_DOWNLINKS-1 downto 0)

    );
end readout_board;

architecture behavioral of readout_board is

  signal fifo_reset     : std_logic            := '0';
  signal fifo_reset_cnt : integer range 0 to 7 := 0;

  -- FIXME: account for fec5/12
  constant ELINK_EN_MASK : std_logic_vector (27 downto 0) := x"0555555";

  constant FREQ : integer := 320;       -- uplink frequency

  constant DOWNWIDTH  : integer := 8;
  constant UPWIDTH    : integer := FREQ/40;
  constant NUM_ELINKS : integer := 224/UPWIDTH;

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

  signal fast_cmd : std_logic_vector (7 downto 0) := (others => '0');

  --------------------------------------------------------------------------------
  -- TX Fifo
  --------------------------------------------------------------------------------

  signal tx_filler_gen        : std_logic_vector (7 downto 0) := (others => '0');
  signal tx_gen               : std_logic_vector (7 downto 0) := (others => '0');
  signal tx_fifo_out          : std_logic_vector (7 downto 0) := (others => '0');
  signal tx_fifo_rst          : std_logic                     := '0';
  signal tx_filler_en         : std_logic                     := '0';
  signal tx_fifo_rst_cnt      : integer range 0 to 7          := 0;
  signal tx_fifo_rd_en        : std_logic                     := '0';
  signal tx_fifo_valid        : std_logic                     := '0';
  signal tx_fifo_almost_empty : std_logic                     := '0';
  signal tx_fifo_empty        : std_logic                     := '0';
  signal tx_filler_tlast      : std_logic                     := '0';
  signal tx_filler_tnext      : std_logic                     := '0';
  signal tx_data_fifo_notfill : std_logic                     := '0';

  --------------------------------------------------------------------------------
  -- FIFO
  --------------------------------------------------------------------------------

  signal fifo_full  : std_logic_vector (1 downto 0) := (others => '0');
  signal fifo_empty : std_logic_vector (1 downto 0) := (others => '0');
  signal fifo_armed : std_logic_vector (1 downto 0) := (others => '0');

  type int_array_t is array (integer range <>) of integer;

  signal elink_sel    : integer range 0 to 27;
  signal lpgbt_sel    : integer range 0 to 1;
  signal link_sel     : integer range 0 to 28*2-1;
  signal link_sel_daq : integer range 0 to 28*2-1;

  --------------------------------------------------------------------------------
  -- TTC
  --------------------------------------------------------------------------------

  signal packet_rx_rate : std_logic_vector (31 downto 0);
  signal packet_cnt     : std16_array_t(28*NUM_UPLINKS-1 downto 0);
  signal err_cnt        : std16_array_t(28*NUM_UPLINKS-1 downto 0);

  --------------------------------------------------------------------------------
  -- ETROC RX
  --------------------------------------------------------------------------------

  type rx_frame_array_t is array (integer range <>) of std_logic_vector(39 downto 0);
  type rx_state_array_t is array (integer range <>) of std_logic_vector(2 downto 0);

  signal rx_frame_mon_arr  : rx_frame_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_state_mon_arr  : rx_state_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_data_arr  : rx_frame_array_t (28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_valid_arr : std_logic_vector(28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_empty_arr : std_logic_vector(28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_full_arr  : std_logic_vector(28*NUM_UPLINKS-1 downto 0);

  -- ETROC CRC
  constant CRCBITS       : integer   := 8;
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

  signal rx_fifo_data, rx_fifo_data_mux   : std_logic_vector (39 downto 0);
  signal rx_fifo_valid, rx_fifo_valid_mux : std_logic;
  signal rx_fifo_empty                    : std_logic;


  signal rx_fifo_rd_en_selector : std_logic_vector(28*NUM_UPLINKS-1 downto 0);
  signal rx_fifo_valid_selector : std_logic;
  signal rx_fifo_data_selector  : std_logic_vector (39 downto 0);

  signal rx_fifo_metadata_mux      : std_logic_vector (23 downto 0);
  signal rx_fifo_metadata_selector : std_logic_vector (23 downto 0);

  signal global_fifo_full : std_logic;

begin

  extender_inst : entity work.extender
    generic map (LENGTH => 16)
    port map (
      clk => clk40,
      d   => reset or ctrl.fifo_reset,
      q   => fifo_reset
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

    downlink_data(I).valid <= strobe;

    process (clk40) is
    begin
      if (rising_edge(clk40)) then
        case dl_src is

          when 0 =>
            downlink_data(I).data <= repeat_byte(fast_cmd);
          when 1 =>
            downlink_data(I).data <= repeat_byte(cnt_slv);
          when 2 =>
            downlink_data(I).data <= repeat_byte(prbs_gen_reverse);
          when 3 =>
            downlink_data(I).data <= repeat_byte(tx_gen);
          when others =>
            downlink_data(I).data <= repeat_byte(fast_cmd);

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
      link_reset => ctrl.link_reset_pulse,
      data_o     => fast_cmd
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

    pkt_counter : entity work.counter
      generic map (width => 16)
      port map (
        clk    => clk40,
        reset  => reset or ctrl.packet_cnt_reset,
        enable => '1',
        event  => rx_end_of_packet(I),
        count  => packet_cnt(I),
        at_max => open
        );

    err_counter : entity work.counter
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
  uplink_reset(1)                <= ctrl.lpgbt.trigger.uplink.reset;

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
      ic_data_o => downlink_data(0).ic,

      sca0_data_i => uplink_data(0).ec,
      sca0_data_o => downlink_data(0).ec
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

      downlink_data_i => downlink_data,
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
      en_gen : if (ELINK_EN_MASK(ielink) = '1') generate

        signal data_i : std_logic_vector (31 downto 0);
        signal data   : std_logic_vector (39 downto 0) := (others => '0');

        signal locked          : std_logic := '0';
        signal bitslip         : std_logic := '0';
        signal zero_suppress   : std_logic := '1';
        signal raw_data_mode   : std_logic := '0';
        signal start_of_packet : std_logic := '0';
        signal end_of_packet   : std_logic := '0';

        signal start_of_packet_xfifo : std_logic;
        signal end_of_packet_xfifo   : std_logic;
        signal valid_xfifo           : std_logic;
        signal full_xfifo            : std_logic;
        signal empty_xfifo           : std_logic;

        signal wr_en : std_logic := '0';
        signal rd_en : std_logic := '0';

        signal disable : std_logic := '0';

      begin

        data_i <= x"000000" & uplink_data_aligned(ilpgbt).data(8*(ielink+1)-1 downto 8*ielink);

        etroc_rx_1 : entity etroc.etroc_rx
          port map (
            clock             => clk40,
            -- FIXME: this should not be shared across both lpgbts
            reset             => reset or ctrl.reset_etroc_rx(ielink) or disable,
            data_i            => data_i,
            bitslip_i         => bitslip,
            bitslip_auto_i    => ctrl.bitslip_auto_en,
            zero_suppress     => zero_suppress,
            raw_data_mode     => raw_data_mode,
            fifo_wr_en_o      => wr_en,
            fifo_data_o       => data,
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
            start_of_packet_o => start_of_packet,
            end_of_packet_o   => end_of_packet,
            err_o             => rx_err(ilpgbt*28+ielink),
            busy_o            => rx_busy(ilpgbt*28+ielink),
            idle_o            => rx_idle(ilpgbt*28+ielink),
            locked_o          => locked
            );

        rx_locked(ilpgbt*28+ielink) <= locked;
        rd_en                       <= rx_fifo_rd_en_selector(ilpgbt*28+ielink);

        -- buffer data from THIS etroc before it goes into the main mux
        etroc_fifo_inst : entity work.fifo_async
          generic map (
            DEPTH          => 512,
            WR_WIDTH       => 42,
            RD_WIDTH       => 42,
            RELATED_CLOCKS => 1
            )
          port map (
            rst => reset or fifo_reset,  -- Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.

            wr_clk => clk40,
            rd_clk => clk40,

            wr_en => wr_en,
            rd_en => rd_en,

            din               => start_of_packet & end_of_packet & data,
            dout(39 downto 0) => rx_fifo_data_arr(ilpgbt*28+ielink),
            dout(40)          => end_of_packet_xfifo,
            dout(41)          => start_of_packet_xfifo,

            valid => valid_xfifo,
            full  => full_xfifo,
            empty => empty_xfifo
            );

        rx_fifo_full_arr(ilpgbt*28+ielink)   <= full_xfifo and elink_en_mask(ielink);
        rx_fifo_empty_arr(ilpgbt*28+ielink)  <= empty_xfifo or not elink_en_mask(ielink);
        rx_fifo_valid_arr(ilpgbt*28+ielink)  <= valid_xfifo;
        rx_end_of_packet(ilpgbt*28+ielink)   <= valid_xfifo and end_of_packet_xfifo;
        rx_start_of_packet(ilpgbt*28+ielink) <= valid_xfifo and start_of_packet_xfifo;

        lpgbt0 : if (ilpgbt = 0) generate
          bitslip       <= ctrl.etroc_bitslip(ielink);
          zero_suppress <= ctrl.zero_supress(ielink);
          raw_data_mode <= ctrl.raw_data_mode(ielink);
          disable       <= ctrl.etroc_disable(ielink);
        end generate;

        lpgbt1 : if (ilpgbt = 1) generate
          bitslip       <= ctrl.etroc_bitslip_slave(ielink);
          zero_suppress <= ctrl.zero_supress_slave(ielink);
          raw_data_mode <= ctrl.raw_data_mode_slave(ielink);
          disable       <= ctrl.etroc_disable_slave(ielink);
        end generate;

      end generate;
    end generate;
  end generate;

  mon.etroc_locked(27 downto 0)       <= rx_locked(27 downto 0);
  mon.etroc_locked_slave(27 downto 0) <= rx_locked(55 downto 28);

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      rx_fifo_data  <= rx_fifo_data_arr(link_sel);
      rx_fifo_valid <= rx_fifo_valid_arr(link_sel);
      rx_fifo_empty <= rx_fifo_empty_arr(link_sel);
      rx_crc        <= rx_crc_arr(link_sel);
      rx_crc_calc   <= rx_crc_calc_arr(link_sel);
    end if;
  end process;

  rx_crc_match <= '1' when rx_crc = rx_crc_calc else '0';

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (ctrl.rx_fifo_data_src = '1') then
        rx_fifo_data_mux     <= x"AAAAAAAAAA";
        rx_fifo_valid_mux    <= '1';
        rx_fifo_metadata_mux <= (others => '0');
      end if;
      if (ctrl.rx_fifo_data_src = '0') then
        rx_fifo_metadata_mux <= rx_fifo_metadata_selector;
        rx_fifo_data_mux     <= rx_fifo_data_selector (39 downto 0);
        rx_fifo_valid_mux    <= rx_fifo_valid_selector;
      end if;

    end if;
  end process;

  etroc_selector_inst : entity work.etroc_selector
    generic map (
      g_NUM_INPUTS => 28*2,
      g_WIDTH      => 40
      )
    port map (
      clock   => clk40,
      reset_i => reset or fifo_reset,

      global_full => global_fifo_full,

      ch_en_i => rx_locked and (elink_en_mask & elink_en_mask)
                  and not (ctrl.etroc_disable_slave & ctrl.etroc_disable),

      data_i  => rx_fifo_data_arr(link_sel_daq),  -- in:  multiplexed input data
      sof_i   => rx_start_of_packet,
      eof_i   => rx_end_of_packet,
      full_i  => rx_fifo_full_arr,      -- in:  all full flags
      empty_i => rx_fifo_empty_arr,     -- in:  all empty flags
      valid_i => rx_fifo_valid_arr,     -- in:  all valid flags

      data_sel => link_sel_daq,         -- out: multiplexer select 0-57

      rd_en_o    => rx_fifo_rd_en_selector,    -- out: fifo read enable
      data_o     => rx_fifo_data_selector,     -- out: data, connect to daq fifo
      metadata_o => rx_fifo_metadata_selector, -- out: data, connect to daq fifo
      wr_en_o    => rx_fifo_valid_selector     -- out: wr_en, connect to daq_fifo
      );

  mon.rx_fifo_full <= global_fifo_full;

  etroc_fifo_inst : entity work.etroc_fifo
    generic map (
      DEPTH          => 32768*4,
      LOST_CNT_WIDTH => mon.rx_fifo_lost_word_cnt'length
      )
    port map (
      clk40         => clk40,
      reset         => reset,
      fifo_reset_i  => fifo_reset,
      lost_word_cnt => mon.rx_fifo_lost_word_cnt,
      full_o        => global_fifo_full,
      metadata_i    => rx_fifo_metadata_mux,
      fifo_data_i   => rx_fifo_data_mux,
      occupancy_o   => mon.rx_fifo_occupancy,
      fifo_wr_en    => rx_fifo_valid_mux,
      fifo_wb_in    => daq_wb_in(0),
      fifo_wb_out   => daq_wb_out(0)
      );

  --------------------------------------------------------------------------------
  -- TX Fifo
  --------------------------------------------------------------------------------

  -- generate fillers 8 bits at a time
  tx_filler_generator_inst : entity work.tx_filler_generator
    port map (
      clock => clk40,
      l1a   => l1a,
      bc0   => bc0,
      dout  => tx_filler_gen,
      en    => tx_filler_en,
      tnext => tx_filler_tnext,
      tlast => tx_filler_tlast
      );

  tx_filler_en <= not tx_fifo_valid;

  -- switch between the filler generator and the fifo
  tx_gen <= tx_fifo_out when tx_data_fifo_notfill ='1' else tx_filler_gen;

  ------------------------------------------
  -- synchronize the filler -> fifo switchover
  -- to the tlast of the filler generator
  ------------------------------------------

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      -- switch over to the fifo when rd_en is selected and we are at the last
      -- filler word
      if (tx_fifo_rd_en = '1' and tx_filler_tlast = '1') then
        tx_data_fifo_notfill <= '1';

      -- switch back when we are almost empty (fifo getting drained)
      -- or empty (fifo was empty to begin with)
      elsif (tx_fifo_empty = '1' or tx_fifo_almost_empty = '1') then
        tx_data_fifo_notfill <= '0';

      end if;

    end if;
  end process;

  -- Synchronize the rd_en of the fifo to the data word
  -- this is done by only reading the fifo at the appropriate
  -- phase of the 40 bit to 8 bit conversion state machine
  --
  -- the tnext signal indicates that the next data word is the last data word
  -- in the cycle.
  --
  -- by flagging rd_en high on tnext, then a word should be available at the
  -- FIFO output in time to replace the first data word; this of course depends
  -- on the latency of the FIFO, so that would need to be taken into account.
  -- if the latency of the FIFO changes, then the timing of this signal would
  -- need to change as well by adding a delay

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (ctrl.tx_fifo_rd_en = '0') then
        tx_fifo_rd_en <= '0';
      elsif (tx_filler_tnext = '1') then
        tx_fifo_rd_en <= '1';
      end if;
    end if;
  end process;

  ------------------------------------------
  -- pulse extend the TX FIFO reset signal
  ------------------------------------------

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (reset = '1' or ctrl.tx_fifo_reset = '1') then
        tx_fifo_rst_cnt <= 7;
        tx_fifo_rst     <= '1';
      elsif (tx_fifo_rst_cnt > 0) then
        tx_fifo_rst_cnt <= tx_fifo_rst_cnt-1;
        tx_fifo_rst     <= '1';
      else
        tx_fifo_rst <= '0';
      end if;
    end if;
  end process;

  ------------------------------------------
  -- tx fifo instance
  ------------------------------------------

  fifo_sync_inst : entity work.fifo_sync
    generic map (
      DEPTH               => 32768,
      USE_ALMOST_FULL     => 1,
      WR_WIDTH            => 32,
      RD_WIDTH            => 8,
      FIFO_READ_LATENCY   => 1
      )
    port map (
      rst           => tx_fifo_rst,
      clk           => clk40,
      wr_en         => ctrl.tx_fifo_wr_en,
      rd_en         => tx_fifo_rd_en,
      din           => ctrl.tx_fifo_data(7 downto 0) &
                       ctrl.tx_fifo_data(15 downto 8) &
                       ctrl.tx_fifo_data(23 downto 16) &
                       ctrl.tx_fifo_data(31 downto 24),
      dout          => tx_fifo_out,
      valid         => tx_fifo_valid,
      wr_data_count => open,
      overflow      => open,
      full          => open,
      almost_empty  => tx_fifo_almost_empty,
      almost_full   => open,
      empty         => tx_fifo_empty
      );

  --------------------------------------------------------------------------------
  -- DEBUG ILAS
  --------------------------------------------------------------------------------

  debug : if (C_DEBUG) generate

    signal ila_uplink_data       : std_logic_vector (223 downto 0);
    signal ila_uplink_elink_data : std_logic_vector (7 downto 0);
    signal ila_uplink_valid      : std_logic;
    signal ila_uplink_ready      : std_logic;
    signal ila_uplink_reset      : std_logic;
    signal ila_uplink_fec_err    : std_logic;
    signal ila_uplink_ic         : std_logic_vector (1 downto 0);
    signal ila_uplink_ec         : std_logic_vector (1 downto 0);

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

        ila_uplink_data       <= uplink_data_aligned(lpgbt_sel).data;
        ila_uplink_elink_data <= ila_uplink_data(8*(elink_sel+1)-1 downto 8*elink_sel);
        ila_uplink_valid      <= uplink_data_aligned(lpgbt_sel).valid;
        ila_uplink_ready      <= uplink_ready(lpgbt_sel);
        ila_uplink_reset      <= uplink_reset(lpgbt_sel);
        ila_uplink_fec_err    <= uplink_fec_err(lpgbt_sel);
        ila_uplink_ic         <= uplink_data(lpgbt_sel).ic;
        ila_uplink_ec         <= uplink_data(lpgbt_sel).ec;

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
        clk                    => clk40,
        probe0(7 downto 0)     => rx_crc,
        probe0(15 downto 8)    => rx_crc_calc,
        probe0(16)             => l1a,
        probe0(17)             => rx_start_of_packet_mon,
        probe0(18)             => rx_end_of_packet_mon,
        probe0(19)             => rx_crc_match,
        probe0(25 downto 20)   => std_logic_vector(to_unsigned(link_sel_daq, 6)),
        probe0(65 downto 26)   => rx_frame_mon,
        probe0(73 downto 66)   => ila_uplink_elink_data,
        probe0(81 downto 74)   => tx_fifo_out,
        probe0(82)             => tx_fifo_rst,
        probe0(83)             => tx_filler_en,
        probe0(84)             => tx_fifo_rd_en,
        probe0(85)             => tx_fifo_valid,
        probe0(86)             => tx_fifo_almost_empty,
        probe0(87)             => tx_filler_tlast,
        probe0(88)             => tx_filler_tnext,
        probe0(89)             => tx_data_fifo_notfill,
        probe0(97 downto 90)   => tx_filler_gen,
        probe0(105 downto 98)  => tx_gen,
        probe0(106)            => ctrl.tx_fifo_wr_en,
        probe0(138 downto 107) => ctrl.tx_fifo_data,
        probe0(139)            => ctrl.tx_fifo_rd_en,
        probe0(140)            => ctrl.tx_fifo_reset,
        probe0(148 downto 141) => downlink_data(0).data(7 downto 0),
        probe0(156 downto 149) => uplink_data(0).data(7 downto 0),
        probe0(157)            => tx_fifo_empty,
        probe0(223 downto 157) => (others => '0'),
        probe1(0)              => ila_uplink_valid,
        probe2(0)              => ila_uplink_ready,
        probe3(0)              => ila_uplink_reset,
        probe4(0)              => ila_uplink_fec_err,
        probe5(1 downto 0)     => (others => '0'),
        probe6(1 downto 0)     => (others => '0'),
        probe7(39 downto 0)    => rx_fifo_data_arr(link_sel_daq),
        probe8(39 downto 0)    => rx_fifo_data_mux,
        probe9(0)              => rx_fifo_valid_mux,
        probe10(2 downto 0)    => rx_state_mon,
        probe11(0)             => rx_locked_mon,
        probe12(0)             => rx_err_mon,
        probe13(0)             => rx_idle_mon
        );
  end generate;

end behavioral;
