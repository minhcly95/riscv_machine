SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/rtl/rtl.lst

VERILOG_SOURCES += $(shell echo $(shell cat $(LIST_FILE))) $(PROJ_DIR)/tb/tb_top.sv

TOPLEVEL = tb_top

MODULE = test_fibonacci,test_isa,test_access_fault,test_seq_mul,test_seq_div

EXTRA_ARGS += --trace --trace-fst --trace-structs --timing

SIM_BUILD = $(PROJ_DIR)/build/sim

include $(shell cocotb-config --makefiles)/Makefile.sim
