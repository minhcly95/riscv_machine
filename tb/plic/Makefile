TRACE_ARGS = --trace --trace-structs

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/plic/plic_tb.lst

TOPLEVEL = plic_tb_top

MODULE ?= test_zero_prio,test_threshold,test_order,test_pending,test_normal,test_routing

COMPILE_ARGS += -f $(LIST_FILE) $(TRACE_ARGS) -Wno-CMPCONST

ifeq ($(WAVE),1)
	SIM_ARGS += $(TRACE_ARGS)
endif

SIM_BUILD = $(PROJ_DIR)/build/sim/plic

include $(shell cocotb-config --makefiles)/Makefile.sim
