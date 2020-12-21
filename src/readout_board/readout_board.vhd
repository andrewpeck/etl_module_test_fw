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
    NUM_LPGBTS_DAQ  : integer := 1;
    NUM_LPGBTS_TRIG : integer := 1;
    NUM_DOWNLINKS   : integer := 1;
    NUM_SCAS        : integer := 1
    );
  port(

    clk40  : in std_logic;
    clk320 : in std_logic;

    txclk : in std_logic;
    rxclk : in std_logic;

    reset : in std_logic;

    mon  : out READOUT_BOARD_MON_t;
    ctrl : in  READOUT_BOARD_CTRL_t;

    trig_uplink_bitslip : out std_logic_vector (NUM_LPGBTS_TRIG-1 downto 0);
    daq_uplink_bitslip  : out std_logic_vector (NUM_LPGBTS_DAQ-1 downto 0);

    trig_uplink_mgt_word_array : in  std32_array_t (NUM_LPGBTS_TRIG-1 downto 0);
    daq_uplink_mgt_word_array  : in  std32_array_t (NUM_LPGBTS_DAQ-1 downto 0);
    downlink_mgt_word_array    : out std32_array_t (NUM_DOWNLINKS-1 downto 0)

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

  signal downlink_data  : lpgbt_downlink_data_rt_array (NUM_DOWNLINKS-1 downto 0);
  signal downlink_reset : std_logic_vector (NUM_DOWNLINKS-1 downto 0);
  signal downlink_ready : std_logic_vector (NUM_DOWNLINKS-1 downto 0);

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
  attribute DONT_TOUCH of downlink_data       : signal is "true";
  attribute DONT_TOUCH of downlink_reset      : signal is "true";
  attribute DONT_TOUCH of downlink_ready      : signal is "true";

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


  -- FIXME: connect these

  -- master
  signal ic_data_i : std_logic_vector (1 downto 0);
  signal ic_data_o : std_logic_vector (1 downto 0);

  signal sca0_data_i : std_logic_vector (1 downto 0);
  signal sca0_data_o : std_logic_vector (1 downto 0);

  signal counter : integer := 0;

  signal phase : integer range 0 to 7 := 0;

  component vio_lpgbt
    port (
      clk        : in  std_logic;
      probe_in0  : in  std_logic_vector(0 downto 0);
      probe_in1  : in  std_logic_vector(0 downto 0);
      probe_out0 : out std_logic_vector(0 downto 0);
      probe_out1 : out std_logic_vector(0 downto 0)
      );
  end component;

begin

  dl_vio : vio_lpgbt
    port map (
      clk           => clk320,
      probe_out0(0) => downlink_reset(0),
      probe_out1(0) => daq_uplink_reset(0),
      probe_in0(0)  => daq_uplink_ready(0),
      probe_in1(0)  => downlink_ready(0)
      );

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
      counter <= counter + 1;
    end if;
  end process;

  ila_daq_lpgbt_inst : ila_lpgbt
    port map (
      clk        => clk320,
      probe0     => downlink_mgt_word_array(0),
      probe1     => downlink_data(0).data,
      probe2(0)  => downlink_data(0).valid,
      probe3(0)  => downlink_ready(0),
      probe4(0)  => downlink_reset(0),
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
      probe15(0) => txclk,
      probe16(0) => not txclk,
      probe17(0) => rxclk,
      probe18(0) => not rxclk
      );

  -- ila_trg_lpgbt_inst : ila_lpgbt
  --   port map (
  --     clk    => clk320,
  --     probe0 => (others => '0'),
  --     probe1 => (others => '0'),
  --     probe2 => trig_uplink_mgt_word_array(0),
  --     probe3 => trig_uplink_data(0).data,
  --     probe4 => "00",
  --     probe5 => "00"
  --     );

  gbt_controller_wrapper_inst : entity work.gbt_controller_wrapper
    generic map (
      g_CLK_FREQ       => 40,
      g_SCAS_PER_LPGBT => NUM_SCAS
      )
    port map (
      reset_i => reset,
      mon     => mon.sc,
      ctrl    => ctrl.sc,
      clk320  => clk320,
      clk40   => clk40,
      valid_i => '1',

      -- FIXME: parameterize these outputs in an array to avoid hardcoded sizes
      ic_data_i => daq_uplink_data(0).ic,
      ic_data_o => downlink_data(0).ic,

      sca0_data_i => daq_uplink_data(0).ec,
      sca0_data_o => downlink_data(0).ec
      );

  downlink_data(0).data  <= std_logic_vector (to_unsigned(counter, 32));
  downlink_data(0).valid <= valid;

  lpgbt_link_wrapper : entity work.lpgbt_link_wrapper
    generic map (
      g_UPLINK_FEC    => FEC12,
      g_NUM_DOWNLINKS => NUM_DOWNLINKS,
      g_NUM_UPLINKS   => NUM_LPGBTS_DAQ
      )
    port map (
      reset => reset,

      downlink_clk => txclk,
      uplink_clk   => rxclk,

      downlink_reset_i => downlink_reset,
      uplink_reset_i   => daq_uplink_reset,

      downlink_data_i => downlink_data,
      uplink_data_o   => daq_uplink_data,

      downlink_mgt_word_array_o => downlink_mgt_word_array,
      uplink_mgt_word_array_i   => daq_uplink_mgt_word_array,

      downlink_ready_o => downlink_ready,
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

      downlink_clk => txclk,
      uplink_clk   => rxclk,

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

end behavioral;
