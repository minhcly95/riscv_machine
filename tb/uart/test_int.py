import os, random, cocotb
from cocotb.triggers import *
from sequences import *
from uart_const import *


MSG = "Ut at convallis arcu, vitae tempus purus. Integer eget commodo metus."


def split_into_chunks(s, chunk_size=16):
    return [s[i:i+chunk_size] for i in range(0, len(s), chunk_size)]


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_tx_int(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup
    await line_setup(tb)
    await apb_write_byte(tb, REG_IER, IER_THR_EMPTY)

    # Transmit the message
    async def send_msg(tb, msg):
        for c in msg:
            # Wait for interrupt
            if tb.uart_int.value == 0:
                await RisingEdge(tb.uart_int)
            # Verify that the interrupt is THR_EMPTY
            isr = await apb_read_byte(tb, REG_ISR)
            assert (isr & ISR_INT_MASK) == ISR_INT_THR_EMPTY;
            # Send the character
            await apb_write_byte(tb, REG_THR, ord(c))
            # Wait 1 cycle
            await ClockCycles(tb.clk, 1)

    cocotb.start_soon(send_msg(tb, MSG))

    # Read the message from UART
    tx_msg = await uart_read_str(tb, len(MSG))

    # Verify the message
    assert tx_msg == MSG


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_rx_int(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup
    await line_setup(tb)
    await apb_write_byte(tb, REG_IER, IER_RX_DATA_READY)

    # Transmit the message
    cocotb.start_soon(uart_write_str(tb, MSG))

    # Read the message from register
    rx_msg = ""
    for i in range(len(MSG)):
        # Wait for interrupt
        if tb.uart_int.value == 0:
            await RisingEdge(tb.uart_int)
        # Verify that the interrupt is RX_DATA_READY
        isr = await apb_read_byte(tb, REG_ISR)
        assert (isr & ISR_INT_MASK) == ISR_INT_RX_DATA_READY
        # Read the character
        data = await apb_read_byte(tb, REG_RHR)
        rx_msg += chr(data)
        # Wait 1 cycle
        await ClockCycles(tb.clk, 1)

    # Verify the message
    assert rx_msg == MSG


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_tx_int_fifo(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup
    await line_setup(tb)
    await fifo_setup(tb, enable=True)
    await apb_write_byte(tb, REG_IER, IER_THR_EMPTY)

    # Transmit the message
    async def send_msg(tb, msg):
        # We send 16 characters at a time
        for chunk in split_into_chunks(msg):
            # Wait for interrupt
            if tb.uart_int.value == 0:
                await RisingEdge(tb.uart_int)
            # Verify that the interrupt is THR_EMPTY
            isr = await apb_read_byte(tb, REG_ISR)
            assert (isr & ISR_INT_MASK) == ISR_INT_THR_EMPTY;
            # Send 16 characters
            for c in chunk:
                await apb_write_byte(tb, REG_THR, ord(c))
            # Wait 1 cycle
            await ClockCycles(tb.clk, 1)

    cocotb.start_soon(send_msg(tb, MSG))

    # Read the message from UART
    tx_msg = await uart_read_str(tb, len(MSG))

    # Verify the message
    assert tx_msg == MSG


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_rx_int_fifo(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup
    await line_setup(tb)
    await fifo_setup(tb, enable=True, trigger_level=TriggerLevel.TRIG_14)
    await apb_write_byte(tb, REG_IER, IER_RX_DATA_READY)

    # Transmit the message
    cocotb.start_soon(uart_write_str(tb, MSG))

    # Read the message from register
    rx_msg = ""
    while True:
        # Wait for interrupt
        if tb.uart_int.value == 0:
            await RisingEdge(tb.uart_int)
        # Get the interrupt code
        isr = await apb_read_byte(tb, REG_ISR)
        int_code = isr & ISR_INT_MASK
        # Break if RX_TIMEOUT
        if int_code == ISR_INT_RX_TIMEOUT:
            break
        # Verify that the interrupt is RX_DATA_READY
        assert int_code == ISR_INT_RX_DATA_READY
        # Read 14 characters at a time
        for i in range(14):
            data = await apb_read_byte(tb, REG_RHR)
            rx_msg += chr(data)
        # If we have enough characters, we break
        if len(rx_msg) >= len(MSG):
            break
        # Wait 1 cycle
        await ClockCycles(tb.clk, 1)

    # Get all the remaining characters in FIFO
    rx_msg += await recv_str(tb, len(MSG), poll=False)

    # Verify the message
    assert rx_msg == MSG

