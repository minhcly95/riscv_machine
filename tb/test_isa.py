import os, cocotb
import utils
from sequences import reset_sequence
from cocotb.triggers import ClockCycles


PROJ_DIR     = utils.get_proj_dir()
POLL_CLK     = 1000
MAX_POLL     = 100
TO_HOST_ADDR = 0x1000


async def test_isa(tb, test_name):
    dut = tb.u_top

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    utils.load_bin_to_ram(dut, f"{PROJ_DIR}/build/isa/{test_name}.bin")

    # Poll the mem at 0x1000 for changes
    for poll in range(MAX_POLL):
        await ClockCycles(dut.clk, POLL_CLK)
        if utils.ram(dut, TO_HOST_ADDR).value != 0:
            break

    # Check the final result in mem at 0x1000
    # A value of 1 means pass, > 1 means fail
    assert utils.ram(dut, TO_HOST_ADDR).value == 1


# Read the list of tests in a file, then generate the test code
def generate_tests(test_type):
    code = ""
    with open(f"{PROJ_DIR}/isa/{test_type}.txt", "r") as file:
        for i, line in enumerate(file):
            line = line.rstrip('\n')
            code += f"""
@cocotb.test()
async def test_{line.replace("-", "_")}(tb):
    await test_isa(tb, "{line}")
"""
    return code


exec(generate_tests("rv32ui"))
exec(generate_tests("rv32um"))
exec(generate_tests("rv32ua"))
exec(generate_tests("rv32mi"))
exec(generate_tests("rv32si"))


