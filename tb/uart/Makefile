TRACE_ARGS = --trace --trace-fst --trace-structs

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

LIST_FILE ?= $(PROJ_DIR)/tb/uart/uart_tb.lst

TOPLEVEL = uart_top

MODULE ?= test_tx_rx,test_int,test_loopback,test_err

COMPILE_ARGS += -f $(LIST_FILE) $(TRACE_ARGS)

ifeq ($(WAVE),1)
	SIM_ARGS += $(TRACE_ARGS)
endif

SIM_BUILD = $(PROJ_DIR)/build/sim/uart

include $(shell cocotb-config --makefiles)/Makefile.sim
