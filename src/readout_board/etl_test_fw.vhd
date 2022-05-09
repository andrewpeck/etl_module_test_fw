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

    USE_SYSTEM_IBERT : boolean := true;

    USE_EXT_REF : boolean := false;

    MAC_ADDR_BASE : std_logic_vector (47 downto 0) := x"00_08_20_83_53_00";
    IP_ADDR_BASE  : ip_addr_t                      := (192, 168, 0, 10);

    USE_PCIE : integer range 0 to 1 := 0;
    USE_ETH  : integer range 0 to 1 := 1;

    EN_LPGBTS : integer range 0 to 1 := 1;

    PCIE_LANES : integer range 1 to 8 := 1;

    NUM_RBS : integer := 1;

    NUM_LPGBTS_DAQ  : integer := 1;     -- Number of DAQ / Rb
    NUM_LPGBTS_TRIG : integer := 1;     -- Number of Trig / Rb
    NUM_DOWNLINKS   : integer := 1;     -- Number of Downlinks / Rb
    NUM_SCAS        : integer := 1;     -- Number of SCAs / Downlink

    NUM_REFCLK : integer := 2;

    -- these generics get set by hog at synthesis
    GLOBAL_DATE : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    GLOBAL_TIME : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    GLOBAL_VER  : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    GLOBAL_SHA  : std_logic_vector (31 downto 0) := x"DEFFFFFF";
    REPO_SHA    : std_logic_vector (31 downto 0) := x"DEFFFFFF"
    );
  port(

    --------------------------------------------------------------------------------
    -- PCIE
    --------------------------------------------------------------------------------

    -- PCIe clock and reset
    pcie_sys_clk_p : in std_logic_vector(0*USE_PCIE-1 downto 0);
    pcie_sys_clk_n : in std_logic_vector(0*USE_PCIE-1 downto 0);
    pcie_sys_rst   : in std_logic;

    -- PCIe lanes
    pcie_rx_p : in  std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);
    pcie_rx_n : in  std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);
    pcie_tx_p : out std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);
    pcie_tx_n : out std_logic_vector(PCIE_LANES*USE_PCIE-1 downto 0);

    --------------------------------------------------------------------------------
    -- Oscillators
    --------------------------------------------------------------------------------

    -- external oscillator, 125MHz
    osc_clk125_p : in std_logic;
    osc_clk125_n : in std_logic;

    -- external oscillator, 300MHz
    osc_clk300_p : in std_logic;
    osc_clk300_n : in std_logic;

    si570_usrclk_p : in std_logic;
    si570_usrclk_n : in std_logic;

    --------------------------------------------------------------------------------
    -- Transceiver ref-clocks
    --------------------------------------------------------------------------------

    si570_refclk_p : in std_logic;
    si570_refclk_n : in std_logic;

    sma_refclk_p : in std_logic;
    sma_refclk_n : in std_logic;

    --------------------------------------------------------------------------------
    -- Clock output
    --------------------------------------------------------------------------------

    clock_o_p : out std_logic;
    clock_o_n : out std_logic;

    --------------------------------------------------------------------------------
    -- Transceivers
    --------------------------------------------------------------------------------

    tx_p : out std_logic_vector(EN_LPGBTS*NUM_RBS*(NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG) - 1 downto 0);
    tx_n : out std_logic_vector(EN_LPGBTS*NUM_RBS*(NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG) - 1 downto 0);
    rx_p : in  std_logic_vector(EN_LPGBTS*NUM_RBS*(NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG) - 1 downto 0);
    rx_n : in  std_logic_vector(EN_LPGBTS*NUM_RBS*(NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG) - 1 downto 0);

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
    leds : out std_logic_vector(7 downto 0);

    sw : in std_logic_vector (3 downto 0)

    );
end etl_test_fw;

