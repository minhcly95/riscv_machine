import os, random, cocotb
from cocotb.regression import TestFactory
from sequences import *
from uart import *


MSG = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."


async def test_tx(tb, fifo_enable=False, baud_rate=115200, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup(baud_rate=baud_rate, word_len=word_len, parity_mode=parity_mode)
    if fifo_enable:
        await apb.fifo_setup(enable=True)

    # Transmit the message
    cocotb.start_soon(apb.send_str(MSG))

    # Read the message from UART
    uart = Uart(tb, baud_rate=baud_rate, word_len=word_len, parity_mode=parity_mode)
    tx_msg = await uart.read_str(len(MSG))

    # Verify the message
    assert tx_msg == word_len.cast_str(MSG)


async def test_rx(tb, fifo_enable=False, baud_rate=115200, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup(baud_rate=baud_rate, word_len=word_len, parity_mode=parity_mode)
    if fifo_enable:
        await apb.fifo_setup(enable=True)

    # Transmit the message
    uart = Uart(tb, baud_rate=baud_rate, word_len=word_len, parity_mode=parity_mode)
    cocotb.start_soon(uart.write_str(MSG))

    # Read the message from register
    rx_msg = await apb.recv_str(len(MSG))

    # Verify the message
    assert rx_msg == word_len.cast_str(MSG)


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
tf.add_option("word_len",    [WordLength.WORD_5, WordLength.WORD_6, WordLength.WORD_7, WordLength.WORD_8])
tf.add_option("parity_mode", [ParityMode.NONE, ParityMode.ODD, ParityMode.EVEN, ParityMode.FORCE1, ParityMode.FORCE0])
tf.generate_tests(postfix="_option")


tf = TestFactory(test_function=test_rx)
tf.add_option("word_len",    [WordLength.WORD_5, WordLength.WORD_6, WordLength.WORD_7, WordLength.WORD_8])
tf.add_option("parity_mode", [ParityMode.NONE, ParityMode.ODD, ParityMode.EVEN, ParityMode.FORCE1, ParityMode.FORCE0])
tf.generate_tests(postfix="_option")

