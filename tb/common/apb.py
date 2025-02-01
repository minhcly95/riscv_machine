from cocotb.triggers import *
from cocotb.clock import Clock
from uart import *


class Apb:
    def __init__(self, tb):
        self.tb  = tb
        self.clk = tb.clk


    async def _write(self, addr, wdata, wstrb, expect_err=False):
        tb = self.tb
        tb.psel.value = 1
        tb.pwrite.value = 1
        tb.paddr.value = addr
        tb.pwdata.value = wdata
        tb.pwstrb.value = wstrb
        await RisingEdge(tb.clk)
        tb.penable.value = 1
        while True:
            await RisingEdge(tb.clk)
            if tb.pready.value == 1:
                assert tb.pslverr.value == expect_err
                tb.psel.value = 0
                tb.penable.value = 0
                return


    async def _read(self, addr, expect_err=False):
        tb = self.tb
        tb.psel.value = 1
        tb.pwrite.value = 0
        tb.paddr.value = addr
        tb.pwstrb.value = 0
        await RisingEdge(tb.clk)
        tb.penable.value = 1
        while True:
            await RisingEdge(tb.clk)
            if tb.pready.value == 1:
                assert tb.pslverr.value == expect_err
                rdata = tb.prdata.value
                tb.psel.value = 0
                tb.penable.value = 0
                return rdata


    async def write(self, addr, wdata, expect_err=False):
        await self._write(addr, wdata, 0b1111, expect_err=expect_err)


    async def read(self, addr, expect_err=False):
        return await self._read(addr, expect_err=expect_err)


    async def write_byte(self, addr, wdata, expect_err=False):
        await self._write(
                addr,
                wdata << ((addr & 3) * 8),
                1 << (addr & 3),
                expect_err=expect_err)


    async def read_byte(self, addr, expect_err=False):
        rdata = await self._read(addr, expect_err=expect_err)
        return (rdata >> ((addr & 3) * 8)) & 0xff

