.PHONY: lint waive run run-uart sim sim-uart wave wave-uart asm isa clean clean-lint clean-sim clean-sim-uart clean-asm clean-isa

PROJ_DIR ?= $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export PROJ_DIR

TOP ?= top

lint:
	verilator --lint-only --no-std --top $(TOP) -Wall -f lint/lint_err.lst lint/waive.vlt -f rtl/rtl.lst |& tee lint/lint.log

waive:
	verilator --lint-only --no-std --top $(TOP) -Wall -f lint/lint_err.lst lint/waive.vlt -f rtl/rtl.lst --waiver-output lint/waive-auto.vlt |& tee lint/lint.log

run: asm isa
	$(MAKE) -C tb/top

run-uart:
	$(MAKE) -C tb/uart

sim:
	$(MAKE) clean-sim
	$(MAKE) run

sim-uart:
	$(MAKE) clean-sim-uart
	$(MAKE) run-uart

wave:
	gtkwave tb/top/dump.fst

wave-uart:
	gtkwave tb/uart/dump.fst

asm:
	$(MAKE) -C prog/asm asm

isa:
	$(MAKE) -C prog/isa isa

clean: clean-lint clean-sim clean-sim-uart clean-asm clean-isa

clean-lint:
	rm -f lint/*.log

clean-sim:
	$(MAKE) -C tb/top clean
	rm -f tb/top/results.xml

clean-sim-uart:
	$(MAKE) -C tb/uart clean
	rm -f tb/uart/results.xml

clean-asm:
	$(MAKE) -C prog/asm clean

clean-isa:
	$(MAKE) -C prog/isa clean
