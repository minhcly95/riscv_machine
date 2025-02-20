SCOPES            = top core uart plic
SIM_TARGETS       = $(addprefix sim-,$(SCOPES))
RUN_TARGETS       = $(addprefix run-,$(SCOPES))
CLEAN_SIM_TARGETS = $(addprefix clean-sim-,$(SCOPES))

.PHONY: lint waive run sim asm isa c dt clean clean-lint clean-sim clean-asm clean-isa clean-dt run-linux sim-linux

PROJ_DIR ?= $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export PROJ_DIR

PYTHONPATH += :$(PROJ_DIR)/tb/common
export PYTHONPATH

TOP ?= top

lint:
	verilator --lint-only --no-std --top $(TOP) -Wall -f lint/lint_err.lst lint/waive.vlt -f rtl/rtl.lst |& tee lint/lint.log

waive:
	verilator --lint-only --no-std --top $(TOP) -Wall -f lint/lint_err.lst lint/waive.vlt -f rtl/rtl.lst --waiver-output lint/waive-auto.vlt |& tee lint/lint.log

run:
	$(MAKE) run-core
	$(MAKE) run-uart
	$(MAKE) run-plic
	$(MAKE) run-top

run-top: asm c

run-core: asm isa

run-linux:
	MODULE=demo_linux $(MAKE) -C tb/top

sim: clean-sim
	$(MAKE) run

sim-linux: clean-sim-top
	$(MAKE) run-linux

asm:
	$(MAKE) -C prog/asm asm

isa:
	$(MAKE) -C prog/isa isa

c:
	$(MAKE) -C prog/c build

dt:
	$(MAKE) -C dt build

clean: clean-lint clean-sim clean-asm clean-isa clean-c clean-dt

clean-lint:
	rm -f lint/*.log

clean-sim: $(CLEAN_SIM_TARGETS)

clean-asm:
	$(MAKE) -C prog/asm clean

clean-isa:
	$(MAKE) -C prog/isa clean

clean-c:
	$(MAKE) -C prog/c clean

clean-dt:
	$(MAKE) -C dt clean


# Generated rules
define GENERATE_RULE
.PHONY: run-$(1) sim-$(1) wave-$(1) clean-sim-$(1)

run-$(1):
	$(MAKE) -C tb/$(1)

sim-$(1):
	$(MAKE) clean-sim-$(1)
	$(MAKE) run-$(1)

wave-$(1):
	@if [ -f tb/$(1)/dump.fst ]; then \
		gtkwave tb/$(1)/dump.fst;     \
	else							  \
		gtkwave tb/$(1)/dump.vcd;     \
	fi

clean-sim-$(1):
	$(MAKE) -C tb/$(1) clean
	rm -f tb/$(1)/results.xml
endef

$(foreach scope,$(SCOPES),$(eval $(call GENERATE_RULE,$(scope))))

