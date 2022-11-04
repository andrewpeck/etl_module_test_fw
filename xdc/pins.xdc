#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-2 [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
#
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

# PCIe connections
set_property PACKAGE_PIN AB6 [get_ports pcie_sys_clk_p];
create_clock -period 10.000 -name pcie_sys_clk [get_ports pcie_sys_clk_p]

#set_property PULLUP true [get_ports pcie_sys_rst_n]
set_property PACKAGE_PIN K22 [get_ports pcie_sys_rst];
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]

set_property PACKAGE_PIN AB2 [get_ports {pcie_rx_p[0]}] ;
#set_property PACKAGE_PIN AD2 [get_ports {pcie_rx_p[1]}] ;
#set_property PACKAGE_PIN AF2 [get_ports {pcie_rx_p[2]}] ;
#set_property PACKAGE_PIN AH2 [get_ports {pcie_rx_p[3]}] ;
#set_property PACKAGE_PIN AJ3 [get_ports {pcie_rx_p[4]}] ;
#set_property PACKAGE_PIN AK2 [get_ports {pcie_rx_p[5]}] ;
#set_property PACKAGE_PIN AM2 [get_ports {pcie_rx_p[6]}] ;
#set_property PACKAGE_PIN AP2 [get_ports {pcie_rx_p[7]}] ;

set_property PACKAGE_PIN AC4 [get_ports {pcie_tx_p[0]}] ;
#set_property PACKAGE_PIN AE4 [get_ports {pcie_tx_p[1]}] ;
#set_property PACKAGE_PIN AG4 [get_ports {pcie_tx_p[2]}] ;
#set_property PACKAGE_PIN AH6 [get_ports {pcie_tx_p[3]}] ;
#set_property PACKAGE_PIN AJ4 [get_ports {pcie_tx_p[4]}] ;
#set_property PACKAGE_PIN AL4 [get_ports {pcie_tx_p[5]}] ;
#set_property PACKAGE_PIN AM6 [get_ports {pcie_tx_p[6]}] ;
#set_property PACKAGE_PIN AN4 [get_ports {pcie_tx_p[7]}] ;

# EXTERNAL OSCILLATOR:

# 300 MHz external oscillator
create_clock -period 3.333 -name osc_clk300 [get_ports osc_clk300_p]
set_property IOSTANDARD LVDS [get_ports osc_clk300_p]  ;
set_property PACKAGE_PIN AK17 [get_ports osc_clk300_p] ; # updated
set_property PACKAGE_PIN AK16 [get_ports osc_clk300_n] ; # updated

create_clock -period 8.0 -name osc_clk125 [get_ports osc_clk125_p]
set_property IOSTANDARD LVDS [get_ports osc_clk125_p]  ;
set_property PACKAGE_PIN G10 [get_ports osc_clk125_p] ; # 125mhz
set_property PACKAGE_PIN F10 [get_ports osc_clk125_n] ; # 125mhz

set_property PACKAGE_PIN V6 [get_ports {sma_refclk_p}]; # bank 226 REFCLK0
set_property PACKAGE_PIN V5 [get_ports {sma_refclk_n}]; # bank 226 REFCLK0

set_property PACKAGE_PIN F12 [get_ports si570_clk_sel_ls]
set_property IOSTANDARD LVCMOS18 [get_ports si570_clk_sel_ls]

set_property PACKAGE_PIN AL8 [get_ports sfp0_tx_disable]
set_property IOSTANDARD LVCMOS18 [get_ports sfp0_tx_disable]
set_property PACKAGE_PIN D28 [get_ports sfp1_tx_disable]
set_property IOSTANDARD LVCMOS18 [get_ports sfp1_tx_disable]

set ibuf_cell [get_cells -quiet -hierarchical -filter "BEL =~ *GTE3*"]
set_property LOC {}  $ibuf_cell

# set gt_cell [get_cells -quiet -hierarchical -filter "NAME =~ *CHANNEL_PRIM_INST"]
# set_property LOC {}  $gt_cell
#
# # bank 226
set_property PACKAGE_PIN U4 [get_ports {tx_p[0]}]; # bank 226 -- X0Y10 -- GTH1
# set_property PACKAGE_PIN U3 [get_ports {tx_n[0]}]; # bank 226 -- X0Y10 -- GTH1
set_property PACKAGE_PIN W4 [get_ports {tx_p[1]}]; # bank 226 -- X0Y9 -- GTH0

set_property PACKAGE_PIN T2 [get_ports {rx_p[0]}]; # bank 226 -- X0Y10 -- GTH1
# set_property PACKAGE_PIN T1 [get_ports {rx_n[0]}]; # bank 226 -- X0Y10 -- GTH1
set_property PACKAGE_PIN V2 [get_ports {rx_p[1]}]; # bank 226 -- X0Y9 -- GTH0
#
# bank 227
# pin assignments from ug917-kcu105-eval-bd.pdf
set_property PACKAGE_PIN F6 [get_ports {tx_p[2]}]; # bank 228 HPC_DP0_C2M_P -- X0Y17 -- GTH 6
set_property PACKAGE_PIN D6 [get_ports {tx_p[3]}]; # bank 228 HPC_DP1_C2M_P -- X0Y18 -- GTH 7
set_property PACKAGE_PIN C4 [get_ports {tx_p[4]}]; # bank 228 HPC_DP2_C2M_P
set_property PACKAGE_PIN B6 [get_ports {tx_p[5]}]; # bank 228 HPC_DP3_C2M_P
set_property PACKAGE_PIN N4 [get_ports {tx_p[6]}]; # bank 227 HPC_DP4_C2M_P -- XOY13 -- GTH 3
set_property PACKAGE_PIN L4 [get_ports {tx_p[8]}]; # bank 227 HPC_DP6_C2M_P
set_property PACKAGE_PIN J4 [get_ports {tx_p[7]}]; # bank 227 HPC_DP5_C2M_P -- X0Y14 -- GTH 4
set_property PACKAGE_PIN G4 [get_ports {tx_p[9]}]; # bank 227 HPC_DP7_C2M_P -- X0Y16 -- GTH 5

