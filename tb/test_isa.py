import os, cocotb
import utils
from sequences import reset_sequence
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


PROJ_DIR = utils.get_proj_dir()
MAX_CLK  = 2000


async def test_isa(dut, test_name):
    # Start a clock
    cocotb.start_soon(Clock(dut.clk, 1, "ns").start())

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(dut))

    # Backdoor some instructions
    utils.load_bin_to_ram(dut, f"{PROJ_DIR}/build/isa/{test_name}.bin")

    # Wait for 10000 cycles
    await ClockCycles(dut.clk, MAX_CLK)

    # Check the final result is register
    # Reg a7 (x17) is always 93
    # Reg a0 (x10) == 0 means pass
    assert dut.u_core.u_reg_file.reg_mem[17].value == 93
    assert dut.u_core.u_reg_file.reg_mem[10].value == 0


# Read the list of tests in a file, then generate the test code
def generate_tests(test_type):
    code = ""
    with open(f"{PROJ_DIR}/isa/{test_type}.txt", "r") as file:
        for i, line in enumerate(file):
            line = line.rstrip('\n')
            code += f"""
@cocotb.test()
async def test_{line.replace("-", "_")}(dut):
    await test_isa(dut, "{line}")
"""
    return code


exec(generate_tests("rv32ui"))
exec(generate_tests("rv32um"))
exec(generate_tests("rv32ua"))
exec(generate_tests("rv32mi"))
exec(generate_tests("rv32si"))


