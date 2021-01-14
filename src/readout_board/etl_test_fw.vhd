library unisim;
use unisim.vcomponents.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_Ctrl.all;
use ctrl_lib.FW_INFO_Ctrl.all;
use ctrl_lib.MGT_Ctrl.all;

library work;
use work.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library ipbus;
use ipbus.ipbus.all;
use ipbus.ipbus_decode_etl_test_fw.all;

entity etl_test_fw is
  generic(

    MAC_ADDR : std_logic_vector (47 downto 0) := x"00_08_20_83_53_D1";
    IP_ADDR  : ip_addr_t                      := (192, 168, 0, 10);

    USE_PCIE : integer range 0 to 1 := 0;
    USE_ETH  : integer range 0 to 1 := 1;

    EN_LPGBTS : integer range 0 to 1 := 1;

    PCIE_LANES : integer range 1 to 8 := 1;

    NUM_GTS : integer := 10;

    NUM_RBS : integer := 5;

    NUM_LPGBTS_DAQ  : integer := 1;     -- Number of DAQ / Rb
    NUM_LPGBTS_TRIG : integer := 0;     -- Number of Trig / Rb
    NUM_DOWNLINKS   : integer := 1;     -- Number of Downlinks / Rb
    NUM_SCAS        : integer := 1;     -- Number of SCAs / Downlink

    NUM_REFCLK : integer := 2;

    -- these generics get set by hog at synthesis
    GLOBAL_DATE : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    GLOBAL_TIME : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    GLOBAL_VER  : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    GLOBAL_SHA  : std_logic_vector (31 downto 0) := x"DEFFFFFF"
    );
  port(

    -- PCIe clock and reset
    pcie_sys_clk_p : in std_logic_vector(0*USE_PCIE-1 downto 0);
    pcie_sys_clk_n : in std_logic_vector(0*USE_PCIE-1 downto 0);
    pcie_sys_rst   : in std_logic;

    -- PCIe lanes
    pcie_rx_p : in  std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);
    pcie_rx_n : in  std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);
    pcie_tx_p : out std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);
    pcie_tx_n : out std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);

    -- external oscillator, 125MHz
    osc_clk125_p : in std_logic;
    osc_clk125_n : in std_logic;

    -- external oscillator, 300MHz
    osc_clk300_p : in std_logic;
    osc_clk300_n : in std_logic;

    -- Transceiver ref-clocks
    si570_refclk_p : in std_logic;
    si570_refclk_n : in std_logic;

    --sma_refclk_p : in std_logic;
    --sma_refclk_n : in std_logic;

    tx_p : out std_logic_vector(EN_LPGBTS*NUM_GTS - 1 downto 0);
    tx_n : out std_logic_vector(EN_LPGBTS*NUM_GTS - 1 downto 0);
    rx_p : in  std_logic_vector(EN_LPGBTS*NUM_GTS - 1 downto 0);
    rx_n : in  std_logic_vector(EN_LPGBTS*NUM_GTS - 1 downto 0);

    sfp0_tx_disable  : out std_logic := '0';
    sfp1_tx_disable  : out std_logic := '0';
    si570_clk_sel_ls : out std_logic := '0';

    sgmii_clk_p : in  std_logic;
    sgmii_clk_n : in  std_logic;
    sgmii_txp   : out std_logic;
    sgmii_txn   : out std_logic;
    sgmii_rxp   : in  std_logic;
    sgmii_rxn   : in  std_logic;

    phy_resetb    : out   std_logic;    -- reset signal
    phy_mdio      : inout std_logic;    -- control line to program the PHY chip
    phy_mdc       : out   std_logic;    -- clock line (must be < 2.5 MHz)
    phy_interrupt : out   std_logic;    --

    -- status LEDs
    leds : out std_logic_vector(7 downto 0)

    );
end etl_test_fw;

