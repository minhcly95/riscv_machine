import os, cocotb
import utils
from ram import Ram
from uart import *
from sequences import reset_sequence


PROJ_DIR = utils.get_proj_dir()


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_timer(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Backdoor some instructions
    ram = Ram(tb.dut.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/c/test_timer.bin")

    # Wait for CPU setup
    await ClockCycles(tb.clk, 100)

    # Read the output from UART
    uart = Uart(tb)
    tx_msg = await uart.read_str(256)

    # Verify the message (256 bytes from 0 to 255)
    assert tx_msg == ''.join(chr(i) for i in range(256))

