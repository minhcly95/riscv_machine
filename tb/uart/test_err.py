import os, random, cocotb
from cocotb.regression import TestFactory
from cocotb.triggers import *
from sequences import *
from uart import *


async def wait_for_line_stat(tb, apb):
    # Wait for interrupt
    if tb.uart_int.value == 0:
        await RisingEdge(tb.uart_int)

    # Verify that the interrupt is RX_LINE_STAT
    isr = await apb.read_byte(REG_ISR)
    int_code = isr & ISR_INT_MASK
    assert int_code == ISR_INT_RX_LINE_STAT


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_overrun_err(tb, fifo_enable=False):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup()
    if fifo_enable:
        await apb.fifo_setup(enable=True)
    await apb.write_byte(REG_IER, IER_RX_LINE_STAT)

    # Transmit 2 characters with no read (17 if FIFO is enabled)
    async def send_data():
        uart = Uart(tb)
        for _ in range(17 if fifo_enable else 2):
            await uart.write(random.randint(0, 255))

    cocotb.start_soon(send_data())

    # Wait for RX_LINE_STAT interrupt
    await wait_for_line_stat(tb, apb)

    # Read LSR to verify that there is an overrun error
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_OVERRUN_ERR) != 0

    # Verify that the interrupt is cleared
    await ClockCycles(tb.clk, 1)
    assert tb.uart_int.value == 0


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_overrun_err_fifo(tb):
    await test_overrun_err(tb, fifo_enable=True)


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_parity_err(tb, parity_mode=ParityMode.ODD):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup(parity_mode=parity_mode)
    await apb.write_byte(REG_IER, IER_RX_LINE_STAT)

    # Transmit the message
    data = random.randint(0, 255)
    uart = Uart(tb, parity_mode=parity_mode)
    cocotb.start_soon(uart.write(data, flip_parity=True))

    # Wait for RX_LINE_STAT interrupt
    await wait_for_line_stat(tb, apb)

    # Read LSR to verify that there is a parity error
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_PARITY_ERR) != 0

    # Verify that the interrupt is cleared
    await ClockCycles(tb.clk, 1)
    assert tb.uart_int.value == 0


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_frame_err(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup()
    await apb.write_byte(REG_IER, IER_RX_LINE_STAT)

    # Transmit the message
    data = random.randint(0, 255)
    uart = Uart(tb)
    cocotb.start_soon(uart.write(data, flip_stop=True))

    # Wait for RX_LINE_STAT interrupt
    await wait_for_line_stat(tb, apb)

    # Read LSR to verify that there is a framing error
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_FRAME_ERR) != 0

    # Verify that the interrupt is cleared
    await ClockCycles(tb.clk, 1)
    assert tb.uart_int.value == 0


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_break_int(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup()
    await apb.write_byte(REG_IER, IER_RX_LINE_STAT)

    # Pull RX low (after some delay)
    await ClockCycles(tb.clk, 100)
    tb.rx.value = 0

    # Wait for RX_LINE_STAT interrupt
    await wait_for_line_stat(tb, apb)

    # Read LSR to verify that there is a break interrupt
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_BREAK_INT) != 0

    # Verify that the interrupt is cleared
    await ClockCycles(tb.clk, 1)
    assert tb.uart_int.value == 0


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_fifo_err(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = UartApb(tb)

    # Register setup
    await apb.line_setup()
    await apb.fifo_setup(enable=True)
    await apb.write_byte(REG_IER, IER_RX_DATA_READY)

    # Transmit the message
    data = random.randint(0, 255)
    uart = Uart(tb)
    cocotb.start_soon(uart.write(data, flip_stop=True))

    # Wait for interrupt
    if tb.uart_int.value == 0:
        await RisingEdge(tb.uart_int)

    # Read LSR to verify that there is a FIFO error
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_FIFO_ERR) != 0

    # Reading LSR should not clear the FIFO error
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_FIFO_ERR) != 0

    # Pop the RHR (and clear the FIFO error)
    await apb.read_byte(REG_RHR)

    # The FIFO error should be cleared now
    lsr = await apb.read_byte(REG_LSR)
    assert (lsr & LSR_FIFO_ERR) == 0


tf = TestFactory(test_function=test_parity_err)
tf.add_option("parity_mode", [ParityMode.EVEN, ParityMode.FORCE1, ParityMode.FORCE0])
tf.generate_tests()

