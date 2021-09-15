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

    fifo_wb_in  : in  ipb_wbus;
    fifo_wb_out : out ipb_rbus;

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

  constant COUNTER_WIDTH    : integer := 16;
  type counter_array_t is array (integer range <>) of std_logic_vector(COUNTER_WIDTH-1 downto 0);
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

  signal counter          : integer range 0 to 255                  := 0;
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

  prbs_gen_reverse <= reverse_vector(prbs_gen);

  -- lpgbt downlink multiplexing
  --
  -- Choose between different data sources
  --
  --  + up count
  --  + prbs-7 generation
  --  + programmable fast command

  dl_assign : for I in 0 to NUM_DOWNLINKS-1 generate
  begin
    process (clk40) is
      variable cnt_slv : std_logic_vector (7 downto 0) := (others => '0');
    begin
      cnt_slv := std_logic_vector (to_unsigned(counter, cnt_slv'length));
      if (rising_edge(clk40)) then
        if (to_integer(unsigned(ctrl.lpgbt.daq.downlink.dl_src)) = 0) then
          downlink_data(I).data <= cnt_slv & cnt_slv & cnt_slv & cnt_slv;
        elsif (to_integer(unsigned(ctrl.lpgbt.daq.downlink.dl_src)) = 1) then
          downlink_data(I).data <= cnt_slv & cnt_slv & cnt_slv & cnt_slv;
        elsif (to_integer(unsigned(ctrl.lpgbt.daq.downlink.dl_src)) = 2) then
          downlink_data(I).data <= prbs_gen_reverse & prbs_gen_reverse & prbs_gen_reverse & prbs_gen_reverse;
        elsif (to_integer(unsigned(ctrl.lpgbt.daq.downlink.dl_src)) = 3) then
          downlink_data(I).data <= fast_cmd & fast_cmd & fast_cmd & fast_cmd;
        end if;
      end if;
    end process;
  end generate;

  -- Fast command pulse
  --  + make it so that the fast commands are just one pulse wide
  --    (gated by the strobe)

  fast_cmd <= ctrl.lpgbt.daq.downlink.fast_cmd_data
              when
              ctrl.lpgbt.daq.downlink.fast_cmd_pulse = '1' else
              ctrl.lpgbt.daq.downlink.fast_cmd_idle;

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

  mon.lpgbt.daq.uplink.fec_err_cnt  <= uplink_fec_err_cnt(0);
  mon.lpgbt.trigger.uplink.fec_err_cnt <= uplink_fec_err_cnt(1);

  ulfeccnt : for I in 0 to NUM_UPLINKS-1 generate
  begin
    uplink_fec_counter : entity work.counter
      generic map (width => 16)
      port map (
        clk    => clk40,
        reset  => reset,
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
    signal align_cnt                 :
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
  -- TODO: move this into its own block
  --
  --------------------------------------------------------------------------------

  -- FIXME: generalize this so the loop doesn't need to be copy pasted for
  -- additional lpgbts stick the registers into an array by hand that can be
  -- indexed, or get the fw_info=array feature to work on bare registers

  xxx : if (true) generate
    type align_cnt_array is array (27 downto 0) of
      std_logic_vector(integer(ceil(log2(real(UPWIDTH))))-1 downto 0);
    type align_cnt_array_2d is array (NUM_LPGBTS_DAQ+NUM_LPGBTS_TRIG-1 downto 0) of align_cnt_array;
    signal align_cnts : align_cnt_array_2d;
  begin

    align_cnts(0)(0)  <= ctrl.lpgbt.daq.uplink.align_0;
    align_cnts(0)(1)  <= ctrl.lpgbt.daq.uplink.align_1;
    align_cnts(0)(2)  <= ctrl.lpgbt.daq.uplink.align_2;
    align_cnts(0)(3)  <= ctrl.lpgbt.daq.uplink.align_3;
    align_cnts(0)(4)  <= ctrl.lpgbt.daq.uplink.align_4;
    align_cnts(0)(5)  <= ctrl.lpgbt.daq.uplink.align_5;
    align_cnts(0)(6)  <= ctrl.lpgbt.daq.uplink.align_6;
    align_cnts(0)(7)  <= ctrl.lpgbt.daq.uplink.align_7;
    align_cnts(0)(8)  <= ctrl.lpgbt.daq.uplink.align_8;
    align_cnts(0)(9)  <= ctrl.lpgbt.daq.uplink.align_9;
    align_cnts(0)(10) <= ctrl.lpgbt.daq.uplink.align_10;
    align_cnts(0)(11) <= ctrl.lpgbt.daq.uplink.align_11;
    align_cnts(0)(12) <= ctrl.lpgbt.daq.uplink.align_12;
    align_cnts(0)(13) <= ctrl.lpgbt.daq.uplink.align_13;
    align_cnts(0)(14) <= ctrl.lpgbt.daq.uplink.align_14;
    align_cnts(0)(15) <= ctrl.lpgbt.daq.uplink.align_15;
    align_cnts(0)(16) <= ctrl.lpgbt.daq.uplink.align_16;
    align_cnts(0)(17) <= ctrl.lpgbt.daq.uplink.align_17;
    align_cnts(0)(18) <= ctrl.lpgbt.daq.uplink.align_18;
    align_cnts(0)(19) <= ctrl.lpgbt.daq.uplink.align_19;
    align_cnts(0)(20) <= ctrl.lpgbt.daq.uplink.align_20;
    align_cnts(0)(21) <= ctrl.lpgbt.daq.uplink.align_21;
    align_cnts(0)(22) <= ctrl.lpgbt.daq.uplink.align_22;
    align_cnts(0)(23) <= ctrl.lpgbt.daq.uplink.align_23;
    align_cnts(0)(24) <= ctrl.lpgbt.daq.uplink.align_24;
    align_cnts(0)(25) <= ctrl.lpgbt.daq.uplink.align_25;
    align_cnts(0)(26) <= ctrl.lpgbt.daq.uplink.align_26;
    align_cnts(0)(27) <= ctrl.lpgbt.daq.uplink.align_27;

    align_cnts(1)(0)  <= ctrl.lpgbt.trigger.uplink.align_0;
    align_cnts(1)(1)  <= ctrl.lpgbt.trigger.uplink.align_1;
    align_cnts(1)(2)  <= ctrl.lpgbt.trigger.uplink.align_2;
    align_cnts(1)(3)  <= ctrl.lpgbt.trigger.uplink.align_3;
    align_cnts(1)(4)  <= ctrl.lpgbt.trigger.uplink.align_4;
    align_cnts(1)(5)  <= ctrl.lpgbt.trigger.uplink.align_5;
    align_cnts(1)(6)  <= ctrl.lpgbt.trigger.uplink.align_6;
    align_cnts(1)(7)  <= ctrl.lpgbt.trigger.uplink.align_7;
    align_cnts(1)(8)  <= ctrl.lpgbt.trigger.uplink.align_8;
    align_cnts(1)(9)  <= ctrl.lpgbt.trigger.uplink.align_9;
    align_cnts(1)(10) <= ctrl.lpgbt.trigger.uplink.align_10;
    align_cnts(1)(11) <= ctrl.lpgbt.trigger.uplink.align_11;
    align_cnts(1)(12) <= ctrl.lpgbt.trigger.uplink.align_12;
    align_cnts(1)(13) <= ctrl.lpgbt.trigger.uplink.align_13;
    align_cnts(1)(14) <= ctrl.lpgbt.trigger.uplink.align_14;
    align_cnts(1)(15) <= ctrl.lpgbt.trigger.uplink.align_15;
    align_cnts(1)(16) <= ctrl.lpgbt.trigger.uplink.align_16;
    align_cnts(1)(17) <= ctrl.lpgbt.trigger.uplink.align_17;
    align_cnts(1)(18) <= ctrl.lpgbt.trigger.uplink.align_18;
    align_cnts(1)(19) <= ctrl.lpgbt.trigger.uplink.align_19;
    align_cnts(1)(20) <= ctrl.lpgbt.trigger.uplink.align_20;
    align_cnts(1)(21) <= ctrl.lpgbt.trigger.uplink.align_21;
    align_cnts(1)(22) <= ctrl.lpgbt.trigger.uplink.align_22;
    align_cnts(1)(23) <= ctrl.lpgbt.trigger.uplink.align_23;
    align_cnts(1)(24) <= ctrl.lpgbt.trigger.uplink.align_24;
    align_cnts(1)(25) <= ctrl.lpgbt.trigger.uplink.align_25;
    align_cnts(1)(26) <= ctrl.lpgbt.trigger.uplink.align_26;
    align_cnts(1)(27) <= ctrl.lpgbt.trigger.uplink.align_27;

    uplink_aligners_lpgbtloop : for I in 0 to NUM_UPLINKS-1 generate
      uplink_aligners_linkloop : for J in 0 to NUM_ELINKS-1 generate
        signal align_cnt : std_logic_vector (integer(ceil(log2(real(UPWIDTH))))-1 downto 0);

        -- don't care about bus coherence here..
        -- switching doesn't need to be glitchless
        attribute ASYNC_REG              : string;
        attribute ASYNC_REG of align_cnt : signal is "true";

      begin

        process (clk40) is
        begin
          if (rising_edge(clk40)) then
            align_cnt <= align_cnts (I)(J);
          end if;
        end process;

        frame_aligner_inst : entity work.frame_aligner
          generic map (WIDTH => UPWIDTH)
          port map (
            clock => clk40,
            cnt   => align_cnt,
            din   => uplink_data(I).data(UPWIDTH*(J+1)-1 downto UPWIDTH*J),
            dout  => uplink_data_aligned(I).data(UPWIDTH*(J+1)-1 downto UPWIDTH*J)
            );

      end generate;
    end generate;
  end generate;

  --------------------------------------------------------------------------------
  -- DAQ FIFO + Reader
  --
  -- Multiplex all elinks into a single FIFO that can be read from the DAQ
  --
  -- TODO: move this into its own block
  --
  --------------------------------------------------------------------------------

  fifo_gen : if (true) generate

    signal data      : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
    signal data_r    : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
    signal elink_sel : integer range 0 to 27;
    signal lpgbt_sel : integer range 0 to 1;

    constant DAQ_FIFO_DEPTH         : positive := 32768;
    constant DAQ_FIFO_WORDCNT_WIDTH : positive := integer(ceil(log2(real(DAQ_FIFO_DEPTH))));

    signal fifo_dout  : std_logic_vector (31 downto 0) := (others => '0');
    signal fifo_rd_en : std_logic                      := '0';
    signal fifo_wr_en : std_logic                      := '0';
    signal fifo_empty : std_logic                      := '0';
    signal fifo_valid : std_logic                      := '0';
    signal fifo_full  : std_logic                      := '0';

    signal daq_force_trigger, daq_trigger : std_logic                           := '0';
    signal daq_armed                      : std_logic                           := '0';
    signal daq_rearm                      : std_logic                           := '0';
    signal fifo_capture_depth             : integer range 0 to DAQ_FIFO_DEPTH-1;
    signal fifo_words_captured            : integer range 0 to DAQ_FIFO_DEPTH-1 := 0;

    signal trig0, trig1           : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
    signal trig0_mask, trig1_mask : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');

  begin

    trig0              <= ctrl.fifo_trig0(UPWIDTH-1 downto 0);
    trig1              <= ctrl.fifo_trig1(UPWIDTH-1 downto 0);
    trig0_mask         <= ctrl.fifo_trig0_mask(UPWIDTH-1 downto 0);
    trig1_mask         <= ctrl.fifo_trig1_mask(UPWIDTH-1 downto 0);
    mon.fifo_armed     <= daq_armed;
    mon.fifo_full      <= fifo_full;
    mon.fifo_empty     <= fifo_empty;
    daq_force_trigger  <= ctrl.fifo_force_trig;
    fifo_capture_depth <= to_integer(unsigned(ctrl.fifo_capture_depth));

    process (clk40) is
    begin
      if (rising_edge(clk40)) then

        if (fifo_wr_en = '1') then
          fifo_words_captured <= fifo_words_captured + 1;
        end if;

        -- trigger
        if ((daq_armed = '1' and
             ((trig1_mask and data) = (trig1_mask and trig1)) and
             ((trig0_mask and data_r) = (trig0_mask and trig0)))
            or daq_force_trigger = '1') then
          fifo_words_captured <= 0;
          daq_armed           <= '0';
          fifo_wr_en          <= '1';
        end if;

        -- reached fifo # of words
        if (fifo_capture_depth = fifo_words_captured) then
          daq_armed           <= '1';
          fifo_wr_en          <= '0';
          fifo_words_captured <= 0;
        end if;

        -- stop writing when it is full, and wait until it is re-armed
        if (fifo_full = '1') then
          daq_armed  <= '0';
          fifo_wr_en <= '0';
        end if;

        -- reset
        if (ctrl.fifo_reset = '1') then
          daq_armed  <= '1';
          fifo_wr_en <= '0';
        end if;

      end if;
    end process;

    -- copy for timing and align to system 40MHz
    elink_sel <= to_integer(unsigned(ctrl.fifo_elink_sel));
    lpgbt_sel <= to_integer(unsigned(std_logic_vector'("" & ctrl.fifo_lpgbt_sel)));  -- vhdl qualify operator

    process (clk40) is
    begin
      if (rising_edge(clk40)) then
        data   <= uplink_data_aligned(lpgbt_sel).data(8*(elink_sel+1)-1 downto 8*elink_sel);
        data_r <= data;
      end if;
    end process;

    fifo_sync_1 : entity work.fifo_sync
      generic map (
        DEPTH               => DAQ_FIFO_DEPTH,
        USE_ALMOST_FULL     => 1,
        WR_WIDTH            => 32,
        RD_WIDTH            => 32,
        WR_DATA_COUNT_WIDTH => DAQ_FIFO_WORDCNT_WIDTH,
        USE_WR_DATA_COUNT   => 1
        )
      port map (
        rst           => ctrl.fifo_reset,  -- Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
        clk           => clk40,
        wr_en         => fifo_wr_en,
        rd_en         => fifo_rd_en,
        din           => x"000000" & data,
        dout          => fifo_dout,
        valid         => fifo_valid,
        wr_data_count => open,
        overflow      => open,
        full          => fifo_full,
        almost_full   => open,
        empty         => fifo_empty
        );

    wishbone_fifo_reader_inst : entity work.wishbone_fifo_reader
      port map (
        clk       => clk40,
        reset     => reset,
        ipbus_in  => fifo_wb_in,
        ipbus_out => fifo_wb_out,
        rd_en     => fifo_rd_en,
        din       => fifo_dout,
        valid     => fifo_valid,
        empty     => fifo_empty
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
  -- DEBUG ILAS
  --------------------------------------------------------------------------------

  debug : if (C_DEBUG) generate
  begin

    ila_lpgbt_trig_inst : ila_lpgbt
      port map (
        clk                 => clk40,
        probe0(31 downto 0) => (others => '0'),
        probe1              => (others => '0'),
        probe2(0)           => '0',
        probe3(0)           => '0',
        probe4(0)           => '0',
        probe5(31 downto 0) => (others => '0'),
        probe6              => uplink_data_aligned(1).data,
        probe7(0)           => uplink_data_aligned(1).valid,
        probe8(0)           => uplink_ready(1),
        probe9(0)           => uplink_reset(1),
        probe10(0)          => uplink_fec_err(1),
        probe11             => uplink_data(1).ic,
        probe12             => "00",
        probe13             => uplink_data(1).ec,
        probe14             => "00",
        probe15(0)          => '1',
        probe16(0)          => '1',
        probe17(0)          => '1',
        probe18(0)          => '1'
        );

    ila_lpgbt_inst : ila_lpgbt
      port map (
        clk                 => clk40,
        probe0(31 downto 0) => (others => '0'),
        probe1              => downlink_data_aligned(0).data,
        probe2(0)           => downlink_data_aligned(0).valid,
        probe3(0)           => downlink_ready(0),
        probe4(0)           => downlink_reset(0),
        probe5(31 downto 0) => prbs_ff,
        probe6              => uplink_data_aligned(0).data,
        probe7(0)           => uplink_data_aligned(0).valid,
        probe8(0)           => uplink_ready(0),
        probe9(0)           => uplink_reset(0),
        probe10(0)          => uplink_fec_err(0),
        probe11             => uplink_data(0).ic,
        probe12             => downlink_data_aligned(0).ic,
        probe13             => uplink_data(0).ec,
        probe14             => downlink_data_aligned(0).ec,
        probe15(0)          => '1',
        probe16(0)          => '1',
        probe17(0)          => '1',
        probe18(0)          => '1'
        );

  end generate;

end behavioral;
