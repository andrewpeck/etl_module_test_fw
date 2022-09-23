.PHONY: svg png

all: png svg

open:
	draw.io daq.drawio &

#small:
#	draw.io --width 700 -p 0 -x -f svg -o data-flow.svg etl-readout-board.drawio
#
#large:
#	draw.io --width 2400 -p 0 -x -f png -o data-flow_large.png etl-readout-board.drawio
#	draw.io --width 2400 -p 1 -x -f png -o power-distribution_large.png etl-readout-board.drawio
#	draw.io --width 2400 -p 2 -x -f png -o ctrl-and-mon_large.png etl-readout-board.drawio
#	draw.io --width 2400 -p 3 -x -f png -o module-connectivity_large.png etl-readout-board.drawio

svg:
	draw.io -x -f svg -o daq.svg daq.drawio
	draw.io -x -f svg -o fast_commands.svg fast_commands.drawio

png:
	draw.io --width 1024 -x -f png -o daq.png daq.drawio
	draw.io --width 1024 -x -f png -o fast_commands.png fast_commands.drawio
