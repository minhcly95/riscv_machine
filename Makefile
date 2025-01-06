.PHONY: lint sim wave asm isa clean clean-lint clean-sim clean-asm clean-isa

PROJ_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export PROJ_DIR

lint:
	verilator --lint-only --no-std --top top -Wall -f lint/lint_err.lst -f rtl/rtl.lst |& tee lint/lint.log

sim: asm isa
	$(MAKE) -C tb

wave:
	gtkwave tb/dump.fst

asm:
	$(MAKE) -C asm asm

isa:
	$(MAKE) -C isa isa

clean: clean-lint clean-sim clean-asm clean-isa

clean-lint:
	rm lint/*.log

clean-sim:
	$(MAKE) -C tb clean
	rm tb/results.xml

clean-asm:
	$(MAKE) -C asm clean

clean-isa:
	$(MAKE) -C isa clean
