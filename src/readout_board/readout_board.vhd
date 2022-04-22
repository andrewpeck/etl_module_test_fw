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

    ctrl_clk : in  std_logic;
    mon      : out READOUT_BOARD_MON_t;
    ctrl     : in  READOUT_BOARD_CTRL_t;

    fifo_wb_in  : in  ipb_wbus_array(1 downto 0);
    fifo_wb_out : out ipb_rbus_array(1 downto 0);

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

  signal fast_cmd_fw, fast_cmd_sw : std_logic_vector (7 downto 0) := (others => '0');

  --------------------------------------------------------------------------------
  -- FIFO
  --------------------------------------------------------------------------------

  signal fifo_full  : std_logic_vector (1 downto 0) := (others => '0');
  signal fifo_empty : std_logic_vector (1 downto 0) := (others => '0');
  signal fifo_armed : std_logic_vector (1 downto 0) := (others => '0');

  type int_array_t is array (integer range <>) of integer;

  signal elink_sel : int_array_t (1 downto 0);
  signal lpgbt_sel : int_array_t (1 downto 0);

  --------------------------------------------------------------------------------
  -- TTC
  --------------------------------------------------------------------------------

  signal trigger_rate : std_logic_vector (31 downto 0);

  signal l1a_gen    : std_logic               := '0';
  signal l1a        : std_logic               := '0';
  signal bc0        : std_logic               := '0';
  signal link_reset : std_logic               := '0';
  signal bxn        : natural range 0 to 3563 := 0;

  --------------------------------------------------------------------------------
  -- ILA
  --------------------------------------------------------------------------------

  signal ila_sel : integer := 0;

  --------------------------------------------------------------------------------
  -- ETROC RX
  --------------------------------------------------------------------------------

  signal rx_frame_mon  : std_logic_vector (39 downto 0) := (others => '0');
  signal rx_fifo_data  : std_logic_vector (39 downto 0) := (others => '0');
  signal rx_fifo_wr_en : std_logic;

  signal rx_start_of_packet  : std_logic;
  signal rx_end_of_packet   : std_logic;

