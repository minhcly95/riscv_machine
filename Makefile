.PHONY: lint waive sim wave asm isa clean clean-lint clean-sim clean-asm clean-isa

PROJ_DIR ?= $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export PROJ_DIR

TOP ?= top

lint:
	verilator --lint-only --no-std --top $(TOP) -Wall -f lint/lint_err.lst lint/waive.vlt -f rtl/rtl.lst |& tee lint/lint.log

waive:
	verilator --lint-only --no-std --top $(TOP) -Wall -f lint/lint_err.lst lint/waive.vlt -f rtl/rtl.lst --waiver-output lint/waive-auto.vlt |& tee lint/lint.log

sim: asm isa
	$(MAKE) -C tb

wave:
	gtkwave tb/dump.fst

asm:
	$(MAKE) -C prog/asm asm

isa:
	$(MAKE) -C prog/isa isa

clean: clean-lint clean-sim clean-asm clean-isa

clean-lint:
	rm lint/*.log

clean-sim:
	$(MAKE) -C tb clean
	rm tb/results.xml

clean-asm:
	$(MAKE) -C prog/asm clean

clean-isa:
	$(MAKE) -C prog/isa clean
