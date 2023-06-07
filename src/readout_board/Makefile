test_filler_generator:
	ghdl -a --std=08 ../etroc/configs/*.vhd ../etroc/decoding_gearbox.vhd ../etroc/etroc_rx.vhd tx_filler_generator.vhd tx_filler_generator_tb.vhd
	ghdl -e --std=08 tx_filler_tb
	ghdl -r --std=08 tx_filler_tb --wave=tx_filler.ghw
