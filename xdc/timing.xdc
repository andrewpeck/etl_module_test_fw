################################################################################
# Create Clocks
################################################################################

# si570 user clock
# create_clock -period 3.124 -name si570_usrclk_p [get_ports {si570_usrclk_p}]

# create_generated_clock -name clock_o_p \
#     -source [get_pins {ODDRE1_inst/CLKDIV}] \
#     -divide_by 1 -invert [get_ports {clock_o_p}]

# M88E1111 Ethernet Phy

################################################################################
# UDP Clock crossing
################################################################################

# 125MHz clk -> 8 ns
set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to   [get_clocks I] 5.0

set_max_delay -datapath_only \
    -from [get_clocks I] \
    -to   [get_clocks clk125_i] 5.0

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to   [get_clocks clk_40_system_clocks] 5.0

set_max_delay -datapath_only \
    -from [get_clocks clk_40_system_clocks] \
    -to   [get_clocks clk125_i] 5.0

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to   [get_clocks osc_clk125] 5.0

set_max_delay -datapath_only \
    -from [get_clocks osc_clk125] \
    -to   [get_clocks clk125_i] 5.0

################################################################################
## Ipb Clock crossing
################################################################################

# ipb to tx/rx outclk
set_max_delay \
         -from [get_clocks I] \
         -to [get_clocks *xoutclk_out*] 5.0

# tx/rx outclk to ipb
set_max_delay \
         -from [get_clocks *xoutclk_out*] \
         -to [get_clocks I] 5.0

# ipb to clk40
set_max_delay \
         -from [get_clocks I] \
         -to [get_clocks clk_40_system_clocks] 5.0

# ipb to clk320
set_max_delay -datapath_only \
         -from [get_clocks I] \
         -to [get_clocks clk_320_system_clocks] 3.1

# clk40 to ipb
set_max_delay -datapath_only \
         -from [get_clocks clk_40_system_clocks] \
         -to [get_clocks I] 5.0

# clk320 to ipb
set_max_delay -datapath_only \
         -from [get_clocks clk_320_system_clocks] \
         -to [get_clocks I] 3.1

################################################################################
# ilas
################################################################################

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to [get_pins -hierarchical -filter { NAME =~  "*U0/PROBE_PIPE*/D" }] 5.0

set_false_path -from \
    [get_pins {eth.eth_infra_inst/eth/debugilas.vio_sgmii_1/inst/*/Probe_out_reg[*]/C}]

################################################################################
# Resets
################################################################################

set_false_path \
    -from [get_pins eth.eth_infra_inst/clocks/rst_reg/C] \
    -to   [get_pins eth.eth_infra_inst/clocks/rst_ipb_ctrl_reg/D]

set_false_path \
    -from [get_pins eth.eth_infra_inst/clocks/rst_reg/C] \
    -to   [get_pins eth.eth_infra_inst/clocks/rst_ipb_reg/D]

set_false_path -from [get_pins eth.eth_infra_inst/clocks/rsto_eth_reg/C]

set_false_path \
    -from [get_clocks osc_clk125] \
    -to [get_pins eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/gig_eth_pcs_pma_gmii_to_sgmii_bridge_core/gpcs_pma_inst/HAS_MANAGEMENT.MDIO/*/D]

################################################################################
# Clock frequency counters
################################################################################

set_max_delay -datapath_only \
    -from [get_clocks] \
    -to [get_pins -hierarchical -filter { NAME =~ "*frequency_counter_inst*/rate_reg[*]/D"}] 8

set_max_delay -datapath_only \
    -from [get_clocks] \
    -to [get_pins -hierarchical -filter { NAME =~ "*frequency_counter_inst*/valid_sr_reg[0]/D"}] 8

set_max_delay -datapath_only \
    -from [get_clocks] \
    -to [get_pins -hierarchical -filter { NAME =~ "*frequency_counter_inst*/measure_sr_reg[0]/D"}] 8

set_max_delay -datapath_only \
    -from [get_clocks] \
    -to [get_pins -hierarchical -filter { NAME =~ "*control_inst/FW_INFO_wb_map/localRdData_reg[*]/D"}] 8
