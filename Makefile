SHELL := /bin/bash

.PHONY: create synth impl reg init

CCZE := $(shell command -v ccze 2> /dev/null)
ifndef CCZE
COLORIZE =
else
COLORIZE = | ccze -A
endif

IFTIME := $(shell command -v time 2> /dev/null)
ifndef IFTIME
TIMECMD =
else
TIMECMD = time -p
endif

export LD_LIBRARY_PATH=/opt/cactus/lib

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

init:
	git submodule update --init --recursive

################################################################################
# Hog
################################################################################

create:
	$(TIMECMD) Hog/CreateProject.sh etl_test_fw $(COLORIZE)

synth:
	$(TIMECMD) Hog/LaunchWorkflow.sh -synth_only etl_test_fw $(COLORIZE)

impl:
	$(TIMECMD) Hog/LaunchWorkflow.sh etl_test_fw $(COLORIZE)

clean:
	rm -rf Projects/

################################################################################
# Registers
################################################################################

decode:
	/opt/cactus/bin/uhal/tools/gen_ipbus_addr_decode address_tables/etl_test_fw.xml
	mv ipbus_decode_etl_test_fw.vhd registers/

XML_FILES=$(shell find registers/ -name *.xml -type l)
MAP_OBJS = $(patsubst %.xml, %_map.vhd, $(XML_FILES))
PKG_OBJS = $(patsubst %.xml, %_PKG.vhd, $(XML_FILES))

reg:
	make clean_regmap
	make regmap

# Update the XML2VHDL register map
regmap : $(MAP_OBJS)

# Update the XML2VHDL register map
%_map.vhd %_PKG.vhd : %.xml
	@python3 regmap/build_vhdl_packages.py \
			-s False \
			-x address_tables/modules/$(basename $(notdir $<)).xml \
			-o  $(dir $<) \
			--mapTemplate templates/wishbone/template_map.vhd \
        $(basename $(notdir $<))
	make decode

clean_regmap:
	@rm -rf $(MAP_OBJS) $(PKG_OBJS)

docs: 
	pandoc README.org -o README.md -t gfm
