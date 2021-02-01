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


-- Infrastructural firmware for the Xilinx KCU105 board; includes clock configuration, PCIe interface, IPbus transactor & master.
--
-- Tom Williams, July 2018
--
-- Modified for KCU105 by ap


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_trans_decl.all;

library UNISIM;
use UNISIM.VComponents.all;


entity eth_infra is
  generic(
    C_DEBUG : boolean := false
    );
  port (
    -- External oscillators
    osc_clk_300   : in    std_logic;
    osc_clk_125   : in    std_logic;
    -- status LEDs
    rst_in        : in    std_logic_vector(4 downto 0);  -- external reset button
    dip_sw        : in    std_logic_vector(3 downto 0);
    -- SGMII clk and data
    sgmii_clk_p   : in    std_logic;
    sgmii_clk_n   : in    std_logic;
    sgmii_txp     : out   std_logic;
    sgmii_txn     : out   std_logic;
    sgmii_rxp     : in    std_logic;
    sgmii_rxn     : in    std_logic;
    phy_resetb    : out   std_logic;
    phy_mdio      : inout std_logic;
    phy_mdc       : out   std_logic;
    phy_interrupt : out   std_logic;
    -- IPbus clock and reset
    clk_ipb_o     : out   std_logic;
    rst_ipb_o     : out   std_logic;
    clk_aux_o     : out   std_logic;                     -- 40MHz generated clock
    rst_aux_o     : out   std_logic;
    -- The signals of doom and lesser doom
    nuke          : in    std_logic;
    soft_rst      : in    std_logic;

    mac_addr : in  std_logic_vector(47 downto 0);  -- MAC address
    ip_addr  : in  std_logic_vector(31 downto 0);  -- IP address
    -- IPbus (from / to slaves)
    ipb_in   : in  ipb_rbus;
    ipb_out  : out ipb_wbus
    );
end eth_infra;


architecture rtl of eth_infra is

  signal clk_eth, clk_ipb_i, clk_aux, clk_200                                                    : std_logic;
  signal locked, clk_locked, eth_locked, rst_ipb, rst_aux, rst_ipb_ctrl, rst_phy, rst_eth, onehz : std_logic;

  -- ipbus to ethernet
  signal tx_data, rx_data : std_logic_vector(7 downto 0);

  signal tx_valid, tx_last, tx_error, tx_ready, rx_valid, rx_last, rx_error : std_logic;

  signal pkt       : std_logic;
  signal trans_in  : ipbus_trans_in;
  signal trans_out : ipbus_trans_out;