architecture behavioral of etl_test_fw is


  signal gtwiz_userdata_tx_in  : std_logic_vector(32*NUM_GTS-1 downto 0);
  signal gtwiz_userdata_rx_out : std_logic_vector(32*NUM_GTS-1 downto 0);

  signal locked : std_logic;

  signal clk_osc125, clk_osc300 : std_logic;

  signal mgt_data_in  : std32_array_t (NUM_GTS-1 downto 0) := (others => (others => '0'));
  signal mgt_data_out : std32_array_t (NUM_GTS-1 downto 0);

  signal rxslide             : std_logic_vector (NUM_GTS-1 downto 0);
  signal trig_uplink_bitslip : std_logic_vector (NUM_RBS*NUM_LPGBTS_TRIG-1 downto 0);
  signal daq_uplink_bitslip  : std_logic_vector (NUM_RBS*NUM_LPGBTS_DAQ-1 downto 0);

  signal trig_uplink_mgt_word_array : std32_array_t (NUM_RBS*NUM_LPGBTS_TRIG-1 downto 0);
  signal daq_uplink_mgt_word_array  : std32_array_t (NUM_RBS*NUM_LPGBTS_DAQ-1 downto 0);
  signal downlink_mgt_word_array    : std32_array_t (NUM_RBS*NUM_DOWNLINKS-1 downto 0);

  signal userclk_rx_usrclk_out  : std_logic_vector (NUM_GTS-1 downto 0);
  signal userclk_rx_usrclk2_out : std_logic_vector (NUM_GTS-1 downto 0);

  signal userclk_tx_usrclk_out  : std_logic_vector (NUM_GTS-1 downto 0);
  signal userclk_tx_usrclk2_out : std_logic_vector (NUM_GTS-1 downto 0);

  signal clk40, clk320 : std_logic := '0';
  signal reset         : std_logic := '0';

  signal ipb_clk, ipb_rst : std_logic;
  signal nuke, soft_rst   : std_logic := '0';
  signal pcie_sys_rst_n   : std_logic;

  signal ipb_w : ipb_wbus;
  signal ipb_r : ipb_rbus;

  signal refclk, refclk_mirror : std_logic;

  signal refclk_bufg : std_logic;

  -- control and monitoring
  signal readout_board_mon  : READOUT_BOARD_Mon_array_t (NUM_RBS-1 downto 0);
  signal readout_board_ctrl : READOUT_BOARD_Ctrl_array_t (NUM_RBS-1 downto 0);

  signal mgt_mon  : MGT_Mon_t;
  signal mgt_ctrl : MGT_Ctrl_t;

  signal fw_info_mon : FW_INFO_Mon_t;

  component cylon1 is
    port (
      clock : in  std_logic;
      rate  : in  std_logic_vector (1 downto 0);
      q     : out std_logic_vector (7 downto 0)
      );
  end component;

  signal cylon : std_logic_vector (7 downto 0);

  component system_clocks is
    port (
      reset     : in  std_logic;
      clk_in300 : in  std_logic;
      clk_40    : out std_logic;
      clk_320   : out std_logic;
      locked    : out std_logic
      );
  end component;

  attribute MARK_DEBUG           : string;
  attribute MARK_DEBUG of locked : signal is "TRUE";

