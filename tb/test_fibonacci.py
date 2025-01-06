import os, cocotb
import utils
from sequences import reset_sequence
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


PROJ_DIR = utils.get_proj_dir()


@cocotb.test()
async def test_fibonacci(dut):
    # Start a clock
    cocotb.start_soon(Clock(dut.clk, 1, "ns").start())

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(dut))

    # Backdoor some instructions
    utils.load_bin_to_ram(dut, f"{PROJ_DIR}/build/asm/fibonacci.bin")

    # Wait for 1000 cycles
    await ClockCycles(dut.clk, 1000)

    # Check the final result is RAM (starting at 0x1000)
    start_word = 0x1000 // 4;
    with open(f"{PROJ_DIR}/asm/fibonacci.ref", "r") as file:
        for i, line in enumerate(file):
            # Convert to int
            number = int(line)
            # Compare with the value in RAM
            assert dut.u_ram.mem_array[start_word + i].value == number

