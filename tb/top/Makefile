SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/top/tb.lst

TOPLEVEL = tb_top

MODULE ?= test_echo,test_to_upper

COMPILE_ARGS += -f $(LIST_FILE)

EXTRA_ARGS += --trace --trace-fst --trace-structs --timing

SIM_BUILD = $(PROJ_DIR)/build/sim/top

include $(shell cocotb-config --makefiles)/Makefile.sim
