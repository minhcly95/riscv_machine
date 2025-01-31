import os, random, cocotb
import utils
from ram import Ram
from sequences import reset_sequence


PROJ_DIR    = utils.get_proj_dir()
CODE_SEQ    = [5, 7, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]
BASE_DATA   = 0x1000


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_access_fault(tb):
    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    ram = Ram(tb.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/asm/access_fault.bin")

    # Wait for ecall
    await utils.wait_ecall(tb.u_core)

    # Check the results
    for (i, code) in enumerate(CODE_SEQ):
        assert ram.at(BASE_DATA + 8*i).value     == i + 1, f"Result {i+1} did not exist"
        assert ram.at(BASE_DATA + 8*i + 4).value == code,  f"Test {i+1} failed"

