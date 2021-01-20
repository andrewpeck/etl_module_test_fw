-- based on https://github.com/ipbus/ipbus-firmware/blob/master/components/ipbus_eth/firmware/hdl/eth_us_1000basex.vhd
-- taken at commit e9d7ddbb8ab196fe0974213bd1feb30514619123

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


-- Contains the instantiation of the Xilinx MAC & 1000baseX pcs/pma & GTP transceiver cores
--
-- Do not change signal names in here without corresponding alteration to the timing contraints file
--
-- Dave Newbold, October 2016
--
-- https://forums.xilinx.com/t5/Ethernet/1G-2-5G-Ethernet-PCS-PMA-or-SGMII-auto-negotiation-issue/td-p/696244


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity eth_sgmii_lvds is
  generic(
    C_DEBUG : boolean := false
    );
  port(
    -- clock and data i/o (connected to external device)
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
    debug_leds    : out   std_logic_vector(7 downto 0);
    dip_sw        : in    std_logic_vector(3 downto 0);
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

  --- this is the MAC ---
  component temac_gbe_v9_0
    port (
      gtx_clk                 : in  std_logic;
      --clk_enable              : in  std_logic;
      glbl_rstn               : in  std_logic;
      rx_axi_rstn             : in  std_logic;
      tx_axi_rstn             : in  std_logic;
      rx_statistics_vector    : out std_logic_vector(27 downto 0);
      rx_statistics_valid     : out std_logic;
      rx_mac_aclk             : out std_logic;
      rx_reset                : out std_logic;
      rx_axis_mac_tdata       : out std_logic_vector(7 downto 0);
      rx_axis_mac_tvalid      : out std_logic;
      rx_axis_mac_tlast       : out std_logic;
      rx_axis_mac_tuser       : out std_logic;
      tx_ifg_delay            : in  std_logic_vector(7 downto 0);
      tx_statistics_vector    : out std_logic_vector(31 downto 0);
      tx_statistics_valid     : out std_logic;
      tx_mac_aclk             : out std_logic;
      tx_reset                : out std_logic;
      tx_axis_mac_tdata       : in  std_logic_vector(7 downto 0);
      tx_axis_mac_tvalid      : in  std_logic;
      tx_axis_mac_tlast       : in  std_logic;
      tx_axis_mac_tuser       : in  std_logic_vector(0 downto 0);
      tx_axis_mac_tready      : out std_logic;
      pause_req               : in  std_logic;
      pause_val               : in  std_logic_vector(15 downto 0);
      speedis100              : out std_logic;
      speedis10100            : out std_logic;
      gmii_txd                : out std_logic_vector(7 downto 0);
      gmii_tx_en              : out std_logic;
      gmii_tx_er              : out std_logic;
      gmii_rxd                : in  std_logic_vector(7 downto 0);
      gmii_rx_dv              : in  std_logic;
      gmii_rx_er              : in  std_logic;
      rx_configuration_vector : in  std_logic_vector(79 downto 0);
      tx_configuration_vector : in  std_logic_vector(79 downto 0)
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

  -- vio signals
  signal vio_global_reset               : std_logic := '0';
  signal vio_phy_reset                  : std_logic := '0';
  signal vio_sgmii_reset, vio_mac_reset : std_logic := '0';
  signal phy_reset, mac_reset           : std_logic := '1';
  signal phy_cfg_not_done               : std_logic := '1';

  signal clk_en : std_logic;


  signal mdio_i, mdio_o, mdio_t : std_logic;

  --- clocks
  signal clk125_sgmii, clk2mhz      : std_logic;
  --- slow clocks and edges
  signal onehz, onehz_d, onehz_re   : std_logic := '0';  -- slow generated clocks
  --- resets
  signal rst125_sgmii               : std_logic;         -- out from SGMII
  signal tx_reset_out, rx_reset_out : std_logic;         -- out from MAC

  --- locked
  signal mmcm_locked : std_logic;

  -- data
  signal gmii_txd, gmii_rxd                             : std_logic_vector(7 downto 0);
  signal gmii_tx_en, gmii_tx_er, gmii_rx_dv, gmii_rx_er : std_logic;

  -- sgmii controls and status
  signal an_restart, vio_an_restart       : std_logic := '0';
  signal an_config_val, vio_an_config_val : std_logic := '0';
  signal an_interrupt                     : std_logic;

  signal an_config_vector : std_logic_vector (15 downto 0) := (others => '0');

  signal sgmii_status_vector : std_logic_vector(15 downto 0);


begin

  link_up <= sgmii_status_vector(1);

  phy_interrupt <= not an_interrupt;

  clkdiv : entity work.ipbus_clock_div
    port map(
      clk => clk125_fr,
      d7  => clk2mhz,
      d28 => onehz
      );

  phy_mdc <= clk2mhz;

  process(clk125_fr)
  begin
    if rising_edge(clk125_fr) then      -- ff's with CE
      onehz_d <= onehz;
    end if;
  end process;
  onehz_re <= '1' when (onehz = '1' and onehz_d = '0') else '0';

  phy_resetb <= not (phy_reset or vio_phy_reset);

  resetter_proc : process (clk125_fr) is
    constant MAX     : integer                := 10;
    variable seconds : integer range 0 to MAX := 0;
  begin
    if (rising_edge(clk125_fr)) then

      if (rst = '1' or vio_global_reset = '1') then

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
            an_config_val <= '0';
          else
            an_config_val <= '1';
          end if;

          if (seconds = 6) then
            an_restart <= '1';
          else
            an_restart <= '0';
          end if;

          if (seconds = 6) then
            phy_cfg_not_done <= '0';
          end if;


      end if;

    end if;
  end process;

  -- Reset to temac clients (outgoing)
  rst_o <= tx_reset_out or rx_reset_out;

  clk125_eth <= clk125_sgmii;

  mac : temac_gbe_v9_0
    port map(
      gtx_clk              => clk125_sgmii,
      --clk_enable              => clk_en,
      glbl_rstn            => not (mac_reset or vio_mac_reset),
      rx_axi_rstn          => not rst125_sgmii,
      tx_axi_rstn          => not rst125_sgmii,
      rx_statistics_vector => open,
      rx_statistics_valid  => open,
      rx_mac_aclk          => open,

      rx_reset           => rx_reset_out,
      rx_axis_mac_tdata  => rx_data,
      rx_axis_mac_tvalid => rx_valid,
      rx_axis_mac_tlast  => rx_last,
      rx_axis_mac_tuser  => rx_error,

      tx_ifg_delay         => X"00",
      tx_statistics_vector => open,
      tx_statistics_valid  => open,
      tx_mac_aclk          => open,

      tx_reset             => tx_reset_out,  -- Out: Active-High TX software reset from Ethernet MAC core level
      tx_axis_mac_tdata    => tx_data,  --  In: Frame data to be transmitted
      tx_axis_mac_tvalid   => tx_valid,  -- In: Control signal for tx_axis_mac_tdata port. Indicates the data is valid.
      tx_axis_mac_tlast    => tx_last,  --  In:Control signal for tx_axis_mac_tdataport. Indicates the final transfer in a frame
      tx_axis_mac_tuser(0) => tx_error,  -- In: Control signal for tx_axis_mac_tdataport. Indicates an error condition, such as FIFO underrun, in the frame allowing the MAC to send an error to the PH
      tx_axis_mac_tready   => tx_ready,  -- Out Handshaking signal. Asserted when the current data on tx_axis_mac_tdata has been accepted and tx_axis_mac_tvalid is High. At 10/100 Mb/s this is used to meter the data into the core at the correct rate.

      pause_req => '0',
      pause_val => X"0000",

      speedis10100 => speedis10100,
      speedis100   => speedis100,

      gmii_txd                => gmii_txd,    -- out
      gmii_tx_en              => gmii_tx_en,  -- out
      gmii_tx_er              => gmii_tx_er,  -- out
      gmii_rxd                => gmii_rxd,    -- in
      gmii_rx_dv              => gmii_rx_dv,  -- in
      gmii_rx_er              => gmii_rx_er,  -- in
      rx_configuration_vector => X"0000_0000_0000_0000_0812",
      tx_configuration_vector => X"0000_0000_0000_0000_0012"
      );


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

  -- https://www.xilinx.com/support/documentation/ip_documentation/gig_ethernet_pcs_pma/v16_0/pg047-gig-eth-pcs-pma.pdf
  -- Figure 3-58
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

      mdc                 => clk2mhz,
      mdio_i              => mdio_i,
      mdio_o              => mdio_o,
      mdio_t              => mdio_t,
      ext_mdc             => open,
      ext_mdio_i          => '1',
      ext_mdio_o          => open,
      ext_mdio_t          => open,
      phyaddr             => "00111",
      configuration_valid => '1',

      an_adv_config_val => an_config_val and vio_an_config_val,  -- For triggering a fresh update of Register 4 through an_adv_config_vector, this signal should be deasserted and then reasserted
      an_restart_config => an_restart or vio_an_restart,  -- The rising edge of this signal is the enable signal to overwrite Bit 9 or Register 0. For triggering a fresh AN Start, this signal should be deasserted and then reasserted

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

      speed_is_10_100 => speedis10100,  -- 0 for 1 Gb/s
      speed_is_100    => speedis100,    -- 0 for 1 Gb/s

      status_vector => sgmii_status_vector,

      reset => vio_sgmii_reset or phy_cfg_not_done,  -- hold the bridge in reset until PHY is up and happy

      signal_detect  => '1',            -- Signal must be tied to logic 1 (if not connected to an optical module).
      idelay_rdy_out => open
      );

  locked <= mmcm_locked;

  debugilas : if (C_DEBUG) generate
    component vio_sgmii
      port (
        clk        : in  std_logic;
        probe_out0 : out std_logic_vector(0 downto 0);
        probe_out1 : out std_logic_vector(0 downto 0);
        probe_out2 : out std_logic_vector(0 downto 0);
        probe_out3 : out std_logic_vector(0 downto 0);
        probe_out4 : out std_logic_vector(0 downto 0);
        probe_out5 : out std_logic_vector(0 downto 0)
        );
    end component;

    component ila_sgmii
      port (
        clk     : in std_logic;
        probe0  : in std_logic_vector(0 downto 0);
        probe1  : in std_logic_vector(0 downto 0);
        probe2  : in std_logic_vector(0 downto 0);
        probe3  : in std_logic_vector(7 downto 0);
        probe4  : in std_logic_vector(7 downto 0);
        probe5  : in std_logic_vector(0 downto 0);
        probe6  : in std_logic_vector(0 downto 0);
        probe7  : in std_logic_vector(0 downto 0);
        probe8  : in std_logic_vector(0 downto 0);
        probe9  : in std_logic_vector(0 downto 0);
        probe10 : in std_logic_vector(0 downto 0);
        probe11 : in std_logic_vector(15 downto 0);
        probe12 : in std_logic_vector(0 downto 0);
        probe13 : in std_logic_vector(0 downto 0);
        probe14 : in std_logic_vector(0 downto 0);
        probe15 : in std_logic_vector(0 downto 0);
        probe16 : in std_logic_vector(0 downto 0);
        probe17 : in std_logic_vector(0 downto 0);
        probe18 : in std_logic_vector(0 downto 0);
        probe19 : in std_logic_vector(0 downto 0);
        probe20 : in std_logic_vector(0 downto 0);
        probe21 : in std_logic_vector(0 downto 0);
        probe22 : in std_logic_vector(0 downto 0);
        probe23 : in std_logic_vector(0 downto 0);
        probe24 : in std_logic_vector(0 downto 0);
        probe25 : in std_logic_vector(0 downto 0);
        probe26 : in std_logic_vector(0 downto 0);
        probe27 : in std_logic_vector(0 downto 0);
        probe28 : in std_logic_vector(7 downto 0);
        probe29 : in std_logic_vector(7 downto 0)
        );
    end component;

  begin

    vio_sgmii_1 : vio_sgmii
      port map (
        clk           => clk125_fr,
        probe_out0(0) => vio_an_restart,
        probe_out1(0) => vio_an_config_val,
        probe_out2(0) => vio_phy_reset,
        probe_out3(0) => vio_sgmii_reset,
        probe_out4(0) => vio_mac_reset,
        probe_out5(0) => vio_global_reset
        );

    ila_sgmii_inst : ila_sgmii
      port map (
        clk        => clk125_fr,
        probe0(0)  => mmcm_locked,
        probe1(0)  => not clk125_sgmii,
        probe2(0)  => clk_en,
        probe3     => gmii_txd(7 downto 0),
        probe4     => gmii_rxd(7 downto 0),
        probe5(0)  => gmii_tx_en,
        probe6(0)  => gmii_tx_er,
        probe7(0)  => gmii_rx_dv,
        probe8(0)  => gmii_rx_er,
        probe9(0)  => '1',
        probe10(0) => rst125_sgmii,
        probe11    => sgmii_status_vector (15 downto 0),
        probe12(0) => phy_cfg_not_done,
        probe13(0) => speedis100,
        probe14(0) => speedis10100,
        probe15(0) => '1',
        probe16(0) => '1',
        probe17(0) => tx_reset_out,
        probe18(0) => rx_reset_out,
        probe19(0) => '1',
        probe20(0) => '1',
        probe21(0) => mdio_i,
        probe22(0) => mdio_o,
        probe23(0) => mdio_t,
        probe24(0) => clk125_sgmii,
        probe25(0) => rst,
        probe26(0) => onehz,
        probe27(0) => onehz_re,
        probe28    => rx_data,
        probe29    => tx_data
        );
  end generate;

end rtl;
