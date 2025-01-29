SCOPES            = top core uart
SIM_TARGETS       = $(addprefix sim-,$(SCOPES))
RUN_TARGETS       = $(addprefix run-,$(SCOPES))
CLEAN_SIM_TARGETS = $(addprefix clean-sim-,$(SCOPES))

.PHONY: lint waive run sim asm isa clean clean-lint clean-sim clean-asm clean-isa

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
	$(MAKE) run-top

run-top: asm

run-core: asm isa

sim: clean-sim
	$(MAKE) run

asm:
	$(MAKE) -C prog/asm asm

isa:
	$(MAKE) -C prog/isa isa

clean: clean-lint clean-sim clean-asm clean-isa

clean-lint:
	rm -f lint/*.log

clean-sim: $(CLEAN_SIM_TARGETS)

clean-asm:
	$(MAKE) -C prog/asm clean

clean-isa:
	$(MAKE) -C prog/isa clean


# Generated rules
define GENERATE_RULE
.PHONY: run-$(1) sim-$(1) wave-$(1) clean-sim-$(1)

run-$(1):
	$(MAKE) -C tb/$(1)

sim-$(1):
	$(MAKE) clean-sim-$(1)
	$(MAKE) run-$(1)

wave-$(1):
	gtkwave tb/$(1)/dump.fst

clean-sim-$(1):
	$(MAKE) -C tb/$(1) clean
	rm -f tb/$(1)/results.xml
endef

$(foreach scope,$(SCOPES),$(eval $(call GENERATE_RULE,$(scope))))