begin

  --------------------------------------------------------------------------------
  -- create 1/8 strobe synced to 40MHz clock
  --------------------------------------------------------------------------------

  clock_strobe_inst : entity work.clock_strobe
    port map (
      fast_clk_i => clk320,
      slow_clk_i => clk40,
      strobe_o   => valid);

  --------------------------------------------------------------------------------
  -- Downlink Data Generation
  --
  -- TODO: move this into its own block
  --
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
            downlink_data(I).data <= repeat_byte(fast_cmd_sw);
          when others =>
            downlink_data(I).data <= repeat_byte(fast_cmd_fw);

        end case;
      end if;
    end process;
  end generate;

  -- Fast command pulse
  --  + make it so that the fast commands are just one pulse wide
  --    (gated by the strobe)

  fast_cmd_sw <= ctrl.lpgbt.daq.downlink.fast_cmd_data
                 when
                 ctrl.lpgbt.daq.downlink.fast_cmd_pulse = '1' else
                 ctrl.lpgbt.daq.downlink.fast_cmd_idle;

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

  l1a        <= ctrl.l1a_pulse or l1a_gen;
  link_reset <= ctrl.link_reset_pulse;

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

  mon.l1a_rate_cnt <= trigger_rate;

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
  --
  -- TODO: move this into its own block
  --
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
  --
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
  -- DAQ FIFO + Reader
  --
  -- Multiplex all elinks into a single FIFO that can be read from the DAQ
  --
  --------------------------------------------------------------------------------

  elink_sel(0) <= to_integer(unsigned(ctrl.fifo_elink_sel0));
  lpgbt_sel(0) <= to_integer(unsigned(std_logic_vector'("" & ctrl.fifo_lpgbt_sel0)));  -- vhdl qualify operator
  elink_sel(1) <= to_integer(unsigned(ctrl.fifo_elink_sel1));
  lpgbt_sel(1) <= to_integer(unsigned(std_logic_vector'("" & ctrl.fifo_lpgbt_sel1)));  -- vhdl qualify operator

  mon.fifo_full0  <= fifo_full(0);
  mon.fifo_full1  <= fifo_full(1);
  mon.fifo_armed0 <= fifo_armed(0);
  mon.fifo_armed1 <= fifo_armed(1);
  mon.fifo_empty0 <= fifo_empty(0);
  mon.fifo_empty1 <= fifo_empty(1);

  daq_gen : for I in 0 to 1 generate
  begin

    elink_daq_inst : entity work.elink_daq
      generic map (
        UPWIDTH     => UPWIDTH,
        NUM_UPLINKS => NUM_UPLINKS
        )
      port map (
        clk40      => clk40,
        reset      => reset,
        fifo_reset => ctrl.fifo_reset,

        trig0 => ctrl.fifo_trig0(UPWIDTH-1 downto 0),
        trig1 => ctrl.fifo_trig1(UPWIDTH-1 downto 0),
        trig2 => ctrl.fifo_trig2(UPWIDTH-1 downto 0),
        trig3 => ctrl.fifo_trig3(UPWIDTH-1 downto 0),
        trig4 => ctrl.fifo_trig4(UPWIDTH-1 downto 0),
        trig5 => ctrl.fifo_trig5(UPWIDTH-1 downto 0),
        trig6 => ctrl.fifo_trig6(UPWIDTH-1 downto 0),
        trig7 => ctrl.fifo_trig7(UPWIDTH-1 downto 0),
        trig8 => ctrl.fifo_trig8(UPWIDTH-1 downto 0),
        trig9 => ctrl.fifo_trig9(UPWIDTH-1 downto 0),

        mask0 => ctrl.fifo_trig0_mask(UPWIDTH-1 downto 0),
        mask1 => ctrl.fifo_trig1_mask(UPWIDTH-1 downto 0),
        mask2 => ctrl.fifo_trig2_mask(UPWIDTH-1 downto 0),
        mask3 => ctrl.fifo_trig3_mask(UPWIDTH-1 downto 0),
        mask4 => ctrl.fifo_trig4_mask(UPWIDTH-1 downto 0),
        mask5 => ctrl.fifo_trig5_mask(UPWIDTH-1 downto 0),
        mask6 => ctrl.fifo_trig6_mask(UPWIDTH-1 downto 0),
        mask7 => ctrl.fifo_trig7_mask(UPWIDTH-1 downto 0),
        mask8 => ctrl.fifo_trig8_mask(UPWIDTH-1 downto 0),
        mask9 => ctrl.fifo_trig9_mask(UPWIDTH-1 downto 0),

        fifo_capture_depth => to_integer(unsigned(ctrl.fifo_capture_depth)),
        force_trig         => ctrl.fifo_force_trig,
        reverse_bits       => ctrl.fifo_reverse_bits,

        elink_sel => elink_sel(I),
        lpgbt_sel => lpgbt_sel(I),

        armed => fifo_armed(I),
        full  => fifo_full(I),
        empty => fifo_empty(I),

        data_i      => uplink_data_aligned,
        fifo_wb_in  => fifo_wb_in(I),
        fifo_wb_out => fifo_wb_out(I)
        );
  end generate;

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

  etroc_rx_gen : for I in 0 to 0 generate
  begin
    etroc_rx_1 : entity etroc.etroc_rx
      port map (
        clock             => clk40,
        reset             => reset,
        data_i            => x"000000" & uplink_data_aligned(lpgbt_sel(I)).data(8*(elink_sel(I)+1)-1 downto 8*elink_sel(I)),
        bitslip_i         => ctrl.etroc_bitslip(I),
        fifo_wr_en_o      => rx_fifo_wr_en,
        fifo_data_o       => rx_fifo_data,
        frame_mon_o       => rx_frame_mon,
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
        crc_o             => open,
        chip_id_o         => open,
        start_of_packet_o => open,
        end_of_packet_o   => open,
        err_o             => open,
        busy_o            => open,
        idle_o            => open
        );
  end generate;

  etroc_fifo_inst : entity work.etroc_fifo
    generic map (
      DEPTH => 32768
      )
    port map (
      clk40        => clk40,
      reset        => reset,
      fifo_reset_i => ctrl.fifo_reset,
      fifo_data_i  => rx_fifo_data,
      fifo_wr_en   => rx_fifo_wr_en,
      fifo_wb_in   => daq_wb_in(0),
      fifo_wb_out  => daq_wb_out(0)
      );

  --------------------------------------------------------------------------------
  -- DEBUG ILAS
  --------------------------------------------------------------------------------

  debug : if (C_DEBUG) generate
  begin

    ila_sel <= to_integer(unsigned(ctrl.ila_sel));

    ila_lpgbt_trig_inst : ila_lpgbt
      port map (
        clk                  => clk40,
        probe0(223 downto 0) => uplink_data_aligned(ila_sel).data,
        probe1(0)            => uplink_data_aligned(ila_sel).valid,
        probe2(0)            => uplink_ready(ila_sel),
        probe3(0)            => uplink_reset(ila_sel),
        probe4(0)            => uplink_fec_err(ila_sel),
        probe5(1 downto 0)   => uplink_data(ila_sel).ic,
        probe6(1 downto 0)   => uplink_data(ila_sel).ec,
        probe7(39 downto 0)  => rx_frame_mon,
        probe8(39 downto 0)  => rx_fifo_data,
        probe9(0)            => rx_fifo_wr_en
        );

  end generate;

end behavioral;
