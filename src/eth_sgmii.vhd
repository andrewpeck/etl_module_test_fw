---------------------------------------------------------------------------------
--
--   Copyright 2017 - Rutherford Appleton Laboratory and University of Bristol
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
--
--                                     - - -
--
--   Additional information about ipbus-firmare and the list of ipbus-firmware
--   contacts are available at
--
--       https://ipbus.web.cern.ch/ipbus
--
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity eth_sgmii_lvds is
  port(
    -- clock and data i/o (connected to external device)
    logic_clk     : in    std_logic;
    logic_rst     : in    std_logic;
    sgmii_clk_p   : in    std_logic;    --> 625 MHz clock
    sgmii_clk_n   : in    std_logic;
    sgmii_txp     : out   std_logic;
    sgmii_txn     : out   std_logic;
    sgmii_rxp     : in    std_logic;
    sgmii_rxn     : in    std_logic;
    -- output reset and power signals (to the external device)
    phy_resetb    : out   std_logic;    -- reset signal (inverted)
    phy_mdio      : inout std_logic;    -- control line to program the PHY chip
    phy_mdc       : out   std_logic;    -- clock line (must be < 2.5 MHz)
    phy_interrupt : out   std_logic;
    -- 125 MHz clocks
    clk125_eth    : out   std_logic;    -- 125 MHz from ethernet
    -- input free-running clock
    clk125_fr     : in    std_logic;
    -- connection control and status (to logic)
    rst           : in    std_logic;    -- request reset of ethernet system
    rst_o         : out   std_logic;    -- request reset of output
    locked        : out   std_logic;    -- locked to ethernet clock
    -- data in and out (connected to ipbus)
    tx_data       : in    std_logic_vector(7 downto 0);
    tx_valid      : in    std_logic;
    tx_last       : in    std_logic;
    tx_error      : in    std_logic;
    tx_ready      : out   std_logic;
    rx_data       : out   std_logic_vector(7 downto 0);
    rx_valid      : out   std_logic;
    rx_last       : out   std_logic;
    rx_error      : out   std_logic
    );

end eth_sgmii_lvds;

architecture rtl of eth_sgmii_lvds is

  component eth_mac_1g_fifo
    port (
      rx_clk    : in std_logic;
      rx_rst    : in std_logic;
      tx_clk    : in std_logic;
      tx_rst    : in std_logic;
      logic_clk : in std_logic;
      logic_rst : in std_logic;

      -- AXI input
      tx_axis_tdata  : in  std_logic_vector;
      tx_axis_tkeep  : in  std_logic_vector;
      tx_axis_tvalid : in  std_logic;
      tx_axis_tready : out std_logic;
      tx_axis_tlast  : in  std_logic;
      tx_axis_tuser  : in  std_logic_vector;

      -- AXI output
      rx_axis_tdata  : out std_logic_vector;
      rx_axis_tkeep  : out std_logic_vector;
      rx_axis_tready : in  std_logic;
      rx_axis_tvalid : out std_logic;
      rx_axis_tlast  : out std_logic;
      rx_axis_tuser  : out std_logic_vector;

      -- GMII interface
      gmii_rxd   : in  std_logic_vector;
      gmii_rx_dv : in  std_logic;
      gmii_rx_er : in  std_logic;
      gmii_txd   : out std_logic_vector;
      gmii_tx_en : out std_logic;
      gmii_tx_er : out std_logic;

      -- Control
      rx_clk_enable : in std_logic;
      tx_clk_enable : in std_logic;
      rx_mii_select : in std_logic;
      tx_mii_select : in std_logic;

      -- Status
      tx_error_underflow : out std_logic;
      tx_fifo_overflow   : out std_logic;
      tx_fifo_bad_frame  : out std_logic;
      tx_fifo_good_frame : out std_logic;
      rx_error_bad_frame : out std_logic;
      rx_error_bad_fcs   : out std_logic;
      rx_fifo_overflow   : out std_logic;
      rx_fifo_bad_frame  : out std_logic;
      rx_fifo_good_frame : out std_logic;

      -- Configuration
      ifg_delay : in std_logic_vector (7 downto 0)
      );
  end component;

  component gig_eth_pcs_pma_gmii_to_sgmii_bridge
    port (
      txp : out std_logic;
      txn : out std_logic;
      rxp : in  std_logic;
      rxn : in  std_logic;

      refclk625_p : in std_logic;
      refclk625_n : in std_logic;

      mmcm_locked_out : out std_logic;

      sgmii_clk_r  : out std_logic;
      sgmii_clk_f  : out std_logic;
      sgmii_clk_en : out std_logic;

      rst_125_out : out std_logic;
      clk312_out  : out std_logic;
      clk125_out  : out std_logic;
      clk625_out  : out std_logic;

      gmii_txd     : in  std_logic_vector(7 downto 0);
      gmii_tx_en   : in  std_logic;
      gmii_tx_er   : in  std_logic;
      gmii_rxd     : out std_logic_vector(7 downto 0);
      gmii_rx_dv   : out std_logic;
      gmii_rx_er   : out std_logic;
      gmii_isolate : out std_logic;

      configuration_vector : in std_logic_vector(4 downto 0);


      an_interrupt         : out std_logic;
      an_adv_config_vector : in  std_logic_vector(15 downto 0);
      an_adv_config_val    : in  std_logic;

      an_restart_config : in std_logic;

      speed_is_10_100 : in std_logic;
      speed_is_100    : in std_logic;

      status_vector : out std_logic_vector(15 downto 0);

      reset : in std_logic;

      signal_detect : in std_logic;

      mdc                 : in  std_logic;
      mdio_i              : in  std_logic;
      mdio_o              : out std_logic;
      mdio_t              : out std_logic;
      ext_mdc             : out std_logic;
      ext_mdio_i          : in  std_logic;
      ext_mdio_o          : out std_logic;
      ext_mdio_t          : out std_logic;
      phyaddr             : in  std_logic_vector(4 downto 0);
      configuration_valid : in  std_logic;

      idelay_rdy_out : out std_logic
      );
  end component;

  signal link_up      : std_logic;
  signal speedis100   : std_logic;
  signal speedis10100 : std_logic;

  signal phy_reset, mac_reset : std_logic := '1';
  signal phy_cfg_not_done     : std_logic := '1';

  signal clk_en : std_logic;

  signal mdio_i, mdio_o, mdio_t : std_logic;

  --- clocks
  signal clk125_sgmii, clk2mhz      : std_logic;
  --- slow clocks and edges
  signal onehz, onehz_d, onehz_re   : std_logic := '0';  -- slow generated clocks
  --- resets
  signal rst125_sgmii               : std_logic;         -- out from SGMII
  signal tx_reset_out, rx_reset_out : std_logic := '0';  -- out from MAC

  --- locked
  signal mmcm_locked : std_logic;

  -- data
  signal gmii_txd, gmii_rxd                             : std_logic_vector(7 downto 0);
  signal gmii_tx_en, gmii_tx_er, gmii_rx_dv, gmii_rx_er : std_logic;

  -- sgmii controls and status
  signal an_restart          : std_logic := '0';
  signal an_config_val       : std_logic := '1';
  signal configuration_valid : std_logic := '1';
  signal an_interrupt        : std_logic;

  signal an_config_vector : std_logic_vector (15 downto 0) := (others => '0');

  signal sgmii_status_vector : std_logic_vector(15 downto 0);

  signal mac_tx_reset : std_logic;
  signal mac_rx_reset : std_logic;

