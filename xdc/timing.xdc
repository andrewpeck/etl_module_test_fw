################################################################################
# ilas
################################################################################

set_max_delay -datapath_only \
    -from [get_clocks clk125_i] \
    -to [get_pins -hierarchical -filter { NAME =~  "*U0/PROBE_PIPE*/D" }] 5.0

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

################################################################################
# CDC exemptions
################################################################################

set_max_delay \
    -from [get_clocks -of_objects [get_pins system_clocks_inst/inst/mmcme3_adv_inst/CLKOUT0]] \
    -to [get_clocks osc_clk125] 8.0

set_max_delay  8.0 \
    -from [get_pins {eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/rd_ptr_gray*/C}] \
    -to [get_pins {eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/rd_ptr_gray_sync*/D}]

set_max_delay  8.0 \
    -from [get_pins {eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/wr_ptr_sync_gray*/C}] \
    -to [get_pins {eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/wr_ptr_gray_sync*/D}]

set_max_delay  8.0 \
  -from [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/wr_ptr_update_*/C] \
  -to [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/wr_ptr_update_sync*/D]

set_max_delay  8.0 \
    -from [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/*_rst_sync1*/C] \
    -to [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/*_rst_sync2*/D]

set_max_delay  8.0 \
    -from [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/wr_ptr_update_sync*/C] \
    -to [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*_fifo/fifo_inst/wr_ptr_update_ack*/D]

set_max_delay 8.0 \
    -to [get_pins eth.eth_infra_inst/eth/eth_mac_1g_inst/*x_fifo/fifo_inst/*rst_sync*/PRE]
    -from [get_pins reset_reg_replica_3/C]  \

set_false_path \
    -from [get_pins eth.eth_infra_inst/eth/phy_cfg_not_done*/C] \
    -to [get_pins eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/gig_eth_pcs_pma_gmii_to_sgmii_bridge_core/gpcs_pma_inst/HAS_MANAGEMENT.MDIO/CONFIG_REG_WITH_AN.ISOLATE_REG_reg/D]

set_false_path \
    -from [get_pins eth.eth_infra_inst/eth/mac_reset_reg/C] \
    -to [get_pins eth.eth_infra_inst/eth/mac_rx_reset_reg/D]

set_false_path \
    -from [get_pins eth.eth_infra_inst/eth/rst_o_reg/C] \
    -to [get_pins eth.eth_infra_inst/reset_ipb_reg/PRE]
