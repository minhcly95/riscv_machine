import os, cocotb
import utils
from ram import Ram
from uart import *
from sequences import reset_sequence


PROJ_DIR = utils.get_proj_dir()


@cocotb.test()
async def demo_echo(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Backdoor some instructions
    ram = Ram(tb.dut.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/c/demo_echo.bin")

    # Wait for CPU setup
    await ClockCycles(tb.clk, 100)

    # Open virtual terminal for UART
    uart = Uart(tb)
    cocotb.start_soon(uart.open_pty())

    # Wait for an ECALL
    await utils.wait_ecall(tb.dut.u_core)

