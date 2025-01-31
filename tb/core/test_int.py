import os, random, cocotb
import utils
from cocotb.triggers import ClockCycles
from ram import Ram
from sequences import reset_sequence


PROJ_DIR    = utils.get_proj_dir()
EMIT_CLK    = 500
TIMEOUT_CLK = 1000

MIE_ADDR    = 0x1000
MEIE_ADDR   = 0x1004
U_MODE_ADDR = 0x1008
RESULT_ADDR = 0x1010
MIP_ADDR    = 0x1014

INT_NONE    = 0x80000000
INT_M_EXT   = 0x80000000 + 11
MIP_NONE    = 0
MIP_M_EXT   = (1 << 11)


async def test_int_base(tb, mie=True, meie=True, u_mode=False, emit_int=True, expect_int=True):
    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    ram = Ram(tb.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/asm/core_int.bin")

    # Set some parameters
    ram.at(MIE_ADDR).value    = mie
    ram.at(MEIE_ADDR).value   = meie
    ram.at(U_MODE_ADDR).value = u_mode

    # Produce an interrupt
    await ClockCycles(tb.clk, EMIT_CLK)

    if emit_int:
        tb.int_m_ext.value = 1

    await ClockCycles(tb.clk, TIMEOUT_CLK - EMIT_CLK)

    # Verify the expected code
    assert ram.at(RESULT_ADDR).value == (INT_M_EXT if expect_int else INT_NONE)

    # Verify the value of MIP (depends on emit_int)
    assert ram.at(MIP_ADDR).value == (MIP_M_EXT if emit_int else MIP_NONE)


@cocotb.test()
async def test_int_normal(tb):
    await test_int_base(tb, mie=True, meie=True, u_mode=False, emit_int=True, expect_int=True)


@cocotb.test()
async def test_int_mie_off(tb):
    await test_int_base(tb, mie=False, meie=True, u_mode=False, emit_int=True, expect_int=False)


@cocotb.test()
async def test_int_meie_off(tb):
    await test_int_base(tb, mie=True, meie=False, u_mode=False, emit_int=True, expect_int=False)


@cocotb.test()
async def test_int_umode(tb):
    await test_int_base(tb, mie=False, meie=True, u_mode=True, emit_int=True, expect_int=True)


@cocotb.test()
async def test_int_umode_meie_off(tb):
    await test_int_base(tb, mie=False, meie=False, u_mode=True, emit_int=True, expect_int=False)


@cocotb.test()
async def test_int_none(tb):
    await test_int_base(tb, mie=True, meie=True, u_mode=False, emit_int=False, expect_int=False)


@cocotb.test()
async def test_int_none_umode(tb):
    await test_int_base(tb, mie=True, meie=True, u_mode=True, emit_int=False, expect_int=False)