set_property PACKAGE_PIN E4 [get_ports {rx_p[2]}]; # bank 228 HPC_DP0_M2C_P -- X0Y17 -- GTH 6
set_property PACKAGE_PIN D2 [get_ports {rx_p[3]}]; # bank 228 HPC_DP1_M2C_P -- X0Y18 -- GTH 7
set_property PACKAGE_PIN B2 [get_ports {rx_p[4]}]; # bank 228 HPC_DP2_M2C_P
set_property PACKAGE_PIN A4 [get_ports {rx_p[5]}]; # bank 228 HPC_DP3_M2C_P
set_property PACKAGE_PIN M2 [get_ports {rx_p[6]}]; # bank 227 HPC_DP4_M2C_P -- XOY13 -- GTH 3
set_property PACKAGE_PIN K2 [get_ports {rx_p[8]}]; # bank 227 HPC_DP6_M2C_P
set_property PACKAGE_PIN H2 [get_ports {rx_p[7]}]; # bank 227 HPC_DP5_M2C_P -- X0Y14 -- GTH 4
set_property PACKAGE_PIN F2 [get_ports {rx_p[9]}]; # bank 227 HPC_DP7_M2C_P -- X0Y16 -- GTH 5

# set_property IOSTANDARD SUB_LVDS [get_ports si570_usrclk*]  ;
# set_property PACKAGE_PIN M25 [get_ports {si570_usrclk_p}];
# set_property PACKAGE_PIN M26 [get_ports {si570_usrclk_n}];

# refclks
set_property PACKAGE_PIN P6 [get_ports {si570_refclk_p}]; # bank 227 REFCLK0 QUADX0Y3
set_property PACKAGE_PIN P5 [get_ports {si570_refclk_n}]; # bank 227 REFCLK0 QUADX0Y3
create_clock -period 3.1189 -name si570refclk [get_ports si570_refclk_p]

set_property PACKAGE_PIN AP8 [get_ports {leds[0]}];
set_property PACKAGE_PIN H23 [get_ports {leds[1]}];
set_property PACKAGE_PIN P20 [get_ports {leds[2]}];
set_property PACKAGE_PIN P21 [get_ports {leds[3]}];
set_property PACKAGE_PIN N22 [get_ports {leds[4]}];
set_property PACKAGE_PIN M22 [get_ports {leds[5]}];
set_property PACKAGE_PIN R23 [get_ports {leds[6]}];
set_property PACKAGE_PIN P23 [get_ports {leds[7]}];
set_property IOSTANDARD LVCMOS18 [get_ports {leds*}]

set_property IOSTANDARD SUB_LVDS [get_ports {sgmii_*}]
create_clock -period 1.55 -name ethclk [get_ports sgmii_clk_p]
set_property PACKAGE_PIN P26 [get_ports sgmii_clk_p ]
set_property PACKAGE_PIN N26 [get_ports sgmii_clk_n ]
set_property PACKAGE_PIN N24 [get_ports sgmii_txp   ]
set_property PACKAGE_PIN M24 [get_ports sgmii_txn   ]
set_property PACKAGE_PIN P24 [get_ports sgmii_rxp   ]
set_property PACKAGE_PIN P25 [get_ports sgmii_rxn   ]

set_property IOSTANDARD LVCMOS18 [get_ports {phy_*}]
set_property PACKAGE_PIN H26 [get_ports phy_mdio]
set_property PACKAGE_PIN L25 [get_ports phy_mdc]
set_property PACKAGE_PIN J23 [get_ports phy_resetb]
set_property PACKAGE_PIN K25 [get_ports phy_interrupt]

set_property IOSTANDARD LVCMOS12 [get_ports sw*]
set_property PACKAGE_PIN AN16 [get_ports sw[0]]
set_property PACKAGE_PIN AN19 [get_ports sw[1]]
set_property PACKAGE_PIN AP18 [get_ports sw[2]]
set_property PACKAGE_PIN AN14 [get_ports sw[3]]

# https://support.xilinx.com/s/article/43989?language=en_US
# set_property IOSTANDARD SUB_LVDS [get_ports clock_o_*]
# set_property PACKAGE_PIN H27 [get_ports clock_o_p]
# set_property PACKAGE_PIN G27 [get_ports clock_o_n]

set_property IOSTANDARD LVCMOS18 [get_ports user_sma_*]
set_property PULLDOWN true [get_ports user_sma_*]
set_property PACKAGE_PIN H27 [get_ports user_sma_p]
set_property PACKAGE_PIN G27 [get_ports user_sma_n]
