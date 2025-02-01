from cocotb.triggers import *
from cocotb.clock import Clock
from uart import *
from apb import Apb


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


class UartApb(Apb):
    # Register setup
    async def line_setup(self, baud_rate=BAUD_RATE, word_len=WordLength.WORD_8, parity_mode=ParityMode.NONE, stop_mode=StopMode.SINGLE):
        # Calculate the div_const
        div_const = round(CLK_FREQ / (16 * baud_rate))

        # Set the div_const
        await self.write_byte(REG_LCR, LCR_DLAB)   # Enable DLAB
        await self.write_byte(REG_DLL, div_const & 0xff)
        await self.write_byte(REG_DLM, (div_const >> 8) & 0xff)

        # Set LCR
        await self.write_byte(REG_LCR, parity_mode.value | stop_mode.value | word_len.value)


    async def fifo_setup(self, enable=False, trigger_level=TriggerLevel.TRIG_1):
        # Set FCR
        await self.write_byte(REG_FCR, trigger_level.value | (FCR_FIFO_ENABLE if enable else 0))


    # Write a character
    async def send_char(self, c):
        while True:
            lsr = await self.read_byte(REG_LSR)
            thr_empty = (lsr & LSR_THR_EMPTY) != 0
            if (thr_empty):
                await self.write_byte(REG_THR, ord(c))
                return
            else:
                await ClockCycles(self.clk, POLL_INTV)


    # Write a string
    async def send_str(self, s):
        for c in s:
            await self.send_char(c)


    # Read a character
    async def recv_char(self, poll=True):
        while True:
            lsr = await self.read_byte(REG_LSR)
            data_ready = (lsr & LSR_DATA_READY) != 0
            if (data_ready):
                data = await self.read_byte(REG_RHR)
                return chr(data)
            else:
                if not poll:
                    return None
                await ClockCycles(self.clk, POLL_INTV)


    # Read a string
    async def recv_str(self, num, poll=True):
        s = ""
        for i in range(num):
            c = await self.recv_char(poll=poll)
            if c == None:
                return s
            else:
                s += c
        return s

