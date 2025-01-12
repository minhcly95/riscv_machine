SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/rtl/rtl.lst

VERILOG_SOURCES += $(shell echo $(shell cat $(LIST_FILE)))

TOPLEVEL = top

MODULE = test_fibonacci,test_isa,test_seq_mul,test_seq_div

EXTRA_ARGS += --trace --trace-fst --trace-structs

SIM_BUILD = $(PROJ_DIR)/build/sim

include $(shell cocotb-config --makefiles)/Makefile.sim
