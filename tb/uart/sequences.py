from cocotb.triggers import *
from cocotb.clock import Clock
from uart_const import *


BAUD_RATE = 115200
CLK_FREQ  = BAUD_RATE * 16
POLL_INTV = 100     # Poll interval to check for status (in clk)


# Reset
async def reset_sequence(tb):
    clk_period = round(1 / CLK_FREQ, 9)

    tb.rst_n.value   = 0
    tb.rx.value      = 1
    tb.psel.value    = 0
    tb.penable.value = 0

    await cocotb.start(Clock(tb.clk, clk_period, 'sec').start())
    await ClockCycles(tb.clk, 5)   # Reset for 5 cycles
    tb.rst_n.value = 1


# APB write
async def apb_write_byte(tb, addr, wdata):
    tb.psel.value = 1
    tb.pwrite.value = 1
    tb.paddr.value = addr
    tb.pwdata.value = wdata << ((addr & 3) * 8)
    tb.pwstrb.value = 1 << (addr & 3)
    await RisingEdge(tb.clk)
    tb.penable.value = 1
    while True:
        await RisingEdge(tb.clk)
        if tb.pready.value == 1:
            assert tb.pslverr.value == 0
            tb.psel.value = 0
            tb.penable.value = 0
            return


# APB read
async def apb_read_byte(tb, addr):
    tb.psel.value = 1
    tb.pwrite.value = 0
    tb.paddr.value = addr
    tb.pwstrb.value = 0
    await RisingEdge(tb.clk)
    tb.penable.value = 1
    while True:
        await RisingEdge(tb.clk)
        if tb.pready.value == 1:
            assert tb.pslverr.value == 0
            rdata = (tb.prdata.value >> ((addr & 3) * 8)) & 0xff
            tb.psel.value = 0
            tb.penable.value = 0
            return rdata


# UART read
async def uart_read(tb, baud_rate=BAUD_RATE, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE):
    char_time = round(1 / baud_rate, 9)
    # Wait for start bit
    await FallingEdge(tb.tx)
    # Align to the center of a character
    await Timer(char_time / 2, 'sec')
    # Verify the start bit
    assert tb.tx.value == 0, "Start bit is not zero"
    # Read the data bits
    data = 0
    for i in range(word_len.length()):
        await Timer(char_time, 'sec')
        data |= (tb.tx.value << i)
    # Verify the parity bit
    parity_gen = parity_mode.gen(data)
    if parity_gen != None:
        await Timer(char_time, 'sec')
        assert tb.tx.value == parity_gen, "Parity does not match"
    # Verify the stop bit
    await Timer(char_time, 'sec')
    assert tb.tx.value == 1, "Stop bit is not one"
    # Return the data
    return data


async def uart_read_str(tb, num, baud_rate=BAUD_RATE, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE):
    s = ""
    for i in range(num):
        data = await uart_read(tb, baud_rate=baud_rate, word_len=word_len, parity_mode=parity_mode)
        s += chr(data)
    return s


# UART write
async def uart_write(tb, data,
                     baud_rate=BAUD_RATE,
                     word_len=WordLength.WORD_8,
                     parity_mode=ParityMode.NONE,
                     flip_parity=False,
                     flip_stop=False):
    char_time = round(1 / baud_rate, 9)
    # Start bit
    tb.rx.value = 0
    await Timer(char_time, 'sec')
    # Data bits
    for i in range(word_len.length()):
        tb.rx.value = (data >> i) & 1;
        await Timer(char_time, 'sec')
    # Parity bit
    parity_gen = parity_mode.gen(data)
    if parity_gen != None:
        tb.rx.value = parity_gen ^ flip_parity
        await Timer(char_time, 'sec')
    # Stop bit
    tb.rx.value = 1 if not flip_stop else 0
    await Timer(char_time, 'sec')


async def uart_write_str(tb, s, baud_rate=BAUD_RATE, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE):
    for c in s:
        await uart_write(tb, ord(c), baud_rate=baud_rate, word_len=word_len, parity_mode=parity_mode)


# Register setup
async def line_setup(tb, baud_rate=BAUD_RATE, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE, stop_mode=StopMode.SINGLE):
    # Calculate the div_const
    div_const = round(CLK_FREQ / (16 * baud_rate))

    # Set the div_const
    await apb_write_byte(tb, REG_LCR, LCR_DLAB)   # Enable DLAB
    await apb_write_byte(tb, REG_DLL, div_const & 0xff)
    await apb_write_byte(tb, REG_DLM, (div_const >> 8) & 0xff)

    # Set LCR
    await apb_write_byte(tb, REG_LCR, parity_mode.value | stop_mode.value | word_len.value)


async def fifo_setup(tb, enable=False, trigger_level=TriggerLevel.TRIG_1):
    # Set FCR
    await apb_write_byte(tb, REG_FCR, trigger_level.value | (FCR_FIFO_ENABLE if enable else 0))


# Write a character
async def send_char(tb, c):
    while True:
        lsr = await apb_read_byte(tb, REG_LSR)
        thr_empty = (lsr & LSR_THR_EMPTY) != 0
        if (thr_empty):
            await apb_write_byte(tb, REG_THR, ord(c))
            return
        else:
            await ClockCycles(tb.clk, POLL_INTV)


# Write a string
async def send_str(tb, s):
    for c in s:
        await send_char(tb, c)


# Read a character
async def recv_char(tb, poll=True):
    while True:
        lsr = await apb_read_byte(tb, REG_LSR)
        data_ready = (lsr & LSR_DATA_READY) != 0
        if (data_ready):
            data = await apb_read_byte(tb, REG_RHR)
            return chr(data)
        else:
            if not poll:
                return None
            await ClockCycles(tb.clk, POLL_INTV)


# Read a string
async def recv_str(tb, num, poll=True):
    s = ""
    for i in range(num):
        c = await recv_char(tb, poll=poll)
        if c == None:
            return s
        else:
            s += c
    return s

