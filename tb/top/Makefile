TRACE_ARGS = --trace --trace-fst --trace-structs

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/top/tb.lst

TOPLEVEL = tb_top

MODULE ?= test_echo,test_to_upper,test_timer

COMPILE_ARGS += -f $(LIST_FILE) $(TRACE_ARGS)

EXTRA_ARGS += --timing

ifeq ($(WAVE),1)
	SIM_ARGS += $(TRACE_ARGS)
endif

SIM_BUILD = $(PROJ_DIR)/build/sim/top

include $(shell cocotb-config --makefiles)/Makefile.sim