begin

  link_up <= sgmii_status_vector(1);

  phy_interrupt <= not an_interrupt;

  clkdiv : entity work.ipbus_clock_div
    port map(
      clk => clk125_fr,
      d7  => clk2mhz,
      d28 => onehz
      );

  --phy_mdc <= clk2mhz;

  process(clk125_fr)
  begin
    if rising_edge(clk125_fr) then      -- ff's with CE
      onehz_d <= onehz;
    end if;
  end process;
  onehz_re <= '1' when (onehz = '1' and onehz_d = '0') else '0';

  resetter_proc : process (clk125_fr) is
    constant MAX     : integer                := 10;
    variable seconds : integer range 0 to MAX := 0;
  begin
    if (rising_edge(clk125_fr)) then

      phy_resetb <= not (phy_reset);

      if (rst = '1') then

        seconds := 0;

        phy_reset        <= '1';
        mac_reset        <= '1';
        an_config_val    <= '1';
        an_restart       <= '0';
        phy_cfg_not_done <= '1';

      else

        if (onehz_re = '1' and seconds < MAX) then
          seconds := seconds + 1;
        end if;

        if (seconds = 2) then
          phy_reset <= '0';
        end if;

        if (seconds = 3) then
          mac_reset <= '0';
        end if;

        if (seconds = 4) then
          phy_cfg_not_done <= '0';
        end if;

      end if;

    end if;
  end process;

  -- Reset to temac clients (outgoing)
  sgmii_resetter_proc : process (clk125_sgmii) is
  begin
    if (rising_edge(clk125_sgmii)) then
      rst_o        <= tx_reset_out or rx_reset_out;
      mac_rx_reset <= mac_reset or rst125_sgmii;
      mac_tx_reset <= mac_reset or rst125_sgmii;
    end if;
  end process;

  clk125_eth <= clk125_sgmii;

  mdio_io_iobuf : IOBUF
    port map (
      IO => phy_mdio,
      I  => mdio_o,
      O  => mdio_i,
      T  => mdio_t
      );

  an_config_vector <= (0      => '1',   -- [0] 1 = SGMII
                                        -- [4:1] Reserved
                                        -- [5] Reserved
                                        -- [6] Reserved
                                        -- [8:7] Reserved
                                        -- [9] Reserved
                       10     => '0',   --
                       11     => '1',   -- [11:10]="10" ==> 1000 Mb/s
                       12     => '1',   -- 1 = full duplex, 0 = half-duplex
                       13     => '0',   -- reserved
                       14     => '1',   -- acknowledge
                       15     => '1',   -- 1 = link up, 0 = link down
                       others => '0'
                       );

  -- Figure 3-58
  -- https://github.com/alexforencich/verilog-ethernet/blob/master/example/KC705/fpga_sgmii/rtl/fpga.v
  sgmii : gig_eth_pcs_pma_gmii_to_sgmii_bridge
    port map (
      txp => sgmii_txp,
      txn => sgmii_txn,
      rxp => sgmii_rxp,
      rxn => sgmii_rxn,

      refclk625_p => sgmii_clk_p,
      refclk625_n => sgmii_clk_n,

      mmcm_locked_out => mmcm_locked,

      sgmii_clk_r  => open,
      sgmii_clk_f  => open,
      sgmii_clk_en => clk_en,

      rst_125_out => rst125_sgmii,
      clk312_out  => open,
      clk125_out  => clk125_sgmii,
      clk625_out  => open,

      gmii_txd     => gmii_txd,
      gmii_tx_en   => gmii_tx_en,
      gmii_tx_er   => gmii_tx_er,
      gmii_rxd     => gmii_rxd,
      gmii_rx_dv   => gmii_rx_dv,
      gmii_rx_er   => gmii_rx_er,
      gmii_isolate => open,

      mdc                 => clk2mhz,   -- in
      mdio_i              => '1',       -- in
      mdio_o              => open,      -- out
      mdio_t              => open,      -- out
      ext_mdc             => phy_mdc,   -- out
      ext_mdio_i          => mdio_i,    -- in
      ext_mdio_o          => mdio_o,    -- out
      ext_mdio_t          => mdio_t,    -- out
      phyaddr             => "00111",
      configuration_valid => '1',  -- For triggering a fresh update of Register 0 through configuration_vector, this signal should be deasserted and then reasserted
      an_adv_config_val   => '0',  -- For triggering a fresh update of Register 4 through an_adv_config_vector, this signal should be deasserted and then reasserted
      an_restart_config   => '0',  -- The rising edge of this signal is the enable signal to overwrite Bit 9 or Register 0. For triggering a fresh AN Start, this signal should be deasserted and then reasserted

      -- Configuration
      configuration_vector => (
        -- 0 = unidirectional enable, set to 0
        -- 1 = loopback control, 1 = loopback
        -- 2 = powerdown transceiver (not used in lvds)
        3                  => phy_cfg_not_done,  -- isolate
        4                  => '1',               -- auto negotiation enabled
        others             => '0'),

      -- Auto Negotiation
      an_interrupt         => an_interrupt,
      an_adv_config_vector => an_config_vector,

      speed_is_10_100 => '0',           -- 0 for 1 Gb/s
      speed_is_100    => '0',           -- 0 for 1 Gb/s

      status_vector => sgmii_status_vector,

      reset => phy_cfg_not_done,  -- hold the bridge in reset until PHY is up and happy

      signal_detect  => '1',  -- Signal must be tied to logic 1 (if not connected to an optical module).
      idelay_rdy_out => open
      );

  locked       <= mmcm_locked;
  tx_reset_out <= mac_tx_reset;
  rx_reset_out <= mac_rx_reset;

  -- https://github.com/alexforencich/verilog-ethernet/blob/master/example/KC705/fpga_sgmii/rtl/fpga_core.v
  eth_mac_1g_inst : eth_mac_1g_fifo
    port map (

      rx_clk => clk125_sgmii,           -- in
      tx_clk => clk125_sgmii,           -- in
      rx_rst => mac_rx_reset,           -- in
      tx_rst => mac_tx_reset,           -- in

      logic_clk => logic_clk,
      logic_rst => logic_rst,

      tx_axis_tdata    => tx_data,
      tx_axis_tvalid   => tx_valid,
      tx_axis_tready   => tx_ready,
      tx_axis_tlast    => tx_last,
      tx_axis_tuser(0) => tx_error,
      tx_axis_tkeep(0) => '0',

      rx_axis_tdata    => rx_data,
      rx_axis_tvalid   => rx_valid,
      rx_axis_tready   => '1',
      rx_axis_tlast    => rx_last,
      rx_axis_tuser(0) => rx_error,
      rx_axis_tkeep(0) => open,

      gmii_rxd   => gmii_rxd,
      gmii_rx_dv => gmii_rx_dv,
      gmii_rx_er => gmii_rx_er,
      gmii_txd   => gmii_txd,
      gmii_tx_en => gmii_tx_en,
      gmii_tx_er => gmii_tx_er,

      rx_clk_enable => '1',
      tx_clk_enable => '1',

      rx_mii_select => '0',
      tx_mii_select => '0',

      tx_error_underflow => open,
      tx_fifo_overflow   => open,
      tx_fifo_bad_frame  => open,
      tx_fifo_good_frame => open,
      rx_error_bad_frame => open,
      rx_error_bad_fcs   => open,
      rx_fifo_overflow   => open,
      rx_fifo_bad_frame  => open,
      rx_fifo_good_frame => open,

      ifg_delay => std_logic_vector(to_unsigned(12, 8))
      );

end rtl;
