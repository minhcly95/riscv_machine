from cocotb.triggers import ClockCycles

# Reset
async def reset_sequence(tb):
    tb.rst_n.value = 0
    await ClockCycles(tb.clk, 5)   # Reset for 5 cycles
    tb.rst_n.value = 1
