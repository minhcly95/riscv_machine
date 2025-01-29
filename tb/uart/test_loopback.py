import os, random, cocotb
from cocotb.triggers import *
from sequences import *
from uart_const import *


MSG = "Vivamus convallis enim a erat euismod, quis convallis sapien iaculis."


def split_into_chunks(s, chunk_size=16):
    return [s[i:i+chunk_size] for i in range(0, len(s), chunk_size)]


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_loopback(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup with loopback mode
    await line_setup(tb)
    await apb_write_byte(tb, REG_MCR, MCR_LOOPBACK)

    # Transmit the message
    cocotb.start_soon(send_str(tb, MSG))

    # Wait some cycles to prevent race conditions
    await ClockCycles(tb.clk, 50)

    # Read the message from register
    rx_msg = await recv_str(tb, len(MSG))

    # Verify the message
    assert rx_msg == MSG


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_loopback_int(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup with loopback mode
    await line_setup(tb)
    await apb_write_byte(tb, REG_IER, IER_THR_EMPTY | IER_RX_DATA_READY)
    await apb_write_byte(tb, REG_MCR, MCR_LOOPBACK)

    # Interrupt handling loop
    tx_ptr = 0
    rx_msg = ""
    while True:
        # Wait for interrupt
        if tb.uart_int.value == 0:
            await RisingEdge(tb.uart_int)
        # Check the interrupt type
        isr = await apb_read_byte(tb, REG_ISR)
        int_code = isr & ISR_INT_MASK
        # Read a character if RX_DATA_READY
        if int_code == ISR_INT_RX_DATA_READY:
            data = await apb_read_byte(tb, REG_RHR)
            rx_msg += chr(data)
            # Break if we received all the characters
            if len(rx_msg) >= len(MSG):
                break
        # Write a character if THR_EMPTY
        elif int_code == ISR_INT_THR_EMPTY:
            await apb_write_byte(tb, REG_THR, ord(MSG[tx_ptr]))
            tx_ptr += 1
            # Turn off the interrupt if done
            if tx_ptr >= len(MSG):
                await apb_write_byte(tb, REG_IER, IER_RX_DATA_READY)
        # Invalid interrupt
        else:
            assert False, "Unexpected interrupt"
        # Wait 1 cycle so that the interrupt is settled
        await ClockCycles(tb.clk, 1)

    # Verify the message
    assert rx_msg == MSG


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_loopback_int_fifo(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Register setup with loopback mode
    await line_setup(tb)
    await fifo_setup(tb, enable=True, trigger_level=TriggerLevel.TRIG_14)
    await apb_write_byte(tb, REG_IER, IER_THR_EMPTY | IER_RX_DATA_READY)
    await apb_write_byte(tb, REG_MCR, MCR_LOOPBACK)

    # Interrupt handling loop
    chunks = split_into_chunks(MSG, 16)
    tx_ptr = 0
    rx_msg = ""
    while True:
        # Wait for interrupt
        if tb.uart_int.value == 0:
            await RisingEdge(tb.uart_int)
        # Check the interrupt type
        isr = await apb_read_byte(tb, REG_ISR)
        int_code = isr & ISR_INT_MASK
        # Break on RX_TIMEOUT
        if int_code == ISR_INT_RX_TIMEOUT:
            break
        # Read 14 characters if RX_DATA_READY
        elif int_code == ISR_INT_RX_DATA_READY:
            for i in range(14):
                data = await apb_read_byte(tb, REG_RHR)
                rx_msg += chr(data)
            # Break if we received all the characters
            if len(rx_msg) >= len(MSG):
                break
        # Write a chunk if THR_EMPTY
        elif int_code == ISR_INT_THR_EMPTY:
            for c in chunks[tx_ptr]:
                await apb_write_byte(tb, REG_THR, ord(c))
            tx_ptr += 1
            # Turn off the interrupt if done
            if tx_ptr >= len(chunks):
                await apb_write_byte(tb, REG_IER, IER_RX_DATA_READY)
        # Invalid interrupt
        else:
            assert False, "Unexpected interrupt"
        # Wait 1 cycle so that the interrupt is settled
        await ClockCycles(tb.clk, 1)

    # Get all the remaining characters in FIFO
    rx_msg += await recv_str(tb, len(MSG), poll=False)

    # Verify the message
    assert rx_msg == MSG

