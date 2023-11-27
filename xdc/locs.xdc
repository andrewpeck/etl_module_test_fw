# Location constraints

# gbe rx
set_property LOC  [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/iserdes_m] BITSLICE_RX_TX_X1Y80
set_property LOC  [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/iserdes_s] BITSLICE_RX_TX_X1Y81

# gbe tx
set_property LOC [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_10_to_1_ser8_i/oserdes_m] BITSLICE_RX_TX_X1Y75
set_property LOC [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_10_to_1_ser8_i/gb0/loop0[0].dataout_reg[0]] SLICE_X44Y89
set_property LOC [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_10_to_1_ser8_i/gb0/loop0[0].dataout_reg[1]] SLICE_X43Y89
set_property LOC [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_10_to_1_ser8_i/gb0/loop0[0].dataout_reg[2]] SLICE_X44Y89
set_property LOC [get_cells eth.eth_infra_inst/eth/sgmii/U0/pcs_pma_block_i/lvds_transceiver_mw/serdes_10_to_1_ser8_i/gb0/loop0[0].dataout_reg[3]] SLICE_X43Y89

