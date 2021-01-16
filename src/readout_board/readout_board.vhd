library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lpgbt_fpga;
use lpgbt_fpga.lpgbtfpga_package.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_ctrl.all;

library work;
use work.types.all;
use work.lpgbt_pkg.all;

entity readout_board is
  generic(
    INST            : integer := 0;
    C_DEBUG         : boolean := true;
    NUM_LPGBTS_DAQ  : integer := 1;
    NUM_LPGBTS_TRIG : integer := 1;
    NUM_DOWNLINKS   : integer := 1;
    NUM_SCAS        : integer := 1;
    NUM_ELINKS      : integer := 28
    );
  port(

    clk40  : in std_logic;
    clk320 : in std_logic;

    reset : in std_logic;

    ctrl_clk : in  std_logic;
    mon      : out READOUT_BOARD_MON_t;
    ctrl     : in  READOUT_BOARD_CTRL_t;

    trig_uplink_bitslip : out std_logic_vector (NUM_LPGBTS_TRIG-1 downto 0);
    daq_uplink_bitslip  : out std_logic_vector (NUM_LPGBTS_DAQ-1 downto 0);

    trig_uplink_mgt_word_array  : in  std32_array_t (NUM_LPGBTS_TRIG-1 downto 0);
    daq_uplink_mgt_word_array   : in  std32_array_t (NUM_LPGBTS_DAQ-1 downto 0);
    daq_downlink_mgt_word_array : out std32_array_t (NUM_DOWNLINKS-1 downto 0)

    );
end readout_board;

architecture behavioral of readout_board is

  signal valid : std_logic;

  --------------------------------------------------------------------------------
  -- LPGBT Glue
  --------------------------------------------------------------------------------
  signal trig_uplink_data    : lpgbt_uplink_data_rt_array (NUM_LPGBTS_TRIG-1 downto 0);
  signal trig_uplink_reset   : std_logic_vector (NUM_LPGBTS_TRIG-1 downto 0);
  signal trig_uplink_ready   : std_logic_vector (NUM_LPGBTS_TRIG-1 downto 0);
  signal trig_uplink_fec_err : std_logic_vector (NUM_LPGBTS_TRIG-1 downto 0);

  signal daq_uplink_data    : lpgbt_uplink_data_rt_array (NUM_LPGBTS_DAQ-1 downto 0);
  signal daq_uplink_reset   : std_logic_vector (NUM_LPGBTS_DAQ-1 downto 0);
  signal daq_uplink_ready   : std_logic_vector (NUM_LPGBTS_DAQ-1 downto 0);
  signal daq_uplink_fec_err : std_logic_vector (NUM_LPGBTS_DAQ-1 downto 0);

  signal daq_downlink_data  : lpgbt_downlink_data_rt_array (NUM_DOWNLINKS-1 downto 0);
  signal daq_downlink_reset : std_logic_vector (NUM_DOWNLINKS-1 downto 0);
  signal daq_downlink_ready : std_logic_vector (NUM_DOWNLINKS-1 downto 0);

  attribute DONT_TOUCH                        : string;
  attribute DONT_TOUCH of daq_uplink_data     : signal is "true";
  attribute DONT_TOUCH of daq_uplink_reset    : signal is "true";
  attribute DONT_TOUCH of daq_uplink_ready    : signal is "true";
  attribute DONT_TOUCH of daq_uplink_bitslip  : signal is "true";
  attribute DONT_TOUCH of daq_uplink_fec_err  : signal is "true";
  attribute DONT_TOUCH of trig_uplink_data    : signal is "true";
  attribute DONT_TOUCH of trig_uplink_reset   : signal is "true";
  attribute DONT_TOUCH of trig_uplink_ready   : signal is "true";
  attribute DONT_TOUCH of trig_uplink_bitslip : signal is "true";
  attribute DONT_TOUCH of trig_uplink_fec_err : signal is "true";
  attribute DONT_TOUCH of daq_downlink_data   : signal is "true";
  attribute DONT_TOUCH of daq_downlink_reset  : signal is "true";
  attribute DONT_TOUCH of daq_downlink_ready  : signal is "true";

  -- master
  signal ic_data_i : std_logic_vector (1 downto 0);
  signal ic_data_o : std_logic_vector (1 downto 0);

  signal sca0_data_i : std_logic_vector (1 downto 0);
  signal sca0_data_o : std_logic_vector (1 downto 0);

  signal counter : integer range 0 to 255 := 0;

  signal phase : integer range 0 to 7 := 0;

  signal prbs_err_counters  : std32_array_t (27 downto 0);
  signal upcnt_err_counters : std32_array_t (27 downto 0);

