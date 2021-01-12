
set_max_delay -datapath_only -from [get_clocks clk125_i] -to [get_pins -hierarchical -filter { NAME =~  "*U0/PROBE_PIPE*/D" }] 4

set_max_delay -datapath_only \
    -to [get_pins -hierarchical -filter {NAME =~ "*clock_crossing_if/rx_read_buf_buf_reg*/D"}] 4

set_max_delay -datapath_only \
    -to [get_pins -hierarchical -filter {NAME =~ "*clock_crossing_if/tx_write_buf_buf_reg*/D"}] 4

set_max_delay -datapath_only \
    -from [get_pins -hierarchical -filter {NAME =~ "*req_send_tff*/Q"}]  \
    -to   [get_pins -hierarchical -filter {NAME =~ "*req_send_buf*/D"}] 4

set_max_delay -datapath_only \
    -from [get_clocks clk125_i]  \
    -to   [get_pins -hierarchical -filter {NAME =~ "*ipbus_tx_ram/ram_reg_*/*DINADIN[*]"}] 4

set_max_delay -datapath_only \
    -from [get_clocks clk125_i]  \
    -to   [get_pins -hierarchical -filter {NAME =~ "*ipbus_tx_ram/ram_reg_*/*DINPADINP[*]"}] 4

set_max_delay -datapath_only \
    -from [get_clocks -of_objects [get_pins eth.eth_infra_inst/clocks/mmcm/CLKOUT1]]  \
    -to [get_pins {eth.eth_infra_inst/ipbus/udp_if/clock_crossing_if/*/D}] 4

set_false_path \
    -from [get_pins eth.eth_infra_inst/clocks/rst_reg/C] \
    -to   [get_pins eth.eth_infra_inst/clocks/rst_ipb_ctrl_reg/D]

set_false_path \
    -from [get_pins eth.eth_infra_inst/clocks/rst_reg/C] \
    -to   [get_pins eth.eth_infra_inst/clocks/rst_ipb_reg/D]

set_false_path -from [get_pins eth.eth_infra_inst/clocks/rsto_eth_reg/C]
