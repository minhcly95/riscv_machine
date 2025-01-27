import os, random, cocotb
import utils
from sequences import reset_sequence


PROJ_DIR    = utils.get_proj_dir()
MAX_CLK     = 100000
CODE_SEQ    = [5, 7, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]
BASE_DATA   = 0x1000


@cocotb.test()
async def test_access_fault(tb):
    dut = tb.u_top

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    utils.load_bin_to_ram(dut, f"{PROJ_DIR}/build/asm/access_fault.bin")

    # Wait for ecall or max cycles
    await utils.wait_ecall(dut, MAX_CLK)

    # Check the results
    for (i, code) in enumerate(CODE_SEQ):
        assert utils.ram(dut, BASE_DATA + 8*i).value     == i + 1, f"Result {i+1} did not exist"
        assert utils.ram(dut, BASE_DATA + 8*i + 4).value == code,  f"Test {i+1} failed"