architecture behavioral of etl_test_fw is

  signal mac_addr : std_logic_vector (47 downto 0) := MAC_ADDR_BASE; 
  signal ip_addr : ip_addr_t := IP_ADDR_BASE;

  constant MAX_GTS : integer := 10;
  constant NUM_GTS : integer := NUM_RBS * (NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG);

  constant NUM_UPLINKS : integer := NUM_RBS * (NUM_LPGBTS_DAQ + NUM_LPGBTS_TRIG);

  signal gtwiz_userdata_tx_in  : std_logic_vector(32*NUM_GTS-1 downto 0);
  signal gtwiz_userdata_rx_out : std_logic_vector(32*NUM_GTS-1 downto 0);

  signal locked : std_logic;

  signal clk_osc125, clk_osc300           : std_logic;
  signal clk_osc125_ibuf, clk_osc300_ibuf : std_logic;
  signal si570_usrclk_ibuf, si570_usrclk  : std_logic;

  signal si570_usrclk_oddr : std_logic := '0';

  signal mgt_data_in  : std32_array_t (NUM_GTS-1 downto 0) := (others => (others => '0'));
  signal mgt_data_out : std32_array_t (NUM_GTS-1 downto 0);

  signal rxslide                 : std_logic_vector (NUM_GTS-1 downto 0);
  signal uplink_bitslip          : std_logic_vector (NUM_UPLINKS-1 downto 0);
  signal uplink_mgt_word_array   : std32_array_t (NUM_UPLINKS-1 downto 0);
  signal downlink_mgt_word_array : std32_array_t (NUM_DOWNLINKS-1 downto 0);

  signal mgt_tx_reset, mgt_rx_reset : std_logic_vector (MAX_GTS-1 downto 0) := (others => '0');
  signal mgt_tx_ready, mgt_rx_ready : std_logic_vector (MAX_GTS-1 downto 0) := (others => '0');

  signal txclk, rxclk       : std_logic_vector (9 downto 0)         := (others => '0');
  signal rxclk_freq         : std32_array_t (9 downto 0);
  signal txclk_freq         : std32_array_t (9 downto 0);

  signal clk40, clk320 : std_logic := '0';
  signal reset         : std_logic := '0';

  signal ipb_clk, ipb_rst : std_logic;
  signal nuke, soft_rst   : std_logic := '0';
  signal pcie_sys_rst_n   : std_logic;

  signal eth_ipb_w, pci_ipb_w : ipb_wbus := (ipb_strobe => '0',
                                             ipb_addr   => (others => '0'),
                                             ipb_wdata  => (others => '0'),
                                             ipb_write  => '0');

  signal eth_ipb_r, pci_ipb_r : ipb_rbus;

  signal refclk, refclk_mirror : std_logic;

  signal refclk_bufg : std_logic;

  -- control and monitoring
  signal readout_board_mon  : READOUT_BOARD_Mon_array_t (NUM_RBS-1 downto 0);
  signal readout_board_ctrl : READOUT_BOARD_Ctrl_array_t (NUM_RBS-1 downto 0);

  signal fifo_ipb_w_array : ipb_wbus_array(2*NUM_RBS - 1 downto 0);
  signal fifo_ipb_r_array : ipb_rbus_array(2*NUM_RBS - 1 downto 0);

  signal daq_ipb_w_array : ipb_wbus_array(NUM_RBS - 1 downto 0);
  signal daq_ipb_r_array : ipb_rbus_array(NUM_RBS - 1 downto 0);

  signal mgt_mon  : MGT_Mon_t;
  signal mgt_ctrl : MGT_Ctrl_t;

  signal fw_info_mon : FW_INFO_Mon_t;

  component fader is
    port (
      clock : in  std_logic;
      led   : out std_logic
      );
  end component;

  component cylon1 is
    port (
      clock : in  std_logic;
      rate  : in  std_logic_vector (1 downto 0);
      q     : out std_logic_vector (7 downto 0)
      );
  end component;

  component cylon2 is
    port (
      clock : in  std_logic;
      rate  : in  std_logic_vector (1 downto 0);
      q     : out std_logic_vector (7 downto 0)
      );
  end component;

  signal cylon1_signal : std_logic_vector (7 downto 0);
  signal cylon2_signal : std_logic_vector (7 downto 0);
  signal breath        : std_logic;

  component system_clocks is
    port (
      reset     : in  std_logic;
      clk_in320 : in  std_logic;
      clk_40    : out std_logic;
      clk_320   : out std_logic;
      locked    : out std_logic
      );
  end component;

