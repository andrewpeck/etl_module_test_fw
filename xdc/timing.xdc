################################################################################
# UDP Clock crossing
################################################################################

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to   [get_clocks I] 4

set_max_delay -datapath_only \
    -from [get_clocks I] \
    -to   [get_clocks clk125_i] 4

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
    -from [get_pins {eth.eth_infra_inst/eth/rst_delay_slr_reg[0]/C}] \
    -to [get_pins {eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/gig_eth_pcs_pma_gmii_to_sgmii_bridge_core/gpcs_pma_inst/NO_MANAGEMENT.CONFIGURATION_VECTOR_REG_reg[3]/D}]
