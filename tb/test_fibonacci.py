import os, cocotb
import utils
from sequences import reset_sequence
from cocotb.triggers import ClockCycles, RisingEdge, First


PROJ_DIR = utils.get_proj_dir()
MAX_CLK  = 1000
BASE_RES = 0x1000


@cocotb.test()
async def test_fibonacci(tb):
    dut = tb.u_top

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    utils.load_bin_to_ram(dut, f"{PROJ_DIR}/build/asm/fibonacci.bin")

    # Wait for ecall or max cycles
    ecall   = RisingEdge(dut.u_core.u_stage_exec.ecall)
    max_clk = ClockCycles(dut.clk, MAX_CLK)
    await First(ecall, max_clk)

    # Check the final result is RAM (starting at 0x1000)
    with open(f"{PROJ_DIR}/asm/fibonacci.ref", "r") as file:
        for i, line in enumerate(file):
            # Convert to int
            number = int(line)
            # Compare with the value in RAM
            assert utils.ram(dut, BASE_RES + (i << 2)).value == number

