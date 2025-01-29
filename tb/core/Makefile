SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/core/core_tb.lst

TOPLEVEL = core_tb_top

MODULE = test_fibonacci,test_isa,test_access_fault,test_seq_mul,test_seq_div

COMPILE_ARGS += -f $(LIST_FILE)

EXTRA_ARGS += --trace --trace-fst --trace-structs --timing

SIM_BUILD = $(PROJ_DIR)/build/sim/core

include $(shell cocotb-config --makefiles)/Makefile.sim
