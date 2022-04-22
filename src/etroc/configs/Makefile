all:
	make update
	make parse

update:
	sh update_commands.sh

parse:
	python fast_commands_parser.py
	python dataformat_parser.py