begin

  cylon1_inst : cylon1
    port map (
      clock => locked and clk40,
      rate  => "00",
      q     => cylon1_signal
      );

  cylon2_inst : cylon2
    port map (
      clock => locked and clk40,
      rate  => "00",
      q     => cylon2_signal
      );

  fader_inst : fader
    port map (
      clock => clk40,
      led   => breath
      );


  pcie_sys_rst_n <= not pcie_sys_rst;

  process (clk40) is
  begin
    if (rising_edge(clk40)) then

      if (readout_board_mon(0).lpgbt.daq.uplink.ready = '1' and
          readout_board_mon(0).lpgbt.trigger.uplink.ready = '1') then

        leds(7 downto 0) <= cylon2_signal (7 downto 0);

      elsif  (readout_board_mon(0).lpgbt.daq.uplink.ready = '1') then

        leds(7 downto 0) <= cylon1_signal (7 downto 0);

      else

        leds(7 downto 0) <= breath & breath & breath & breath &
                            breath & breath & breath & breath;

      end if;

    end if;
  end process;

  si570_usrclk_ibuf_inst : IBUFDS
    port map(
      i  => si570_usrclk_p,
      ib => si570_usrclk_n,
      o  => si570_usrclk_ibuf
      );

  osc_clk125_ibuf_inst : IBUFDS
    port map(
      i  => osc_clk125_p,
      ib => osc_clk125_n,
      o  => clk_osc125_ibuf
      );

  osc_clk300_ibuf_inst : IBUFDS
    port map(
      i  => osc_clk300_p,
      ib => osc_clk300_n,
      o  => clk_osc300_ibuf
      );

  si570_bufg : BUFG
    port map(
      i => si570_usrclk_ibuf,
      o => si570_usrclk
      );

  osc125_bufg : BUFG
    port map(
      i => clk_osc125_ibuf,
      o => clk_osc125
      );

  osc300_bufg : BUFG
    port map(
      i => clk_osc300_ibuf,
      o => clk_osc300
      );

  ODDRE1_inst : ODDRE1
    generic map (
      IS_C_INVERTED  => '0',            -- Optional inversion for C
      IS_D1_INVERTED => '0',            -- Unsupported, do not use
      IS_D2_INVERTED => '0',            -- Unsupported, do not use
      SIM_DEVICE     => "ULTRASCALE",   -- Set the device version for simulation functionality (ULTRASCALE)
      SRVAL          => '0'             -- Initializes the ODDRE1 Flip-Flops to the specified value ('0', '1')
      )
    port map (
      Q  => si570_usrclk_oddr,          -- 1-bit output: Data output to IOB
      C  => si570_usrclk,               -- 1-bit input: High-speed clock input
      D1 => '0',                        -- 1-bit input: Parallel data input 1
      D2 => '1',                        -- 1-bit input: Parallel data input 2
      SR => '0'                         -- 1-bit input: Active-High Async Reset
      );

  OBUFDS_inst : OBUFDS
    generic map (
      IOSTANDARD => "DEFAULT",          -- Specify the output I/O standard
      SLEW       => "SLOW")             -- Specify the output slew rate
    port map (
      O  => clock_o_p,                  -- Diff_p output (connect directly to top-level port)
      OB => clock_o_n,                  -- Diff_n output (connect directly to top-level port)
      I  => si570_usrclk_oddr           -- Buffer input
      );

  ip_addr(0)           <= IP_ADDR_BASE(0) + to_integer(unsigned(sw(3 downto 0)));
  mac_addr(3 downto 0) <= sw(3 downto 0);

  -- Infrastructure
  eth : if (USE_ETH = 1) generate
    eth_infra_inst : entity ipbus.eth_infra
      generic map (
        C_EXT_CLOCK => true)
      port map (
        ext_clk_i     => clk40,
        osc_clk_300   => clk_osc300_ibuf,
        osc_clk_125   => clk_osc125_ibuf,
        rst_in        => (others => '0'),
        dip_sw        => (others => '0'),
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
        mac_addr      => mac_addr,
        ip_addr       => to_slv(IP_ADDR),
        ipb_in        => eth_ipb_r,
        ipb_out       => eth_ipb_w
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
        clk_osc        => clk_osc125_ibuf,
        ipb_clk        => ipb_clk,
        ipb_rst        => ipb_rst,
        nuke           => nuke,
        soft_rst       => soft_rst,
        leds           => leds(1 downto 0),
        ipb_in         => pci_ipb_r,
        ipb_out        => pci_ipb_w
        );

  end generate;

  system_clocks_inst : system_clocks
    port map (
      reset     => std_logic0,
      clk_in320 => refclk_bufg,
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
      pci_ipb_w          => pci_ipb_w,
      pci_ipb_r          => pci_ipb_r,
      eth_ipb_w          => eth_ipb_w,
      eth_ipb_r          => eth_ipb_r,

      elink_ipb_w_array => fifo_ipb_w_array,
      elink_ipb_r_array => fifo_ipb_r_array,

      daq_ipb_w_array => daq_ipb_w_array,
      daq_ipb_r_array => daq_ipb_r_array

      );


  SI570_REF_GEN : if (not USE_EXT_REF) generate
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
  end generate;

  EXT_REF_GEN : if (USE_EXT_REF) generate
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
        I     => sma_refclk_p,
        IB    => sma_refclk_n
        );
  end generate;

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

  --------------------------------------------------------------------------------
  -- Readout Boards
  --------------------------------------------------------------------------------

  rb_gen : if (EN_LPGBTS = 1) generate

    rbgen : for I in 0 to NUM_RBS-1 generate
      constant NU : integer := NUM_LPGBTS_TRIG + NUM_LPGBTS_DAQ;
      constant ND : integer := 1;
    begin
      readout_board_inst : entity work.readout_board
        generic map (
          INST            => I,
          NUM_LPGBTS_DAQ  => NUM_LPGBTS_DAQ,
          NUM_LPGBTS_TRIG => NUM_LPGBTS_TRIG,
          NUM_DOWNLINKS   => NUM_DOWNLINKS,
          NUM_SCAS        => NUM_SCAS
          )
        port map (
          reset => not locked,

          --daq_txready  => tx_ready(I*2),
          --daq_rxready  => rx_ready(I*2),
          --trig_rxready => rx_ready(I*2+1),

          fifo_wb_in => fifo_ipb_w_array(I*2+1 downto I*2),
          fifo_wb_out => fifo_ipb_r_array(I*2+1 downto I*2),

          daq_wb_in => daq_ipb_w_array(I downto I),
          daq_wb_out => daq_ipb_r_array(I downto I),

          clk40  => clk40,
          clk320 => clk320,

          -- slow control
          ctrl_clk => ipb_clk,
          mon      => readout_board_mon(I),
          ctrl     => readout_board_ctrl(I),

          -- data
          uplink_bitslip          => uplink_bitslip (NU*(I+1)-1 downto NU*I),
          uplink_mgt_word_array   => uplink_mgt_word_array (NU*(I+1)-1 downto NU*I),
          downlink_mgt_word_array => downlink_mgt_word_array(ND*(I+1)-1 downto ND*I)
          );
    end generate;


    -- TODO: check this mapping the correspondence between mgt array and daq/trig array are what
    -- create the mapping to different sfp/firefly

    mgt_mon.mgt_tx_ready <= mgt_tx_ready;
    mgt_mon.mgt_rx_ready <= mgt_rx_ready;

    mgt_tx_reset <= mgt_ctrl.mgt_tx_reset;
    mgt_rx_reset <= mgt_ctrl.mgt_rx_reset;

    rbdata : for I in 0 to NUM_GTS-1 generate
    begin

      process (txclk(I)) is
      begin
        if (rising_edge(txclk(I))) then
          mgt_data_in(I)           <= downlink_mgt_word_array(I/2);
        end if;
      end process;

      process (rxclk(I)) is
      begin
        if (rising_edge(rxclk(I))) then
          rxslide(I)               <= uplink_bitslip(I);
          uplink_mgt_word_array(I) <= mgt_data_out(I);
        end if;
      end process;
    end generate;

    datagen : for I in 0 to NUM_GTS-1 generate

      signal txdata, rxdata : std_logic_vector (31 downto 0);

      signal drpclk  : std_logic;
      signal drpaddr : std_logic_vector(8 downto 0);
      signal drpen   : std_logic;
      signal drpdi   : std_logic_vector(15 downto 0);
      signal drprdy  : std_logic;
      signal drpdo   : std_logic_vector(15 downto 0);
      signal drpwe   : std_logic;

    begin

      gtwiz_userdata_tx_in (32*(I+1)-1 downto 32*I) <= mgt_data_in(I);
      mgt_data_out(I)                               <= gtwiz_userdata_rx_out (32*(I+1)-1 downto 32*I);

      -- TODO: connect DRP to ipb control registers
      ibert : if (USE_SYSTEM_IBERT) generate
        component system_ibert
          port (
            drpclk_o       : out std_logic_vector(0 downto 0);
            gt0_drpen_o    : out std_logic;
            gt0_drpwe_o    : out std_logic;
            gt0_drpaddr_o  : out std_logic_vector(8 downto 0);
            gt0_drpdi_o    : out std_logic_vector(15 downto 0);
            gt0_drprdy_i   : in  std_logic;
            gt0_drpdo_i    : in  std_logic_vector(15 downto 0);
            eyescanreset_o : out std_logic_vector(0 downto 0);
            rxrate_o       : out std_logic_vector(2 downto 0);
            txdiffctrl_o   : out std_logic_vector(3 downto 0);
            txprecursor_o  : out std_logic_vector(4 downto 0);
            txpostcursor_o : out std_logic_vector(4 downto 0);
            rxlpmen_o      : out std_logic_vector(0 downto 0);
            rxoutclk_i     : in  std_logic_vector(0 downto 0);
            clk            : in  std_logic
            );
        end component;
      begin

        system_ibert_inst : system_ibert
          port map (
            drpclk_o(0)       => drpclk,
            gt0_drpen_o       => drpen,
            gt0_drpwe_o       => drpwe,
            gt0_drpaddr_o     => drpaddr,
            gt0_drpdi_o       => drpdi,
            gt0_drprdy_i      => drprdy,
            gt0_drpdo_i       => drpdo,
            eyescanreset_o(0) => open,
            rxrate_o          => open,
            txdiffctrl_o      => open,
            txprecursor_o     => open,
            txpostcursor_o    => open,
            rxlpmen_o(0)      => open,
            rxoutclk_i(0)     => rxclk(I),
            clk               => ipb_clk
            );

      end generate;

      xlx_ku_mgt_10g24_1 : entity work.xlx_ku_mgt_10g24
        port map (
          mgt_refclk_i => refclk,

          -- drp
          mgt_freedrpclk_i => drpclk,
          drpaddr          => drpaddr,
          drpen            => drpen,
          drpdi            => drpdi,
          drprdy           => drprdy,
          drpdo            => drpdo,
          drpwe            => drpwe,

          mgt_rxusrclk_o    => rxclk(I),
          mgt_txusrclk_o    => txclk(I),
          mgt_txreset_i     => not locked or mgt_tx_reset(I),
          mgt_rxreset_i     => not locked or mgt_rx_reset(I),
          mgt_rxslide_i     => rxslide(I),
          mgt_entxcalibin_i => '0',
          mgt_txcalib_i     => (others => '0'),
          mgt_txready_o     => mgt_tx_ready(I),
          mgt_rxready_o     => mgt_rx_ready(I),
          mgt_tx_aligned_o  => open,
          mgt_tx_piphase_o  => open,
          mgt_usrword_i     => txdata,  -- mgt_data_in(I),
          mgt_usrword_o     => rxdata,  -- mgt_data_out(I),
          rxp_i             => rx_p(I),
          rxn_i             => rx_n(I),
          txp_o             => tx_p(I),
          txn_o             => tx_n(I)
          );

      mgt_cdc_lpgbt_to_fpga : entity work.fifo_async
        generic map (
          DEPTH    => 16,
          WR_WIDTH => 32,
          RD_WIDTH => 32)
        port map (
          rst    => not locked,         -- TODO: reset if the mgt is inactive
          wr_clk => rxclk(I),
          rd_clk => clk320,
          wr_en  => locked,
          rd_en  => locked,
          din    => rxdata,
          dout   => mgt_data_out(I),
          valid  => open,
          full   => open,
          empty  => open
          );

      mgt_cdc_fpga_to_lpgbt : entity work.fifo_async
        generic map (
          DEPTH    => 16,
          WR_WIDTH => 32,
          RD_WIDTH => 32)
        port map (
          rst    => not locked,         -- TODO: reset if the mgt is inactive
          wr_clk => clk320,
          rd_clk => txclk(I),
          wr_en  => locked,
          rd_en  => locked,
          din    => mgt_data_in(I),
          dout   => txdata,
          valid  => open,
          full   => open,
          empty  => open
          );

    end generate;
  end generate;

  --------------------------------------------------------------------------------
  -- Firmware Info
  --------------------------------------------------------------------------------

  fw_info_mon.HOG_INFO.GLOBAL_DATE <= GLOBAL_DATE;
  fw_info_mon.HOG_INFO.GLOBAL_TIME <= GLOBAL_TIME;
  fw_info_mon.HOG_INFO.GLOBAL_VER  <= GLOBAL_VER;
  fw_info_mon.HOG_INFO.GLOBAL_SHA  <= GLOBAL_SHA;
  fw_info_mon.HOG_INFO.REPO_SHA    <= REPO_SHA;

  process (ipb_clk) is
    variable upcnt : unsigned (63 downto 0) := (others => '0');
  begin
    if (rising_edge(ipb_clk)) then
      upcnt                   := upcnt + 1;
      fw_info_mon.uptime_lsbs <= std_logic_vector(upcnt (31 downto 0));
      fw_info_mon.uptime_msbs <= std_logic_vector(upcnt (63 downto 32));
    end if;
  end process;

  freq_counters : if (true) generate
    signal freq_cnt_clk    : std_logic;
    constant freq_cnt_freq : integer := 125000000;
  begin

    freq_cnt_clk <= clk_osc125;

    ipb_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => ipb_clk,
        rate  => fw_info_mon.ipbclk_freq
        );

    clk40_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => clk40,
        rate  => fw_info_mon.clk_40_freq
        );

    clk320_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => clk320,
        rate  => fw_info_mon.clk320_freq
        );

    refclk_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => refclk_bufg,
        rate  => fw_info_mon.refclk_freq
        );

    si570usr_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => si570_usrclk,
        rate  => fw_info_mon.clkusr_freq
        );


    clk125_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => clk_osc125,
        rate  => fw_info_mon.clk125_freq
        );

    clk300_frequency_counter_inst : entity work.frequency_counter
      generic map (clk_a_freq => freq_cnt_freq)
      port map (
        reset => reset,
        clk_a => freq_cnt_clk,
        clk_b => clk_osc300,
        rate  => fw_info_mon.clk300_freq
        );

    txrxclks : for I in 0 to 9 generate
    begin

      rxclk_frequency_counter_inst : entity work.frequency_counter
        generic map (clk_a_freq => freq_cnt_freq)
        port map (
          reset => reset,
          clk_a => freq_cnt_clk,
          clk_b => rxclk(I),
          rate  => rxclk_freq(I)
          );

      txclk_frequency_counter_inst : entity work.frequency_counter
        generic map (clk_a_freq => freq_cnt_freq)
        port map (
          reset => reset,
          clk_a => freq_cnt_clk,
          clk_b => txclk(I),
          rate  => txclk_freq(I)
          );

    end generate;

    fw_info_mon.rxclk0_freq <= rxclk_freq(0);
    fw_info_mon.rxclk1_freq <= rxclk_freq(1);
    fw_info_mon.rxclk2_freq <= rxclk_freq(2);
    fw_info_mon.rxclk3_freq <= rxclk_freq(3);
    fw_info_mon.rxclk4_freq <= rxclk_freq(4);
    fw_info_mon.rxclk5_freq <= rxclk_freq(5);
    fw_info_mon.rxclk6_freq <= rxclk_freq(6);
    fw_info_mon.rxclk7_freq <= rxclk_freq(7);
    fw_info_mon.rxclk8_freq <= rxclk_freq(8);
    fw_info_mon.rxclk9_freq <= rxclk_freq(9);

    fw_info_mon.txclk0_freq <= txclk_freq(0);
    fw_info_mon.txclk1_freq <= txclk_freq(1);
    fw_info_mon.txclk2_freq <= txclk_freq(2);
    fw_info_mon.txclk3_freq <= txclk_freq(3);
    fw_info_mon.txclk4_freq <= txclk_freq(4);
    fw_info_mon.txclk5_freq <= txclk_freq(5);
    fw_info_mon.txclk6_freq <= txclk_freq(6);
    fw_info_mon.txclk7_freq <= txclk_freq(7);
    fw_info_mon.txclk8_freq <= txclk_freq(8);
    fw_info_mon.txclk9_freq <= txclk_freq(9);

  end generate;

end behavioral;