begin


  --  DCM clock generation for internal bus, ethernet
  clocks : entity work.eth_clocks
    generic map (
      CLK_FR_FREQ => 300.0
      )
    port map (
      clki_fr       => osc_clk_300,
      clki_125      => clk_eth,
      clko_ipb      => clk_ipb_i,
      clko_aux      => clk_aux,
      clko_200      => clk_200,
      eth_locked    => eth_locked,
      locked        => clk_locked,
      nuke          => nuke,
      soft_rst      => soft_rst,
      rsto_125      => open,
      rsto_ipb      => rst_ipb,
      rsto_aux      => rst_aux,
      rsto_eth      => rst_phy,
      rsto_ipb_ctrl => rst_ipb_ctrl,
      onehz         => onehz
      );

  clk_ipb_o <= clk_ipb_i;
  rst_ipb_o <= rst_ipb;
  clk_aux_o <= clk_aux;
  rst_aux_o <= rst_aux;
  locked    <= clk_locked and eth_locked;

  eth : entity work.eth_sgmii_lvds
    port map(
      clk125_fr  => osc_clk_125,        -- free running 125 MHz clk
      rst        => rst_phy,            -- reset in
      rst_o      => rst_eth,            -- reset out
      locked     => eth_locked,         -- status
      clk125_eth => clk_eth,            -- eth clock out

      -- mac tx
      tx_data  => tx_data,
      tx_valid => tx_valid,
      tx_last  => tx_last,
      tx_error => tx_error,
      tx_ready => tx_ready,

      -- mac rx
      rx_data  => rx_data,
      rx_valid => rx_valid,
      rx_last  => rx_last,
      rx_error => rx_error,

      -- eth external ports (go to top level ports)
      sgmii_clk_p   => sgmii_clk_p,
      sgmii_clk_n   => sgmii_clk_n,
      sgmii_txp     => sgmii_txp,
      sgmii_txn     => sgmii_txn,
      sgmii_rxp     => sgmii_rxp,
      sgmii_rxn     => sgmii_rxn,
      phy_resetb    => phy_resetb,
      phy_mdio      => phy_mdio,
      phy_interrupt => phy_interrupt,
      phy_mdc       => phy_mdc
      );

  ipbus : entity work.ipbus_ctrl
    port map(
      mac_clk      => clk_eth,
      rst_macclk   => rst_eth,
      ipb_clk      => clk_ipb_i,
      rst_ipb      => rst_ipb_ctrl,
      mac_rx_data  => rx_data,
      mac_rx_valid => rx_valid,
      mac_rx_last  => rx_last,
      mac_rx_error => rx_error,
      mac_tx_data  => tx_data,
      mac_tx_valid => tx_valid,
      mac_tx_last  => tx_last,
      mac_tx_error => tx_error,
      mac_tx_ready => tx_ready,
      ipb_out      => ipb_out,
      ipb_in       => ipb_in,
      mac_addr     => mac_addr,
      ip_addr      => ip_addr,
      pkt          => pkt
      );


  debugilas : if (C_DEBUG) generate

    component ila_ipb
      port (
        clk    : in std_logic;
        probe0 : in std_logic_vector(31 downto 0);
        probe1 : in std_logic_vector(31 downto 0);
        probe2 : in std_logic_vector(0 downto 0);
        probe3 : in std_logic_vector(0 downto 0);
        probe4 : in std_logic_vector(31 downto 0);
        probe5 : in std_logic_vector(0 downto 0);
        probe6 : in std_logic_vector(0 downto 0)
        );
    end component;

    component ila_eth_infra
      port (
        clk     : in std_logic;
        probe0  : in std_logic_vector(7 downto 0);
        probe1  : in std_logic_vector(7 downto 0);
        probe2  : in std_logic_vector(0 downto 0);
        probe3  : in std_logic_vector(0 downto 0);
        probe4  : in std_logic_vector(0 downto 0);
        probe5  : in std_logic_vector(0 downto 0);
        probe6  : in std_logic_vector(0 downto 0);
        probe7  : in std_logic_vector(0 downto 0);
        probe8  : in std_logic_vector(0 downto 0);
        probe9  : in std_logic_vector(0 downto 0);
        probe10 : in std_logic_vector(0 downto 0);
        probe11 : in std_logic_vector(0 downto 0);
        probe12 : in std_logic_vector(0 downto 0);
        probe13 : in std_logic_vector(0 downto 0)
        );
    end component;

  begin

    -- ila_ipb_master_inst : ila_ipb
    --   port map (
    --     clk       => clk_ipb_i,
    --     probe0    => ipb_out.ipb_addr,
    --     probe1    => ipb_out.ipb_wdata,
    --     probe2(0) => ipb_out.ipb_strobe,
    --     probe3(0) => ipb_out.ipb_write,
    --     probe4    => ipb_in.ipb_rdata,
    --     probe5(0) => ipb_in.ipb_ack,
    --     probe6(0) => ipb_in.ipb_err
    --     );

    ila_eth_infra_inst : ila_eth_infra
      port map (
        clk        => clk_eth,
        probe0     => tx_data,
        probe1     => rx_data,
        probe2(0)  => tx_valid,
        probe3(0)  => tx_last,
        probe4(0)  => tx_error,
        probe5(0)  => tx_ready,
        probe6(0)  => rx_valid,
        probe7(0)  => rx_last,
        probe8(0)  => rx_error,
        probe9(0)  => clk_eth,
        probe10(0) => eth_locked,
        probe11(0) => locked,
        probe12(0) => '1',
        probe13(0) => rst_eth
        );
  end generate;

end rtl;
