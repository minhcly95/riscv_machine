TRACE_ARGS = --trace --trace-fst --trace-structs

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/core/core_tb.lst

TOPLEVEL = core_tb_top

MODULE ?= "test_fibonacci,\
		   test_isa,\
		   test_access_fault,\
		   test_seq_mul,\
		   test_seq_div,\
		   test_int,\
		   test_translate_gather,\
		   test_translate_scatter"

COMPILE_ARGS += -f $(LIST_FILE) $(TRACE_ARGS)

EXTRA_ARGS += --timing

ifeq ($(WAVE),1)
	SIM_ARGS += $(TRACE_ARGS)
endif

SIM_BUILD = $(PROJ_DIR)/build/sim/core

include $(shell cocotb-config --makefiles)/Makefile.sim
