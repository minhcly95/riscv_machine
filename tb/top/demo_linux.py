import os, cocotb
import utils
from cocotb.triggers import *
from ram import Ram
from uart import *
from sequences import reset_sequence


PROJ_DIR = utils.get_proj_dir()


@cocotb.test()
async def demo_linux(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    ram = Ram(tb.dut.u_ram)
    rom = Ram(tb.dut.u_rom)

    # Load Device tree
    rom.load_bin(f"{PROJ_DIR}/build/dt/riscv_machine.dtb")

    # Load OpenSBI firmware
    ram.load_bin(f"{PROJ_DIR}/build/fw_jump.bin")

    # Backdoor initial register value
    tb.dut.u_core.u_reg_file.reg_mem[10].value = 0            # Hart ID
    tb.dut.u_core.u_reg_file.reg_mem[11].value = 0xf0000000   # Device tree blob

    # Open virtual terminal for UART
    uart = Uart(tb)
    cocotb.start_soon(uart.open_pty())

    # Await to infinity
    while True:
        await ClockCycles(tb.clk, 10000)

