import os, cocotb
import utils
from ram import Ram
from sequences import reset_sequence


PROJ_DIR = utils.get_proj_dir()
BASE_RES = 0x1000


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_fibonacci(tb):
    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    ram = Ram(tb.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/asm/fibonacci.bin")

    # Wait for ecall
    await utils.wait_ecall(tb.u_core)

    # Check the final result is RAM (starting at 0x1000)
    with open(f"{PROJ_DIR}/prog/asm/fibonacci.ref", "r") as file:
        for i, line in enumerate(file):
            # Convert to int
            number = int(line)
            # Compare with the value in RAM
            assert ram.at(BASE_RES + (i << 2)).value == number

