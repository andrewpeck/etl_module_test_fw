################################################################################
# UDP Clock crossing
################################################################################

# 125MHz clk -> 8 ns
set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to   [get_clocks I] 7

set_max_delay -datapath_only \
    -from [get_clocks I] \
    -to   [get_clocks clk125_i] 7

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to   [get_clocks osc_clk125] 7

set_max_delay -datapath_only \
    -from [get_clocks osc_clk125] \
    -to   [get_clocks clk125_i] 7


################################################################################
## Ipb Clock crossing
################################################################################

# ipb to clk40
set_max_delay \
         -from [get_clocks I] \
         -to [get_clocks clk_40_system_clocks] 12.0

# ipb to clk320
set_max_delay -datapath_only \
         -from [get_clocks I] \
         -to [get_clocks clk_320_system_clocks] 3.1

# clk40 to ipb
set_max_delay -datapath_only \
         -from [get_clocks clk_40_system_clocks] \
         -to [get_clocks I] 12.0

# clk320 to ipb
set_max_delay -datapath_only \
         -from [get_clocks clk_320_system_clocks] \
         -to [get_clocks I] 3.1

################################################################################
# ilas
################################################################################

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to [get_pins -hierarchical -filter { NAME =~  "*U0/PROBE_PIPE*/D" }] 4

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
    -to [get_pins -hierarchical -filter { NAME =~ "*control_inst/FW_INFO_wb_interface/localRdData_reg[*]/D"}] 8