begin

  -- FIXME: drive this in some sensible way?
  valid <= '1' when phase = 7 else '0';

  process (clk320) is
  begin
    if (rising_edge(clk320)) then
      if (phase = 7) then
        phase <= 0;
      else
        phase <= phase + 1;
      end if;
    end if;
  end process;

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (counter = 255) then
        counter <= 0;
      else
        counter <= counter + 1;
      end if;
    end if;

    daq_downlink_data(0).data <= std_logic_vector (to_unsigned(counter, 8)) &
                                 std_logic_vector (to_unsigned(counter, 8)) &
                                 std_logic_vector (to_unsigned(counter, 8)) &
                                 std_logic_vector (to_unsigned(counter, 8));
  end process;

  mon.lpgbt.daq.uplink.ready     <= daq_uplink_ready(0);
  mon.lpgbt.daq.downlink.ready   <= daq_downlink_ready(0);
  mon.lpgbt.trigger.uplink.ready <= trig_uplink_ready(0);
  daq_downlink_reset(0)          <= ctrl.lpgbt.daq.downlink.reset;
  daq_uplink_reset(0)            <= ctrl.lpgbt.daq.uplink.reset;

  --------------------------------------------------------------------------------
  -- GBT Slow Control
  --------------------------------------------------------------------------------

  gbt_controller_wrapper_inst : entity work.gbt_controller_wrapper
    generic map (
      g_CLK_FREQ       => 40,
      g_SCAS_PER_LPGBT => NUM_SCAS
      )
    port map (

      reset_i => reset,

      ctrl_clk => ctrl_clk,
      mon      => mon.sc,
      ctrl     => ctrl.sc,

      clk320  => clk320,
      clk40   => clk40,
      valid_i => '1',

      -- TODO: parameterize these outputs in an array to avoid hardcoded sizes
      ic_data_i => daq_uplink_data(0).ic,
      ic_data_o => daq_downlink_data(0).ic,

      sca0_data_i => daq_uplink_data(0).ec,
      sca0_data_o => daq_downlink_data(0).ec
      );

  daq_downlink_data(0).valid <= valid;

  --------------------------------------------------------------------------------
  -- LPGBT Cores
  --------------------------------------------------------------------------------

  lpgbt_link_wrapper : entity work.lpgbt_link_wrapper
    generic map (
      g_UPLINK_FEC    => FEC12,
      g_NUM_DOWNLINKS => NUM_DOWNLINKS,
      g_NUM_UPLINKS   => NUM_LPGBTS_DAQ
      )
    port map (
      reset => reset,

      downlink_clk => clk320,
      uplink_clk   => clk320,

      downlink_reset_i => daq_downlink_reset,
      uplink_reset_i   => daq_uplink_reset,

      downlink_data_i => daq_downlink_data,
      uplink_data_o   => daq_uplink_data,

      downlink_mgt_word_array_o => daq_downlink_mgt_word_array,
      uplink_mgt_word_array_i   => daq_uplink_mgt_word_array,

      downlink_ready_o => daq_downlink_ready,
      uplink_ready_o   => daq_uplink_ready,

      uplink_bitslip_o => daq_uplink_bitslip,
      uplink_fec_err_o => daq_uplink_fec_err
      );

  trig_lpgbt_link_wrapper : entity work.lpgbt_link_wrapper
    generic map (
      g_UPLINK_FEC    => FEC12,
      g_NUM_DOWNLINKS => 0,
      g_NUM_UPLINKS   => NUM_LPGBTS_TRIG
      )
    port map (
      reset => reset,

      downlink_clk => clk320,
      uplink_clk   => clk320,

      downlink_reset_i => (others => reset),
      uplink_reset_i   => (others => reset),

      downlink_data_i => (others => lpgbt_downlink_data_rt_zero),
      uplink_data_o   => trig_uplink_data,

      downlink_mgt_word_array_o => open,
      uplink_mgt_word_array_i   => trig_uplink_mgt_word_array,

      downlink_ready_o => open,
      uplink_ready_o   => trig_uplink_ready,

      uplink_bitslip_o => trig_uplink_bitslip,
      uplink_fec_err_o => trig_uplink_fec_err
      );

  --------------------------------------------------------------------------------
  -- PRBS
  --------------------------------------------------------------------------------

  -- TODO: handle clock crossing here to ipb clock?

  pat_checker : for I in 0 to 27 generate
    constant WIDTH : integer                             := 8;
    signal data    : std_logic_vector (WIDTH-1 downto 0) := (others => '0');

  begin

    -- copy for timing and align to system 40MHz
    process (clk40) is
    begin
      if (rising_edge(clk40)) then
        data <= daq_uplink_data(0).data(8*(I+1)-1 downto 8*I);
      end if;
    end process;

    pattern_checker_1 : entity work.pattern_checker
      generic map (
        DEBUG         => I = 0,
        COUNTER_WIDTH => 32,
        WIDTH         => WIDTH
        )
      port map (
        clock          => clk40,
        reset          => reset or ctrl.lpgbt.pattern_checker.reset,
        data           => data,
        check_prbs     => ctrl.lpgbt.pattern_checker.check_prbs_en(I),
        check_upcnt    => ctrl.lpgbt.pattern_checker.check_upcnt_en(I),
        prbs_errors_o  => prbs_err_counters(I),
        upcnt_errors_o => upcnt_err_counters(I)
        );
  end generate;

  -- multiplex the outputs into one register
  process (ctrl_clk) is
    variable sel : integer;

    variable prbs_ff  : std_logic_vector (31 downto 0) := (others => '0');
    variable upcnt_ff : std_logic_vector (31 downto 0) := (others => '0');

    -- don't care too much about bus coherence here.. the counters should just be zero
    -- and exact numbers don't really matter..
    attribute ASYNC_REG             : string;
    attribute ASYNC_REG of prbs_ff  : variable is "true";
    attribute ASYNC_REG of upcnt_ff : variable is "true";
  begin
    if (rising_edge(ctrl_clk)) then
      sel := to_integer(unsigned(ctrl.lpgbt.pattern_checker.sel));

      prbs_ff  := prbs_err_counters(sel);
      upcnt_ff := upcnt_err_counters(sel);

      mon.lpgbt.pattern_checker.prbs_errors  <= prbs_ff;
      mon.lpgbt.pattern_checker.upcnt_errors <= upcnt_ff;
    end if;
  end process;


  timer : entity work.counter
    generic map (
      roll_over   => false,
      async_reset => false,
      width       => 64
      )
    port map (
      clk                 => clk40,
      reset               => reset or ctrl.lpgbt.pattern_checker.reset,
      enable              => '1',
      event               => '1',
      count(31 downto 0)  => mon.lpgbt.pattern_checker.timer_lsbs,
      count(63 downto 32) => mon.lpgbt.pattern_checker.timer_msbs,
      at_max              => open
      );

  --------------------------------------------------------------------------------
  -- DEBUG
  --------------------------------------------------------------------------------

  debug : if (C_DEBUG) generate

    component vio_lpgbt
      port (
        clk        : in  std_logic;
        probe_in0  : in  std_logic_vector(0 downto 0);
        probe_in1  : in  std_logic_vector(0 downto 0);
        probe_out0 : out std_logic_vector(0 downto 0);
        probe_out1 : out std_logic_vector(0 downto 0)
        );
    end component;

    component ila_lpgbt
      port (
        clk     : in std_logic;
        probe0  : in std_logic_vector(31 downto 0);
        probe1  : in std_logic_vector(31 downto 0);
        probe2  : in std_logic_vector(0 downto 0);
        probe3  : in std_logic_vector(0 downto 0);
        probe4  : in std_logic_vector(0 downto 0);
        probe5  : in std_logic_vector(31 downto 0);
        probe6  : in std_logic_vector(223 downto 0);
        probe7  : in std_logic_vector(0 downto 0);
        probe8  : in std_logic_vector(0 downto 0);
        probe9  : in std_logic_vector(0 downto 0);
        probe10 : in std_logic_vector(0 downto 0);
        probe11 : in std_logic_vector(1 downto 0);
        probe12 : in std_logic_vector(1 downto 0);
        probe13 : in std_logic_vector(1 downto 0);
        probe14 : in std_logic_vector(1 downto 0);
        probe15 : in std_logic_vector(0 downto 0);
        probe16 : in std_logic_vector(0 downto 0);
        probe17 : in std_logic_vector(0 downto 0);
        probe18 : in std_logic_vector(0 downto 0)
        );
    end component;

  begin

    ila_daq_lpgbt_inst : ila_lpgbt
      port map (
        clk        => clk320,
        probe0     => daq_downlink_mgt_word_array(0),
        probe1     => daq_downlink_data(0).data,
        probe2(0)  => daq_downlink_data(0).valid,
        probe3(0)  => daq_downlink_ready(0),
        probe4(0)  => daq_downlink_reset(0),
        probe5     => daq_uplink_mgt_word_array(0),
        probe6     => daq_uplink_data(0).data,
        probe7(0)  => daq_uplink_data(0).valid,
        probe8(0)  => daq_uplink_ready(0),
        probe9(0)  => daq_uplink_reset(0),
        probe10(0) => daq_uplink_fec_err(0),
        probe11    => ic_data_i,
        probe12    => ic_data_o,
        probe13    => sca0_data_i,
        probe14    => sca0_data_o,
        probe15(0) => clk40,
        probe16(0) => not clk40,
        probe17(0) => '1',
        probe18(0) => '1'
        );

    -- dl_vio : vio_lpgbt
    --   port map (
    --     clk           => clk320,
    --     probe_out0(0) => daq_downlink_reset(0),
    --     probe_out1(0) => daq_uplink_reset(0),
    --     probe_in0(0)  => daq_uplink_ready(0),
    --     probe_in1(0)  => daq_downlink_ready(0)
    --     );

  end generate;

end behavioral;
