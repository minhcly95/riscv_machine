SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/uart/uart_tb.lst

TOPLEVEL = uart_top

MODULE ?= test_tx_rx,test_int

COMPILE_ARGS += -f $(LIST_FILE)

EXTRA_ARGS += --trace --trace-fst --trace-structs

SIM_BUILD = $(PROJ_DIR)/build/sim/uart

include $(shell cocotb-config --makefiles)/Makefile.sim
