from cocotb.triggers import ClockCycles

# Reset
async def reset_sequence(dut):
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)   # Reset for 5 cycles
    dut.rst_n.value = 1
