import os, cocotb
import utils
from ram import Ram
from uart import *
from sequences import reset_sequence


PROJ_DIR = utils.get_proj_dir()

MSG = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam vel nulla ut " \
      "lectus congue aliquam vitae quis ex. In commodo auctor justo sit amet "       \
      "sagittis. Suspendisse sollicitudin auctor elit id mattis. Aenean ac feugiat " \
      "turpis. Nam auctor sagittis auctor. Pellentesque habitant morbi tristique "   \
      "senectus et netus et malesuada fames ac turpis egestas. Praesent mauris "     \
      "libero, euismod vitae sodales feugiat, egestas id dolor. Vestibulum at nisl " \
      "tortor."


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_to_upper(tb, bin_name="test_to_upper"):
    # Start the reset sequence
    await reset_sequence(tb)

    # Backdoor some instructions
    ram = Ram(tb.dut.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/c/{bin_name}.bin")

    # Wait for CPU setup
    await ClockCycles(tb.clk, 500)

    # Send the message to RX
    uart = Uart(tb)
    cocotb.start_soon(uart.write_str(MSG))

    # Read the message from TX
    tx_msg = await uart.read_str(len(MSG))

    # Verify the message
    assert tx_msg == MSG.upper()


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_to_upper_int(tb):
    await test_to_upper(tb, bin_name="test_to_upper_int")
