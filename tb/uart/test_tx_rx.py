import os, random, cocotb
from cocotb.regression import TestFactory
from sequences import *
from uart_const import *


PROJ_DIR = os.environ["PROJ_DIR"]
MSG = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."


async def test_tx(tb, fifo_enable=False, baud_rate=115200, parity_mode=ParityMode.NONE, stop_mode=StopMode.SINGLE):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup
    await line_setup(tb, baud_rate=baud_rate, parity_mode=parity_mode, stop_mode=stop_mode)
    if fifo_enable:
        await fifo_setup(tb, enable=True)

    # Transmit the message
    async def write_msg():
        await send_str(tb, MSG)

    cocotb.start_soon(write_msg())

    # Read the message from UART
    tx_msg = ""
    for i in range(len(MSG)):
        data = await uart_read(tb, baud_rate=baud_rate, parity_mode=parity_mode)
        tx_msg += chr(data)

    # Verify the message
    assert tx_msg == MSG


async def test_rx(tb, fifo_enable=False, baud_rate=115200, parity_mode=ParityMode.NONE):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup
    await line_setup(tb, baud_rate=baud_rate, parity_mode=parity_mode)
    if fifo_enable:
        await fifo_setup(tb, enable=True)

    # Transmit the message
    async def write_msg():
        for c in MSG:
            await uart_write(tb, ord(c), baud_rate=baud_rate, parity_mode=parity_mode)

    cocotb.start_soon(write_msg())

    # Read the message from register
    rx_msg = await recv_str(tb, len(MSG))

    # Verify the message
    assert rx_msg == MSG


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_tx_plain(tb):
    await test_tx(tb)


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_rx_plain(tb):
    await test_rx(tb)


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_tx_fifo(tb):
    await test_tx(tb, fifo_enable=True)


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_rx_fifo(tb):
    await test_rx(tb, fifo_enable=True)


@cocotb.test(timeout_time=20, timeout_unit="ms")
async def test_tx_slow(tb):
    await test_tx(tb, baud_rate=38400)


@cocotb.test(timeout_time=20, timeout_unit="ms")
async def test_rx_slow(tb):
    await test_rx(tb, baud_rate=38400)


tf = TestFactory(test_function=test_tx)
tf.add_option("parity_mode", [ParityMode.NONE, ParityMode.ODD, ParityMode.EVEN, ParityMode.FORCE1, ParityMode.FORCE0])
tf.add_option("stop_mode",   [StopMode.SINGLE, StopMode.DOUBLE])
tf.generate_tests(postfix="_option")


tf = TestFactory(test_function=test_rx)
tf.add_option("parity_mode", [ParityMode.NONE, ParityMode.ODD, ParityMode.EVEN, ParityMode.FORCE1, ParityMode.FORCE0])
tf.generate_tests(postfix="_option")

