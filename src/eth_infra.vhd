library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_trans_decl.all;

library unisim;
use unisim.vcomponents.all;

entity eth_infra is
  port (

    reset : in std_logic;
    clock : in std_logic;

    osc_clk_125 : in std_logic;
    clk125_o    : out std_logic;

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

    mac_addr : in std_logic_vector(47 downto 0);  -- MAC address
    ip_addr  : in std_logic_vector(31 downto 0);  -- IP address

    -- IPbus (from / to slaves)
    ipb_in  : in  ipb_rbus;
    ipb_out : out ipb_wbus
    );
end eth_infra;


architecture rtl of eth_infra is

  signal reset_ipb : std_logic := '0';

  signal reset_from_phy : std_logic := '0';

  signal clk_eth : std_logic;

  signal eth_locked : std_logic;

  -- ipbus to ethernet
  signal tx_data, rx_data : std_logic_vector(7 downto 0);

  signal tx_valid, tx_last, tx_error, tx_ready, rx_valid, rx_last, rx_error : std_logic;

  signal pkt       : std_logic;
  signal trans_in  : ipbus_trans_in;
  signal trans_out : ipbus_trans_out;

begin

  process (clock, reset_from_phy, reset) is
  begin
    if (reset_from_phy = '1' or reset = '1') then
      reset_ipb <= '1';
    elsif (rising_edge(clock)) then
      reset_ipb <= '0';
    end if;
  end process;

  eth : entity work.eth_sgmii_lvds
    port map(
      clk125_fr  => osc_clk_125,        -- free running 125 MHz clk
      rst        => reset,              -- reset in
      rst_o      => reset_from_phy,     -- reset out
      locked     => eth_locked,         -- status
      clk125_eth => clk125_o,           -- eth clock out

      logic_clk => clock,
      logic_rst => reset,

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

      mac_clk    => clock,
      rst_macclk => reset_ipb,
      ipb_clk    => clock,
      rst_ipb    => reset_ipb,

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

end rtl;
