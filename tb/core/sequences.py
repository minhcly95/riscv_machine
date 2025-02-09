from cocotb.triggers import ClockCycles

# Reset
async def reset_sequence(tb):
    tb.rst_n.value      = 0
    tb.int_m_ext.value  = 0
    tb.int_s_ext.value  = 0
    tb.mtimer_int.value = 0
    await ClockCycles(tb.clk, 5)   # Reset for 5 cycles
    tb.rst_n.value      = 1
