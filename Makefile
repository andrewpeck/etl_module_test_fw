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

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

all: create synth impl

init:
	git submodule update --init

reg:
	cd regmap && make

create:
	$(TIMECMD) Hog/CreateProject.sh etl_test_fw $(COLORIZE)

synth:
	$(TIMECMD) Hog/LaunchWorkflow.sh -synth_only etl_test_fw $(COLORIZE)

impl:
	$(TIMECMD) Hog/LaunchWorkflow.sh -impl_only etl_test_fw $(COLORIZE)

clean:
	rm -rf VivadoProject/