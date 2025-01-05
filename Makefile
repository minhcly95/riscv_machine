.PHONY: lint clean clean-lint

PROJ_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export PROJ_DIR

lint:
	verilator --lint-only --no-std --top core_top -Wall -f lint/lint_err.lst -f rtl/rtl.lst |& tee lint/lint.log

clean: clean-lint

clean-lint:
	rm lint/*.log