begin

  cylon1_inst : cylon1
    port map (
      clock => locked and clk40,
      rate  => "00",
      q     => cylon
      );

  pcie_sys_rst_n <= not pcie_sys_rst;

  leds(7 downto 0) <= cylon (7 downto 0);

  osc_clk125_ibuf : IBUFDS
    port map(
      i  => osc_clk125_p,
      ib => osc_clk125_n,
      o  => clk_osc125
      );

  osc_clk300_ibuf : IBUFDS
    port map(
      i  => osc_clk300_p,
      ib => osc_clk300_n,
      o  => clk_osc300
      );

  -- Infrastructure
  eth : if (USE_ETH = 1) generate
    eth_infra_inst : entity ipbus.eth_infra
      port map (
        osc_clk_300   => clk_osc300,
        osc_clk_125   => clk_osc125,
        rst_in        => (others => '0'),
        dip_sw        => (others => '0'),
        leds          => open,
        debug_leds    => open,
        sgmii_clk_p   => sgmii_clk_p,
        sgmii_clk_n   => sgmii_clk_n,
        sgmii_txp     => sgmii_txp,
        sgmii_txn     => sgmii_txn,
        sgmii_rxp     => sgmii_rxp,
        sgmii_rxn     => sgmii_rxn,
        phy_resetb    => phy_resetb,
        phy_mdio      => phy_mdio,
        phy_interrupt => phy_interrupt,
        phy_mdc       => phy_mdc,
        clk_ipb_o     => ipb_clk,
        rst_ipb_o     => ipb_rst,
        clk_aux_o     => open,
        rst_aux_o     => open,
        nuke          => nuke,
        soft_rst      => soft_rst,
        mac_addr      => MAC_ADDR,
        ip_addr       => to_slv(IP_ADDR),
        ipb_in        => ipb_r,
        ipb_out       => ipb_w
        );
  end generate;

  pcie : if (USE_PCIE = 1) generate
    pcie_infra : entity ipbus.pcie_infra
      port map(
        pcie_sys_clk_p => pcie_sys_clk_p(0),
        pcie_sys_clk_n => pcie_sys_clk_n(0),
        pcie_sys_rst_n => pcie_sys_rst_n,
        pcie_rx_p      => pcie_rx_p,
        pcie_rx_n      => pcie_rx_n,
        pcie_tx_p      => pcie_tx_p,
        pcie_tx_n      => pcie_tx_n,
        clk_osc        => clk_osc125,
        ipb_clk        => ipb_clk,
        ipb_rst        => ipb_rst,
        nuke           => nuke,
        soft_rst       => soft_rst,
        leds           => leds(1 downto 0),
        ipb_in         => ipb_r,
        ipb_out        => ipb_w
        );

  end generate;

  system_clocks_inst : system_clocks
    port map (
      reset     => std_logic0,
      clk_in300 => refclk_bufg,
      clk_40    => clk40,
      clk_320   => clk320,
      locked    => locked
      );

  control_inst : entity work.control
    generic map (
      EN_LPGBTS => EN_LPGBTS,
      NUM_RBS   => NUM_RBS
      )
    port map (
      reset              => ipb_rst,
      clock              => ipb_clk,
      fw_info_mon        => fw_info_mon,
      readout_board_mon  => readout_board_mon,
      readout_board_ctrl => readout_board_ctrl,
      mgt_mon            => mgt_mon,
      mgt_ctrl           => mgt_ctrl,
      ipb_w              => ipb_w,
      ipb_r              => ipb_r
      );

  refclk_ibufds : ibufds_gte3
    generic map(
      REFCLK_EN_TX_PATH  => '0',
      REFCLK_HROW_CK_SEL => (others => '0'),
      REFCLK_ICNTL_RX    => (others => '0')
      )
    port map (
      O     => refclk,
      ODIV2 => refclk_mirror,
      CEB   => '0',
      I     => si570_refclk_p,
      IB    => si570_refclk_n
      );

  mgtclk_img_bufg : BUFG_GT
    port map(
      I       => refclk_mirror,
      O       => refclk_bufg,
      CE      => '1',
      DIV     => (others => '0'),
      CLR     => '0',
      CLRMASK => '0',
      CEMASK  => '0'
      );

  lpgbt_gen : if (EN_LPGBTS = 1) generate

    rbgen : for I in 0 to NUM_RBS-1 generate
      constant NT : integer := NUM_LPGBTS_TRIG;
      constant ND : integer := NUM_LPGBTS_DAQ;
    begin
      readout_board_inst : entity work.readout_board
        generic map (
          NUM_LPGBTS_DAQ  => NUM_LPGBTS_DAQ,
          NUM_LPGBTS_TRIG => NUM_LPGBTS_TRIG,
          NUM_DOWNLINKS   => NUM_DOWNLINKS,
          NUM_SCAS        => NUM_SCAS
          )
        port map (
          clk40                      => clk40,
          clk320                     => clk320,
          txclk                      => userclk_tx_usrclk_out(I),
          rxclk                      => userclk_rx_usrclk_out(I),
          reset                      => not locked,

          -- slow control
          ctrl_clk                   => ipb_clk,
          mon                        => readout_board_mon(I),
          ctrl                       => readout_board_ctrl(I),

          -- data
          trig_uplink_bitslip        => trig_uplink_bitslip(NT*(I+1)-1 downto NT*I),
          daq_uplink_bitslip         => daq_uplink_bitslip(ND*(I+1)-1 downto ND*I),
          trig_uplink_mgt_word_array => trig_uplink_mgt_word_array(NT*(I+1)-1 downto NT*I),
          daq_uplink_mgt_word_array  => daq_uplink_mgt_word_array(ND*(I+1)-1 downto ND*I),
          downlink_mgt_word_array    => downlink_mgt_word_array(I downto I)
          );
    end generate;


    -- TODO: check this mapping
    rbdata : for I in 0 to NUM_RBS-1 generate
    begin
      -- rxslide
      rxslide(I*2) <= daq_uplink_bitslip(I);
      --rxslide(I*2+1) <= trig_uplink_bitslip(I);

      -- mgt downlink map
      mgt_data_in(I*2) <= downlink_mgt_word_array(I);
      --mgt_data_in(I*2+1) <= downlink_mgt_word_array(I);

      -- mgt uplink map
      --trig_uplink_mgt_word_array(I) <= mgt_data_out(I*2+1);
      daq_uplink_mgt_word_array(I) <= mgt_data_out(I*2);
    end generate;

    datagen : for I in 0 to NUM_GTS-1 generate
    begin
      gtwiz_userdata_tx_in (32*(I+1)-1 downto 32*I) <= mgt_data_in(I);
      mgt_data_out(I)                               <= gtwiz_userdata_rx_out (32*(I+1)-1 downto 32*I);

      xlx_ku_mgt_10g24_1 : entity work.xlx_ku_mgt_10g24
        port map (
          mgt_refclk_i      => refclk,
          mgt_freedrpclk_i  => ipb_clk,
          mgt_rxusrclk_o    => userclk_rx_usrclk_out(I),
          mgt_txusrclk_o    => userclk_tx_usrclk_out(I),
          mgt_txreset_i     => not locked,
          mgt_rxreset_i     => not locked,
          mgt_rxslide_i     => rxslide(I),
          mgt_entxcalibin_i => '0',
          mgt_txcalib_i     => (others => '0'),
          mgt_txready_o     => open,
          mgt_rxready_o     => open,
          mgt_tx_aligned_o  => open,
          mgt_tx_piphase_o  => open,
          mgt_usrword_i     => mgt_data_in(I),
          mgt_usrword_o     => mgt_data_out(I),
          rxp_i             => rx_p(I),
          rxn_i             => rx_n(I),
          txp_o             => tx_p(I),
          txn_o             => tx_n(I)
          );
    end generate;

  end generate;

  fw_info_mon.HOG_INFO.GLOBAL_DATE <= GLOBAL_FWDATE;
  fw_info_mon.HOG_INFO.GLOBAL_TIME <= GLOBAL_FWTIME;
  fw_info_mon.HOG_INFO.GLOBAL_VER  <= GLOBAL_FWVER;
  fw_info_mon.HOG_INFO.GLOBAL_SHA  <= GLOBAL_FWSHA;

end behavioral;
