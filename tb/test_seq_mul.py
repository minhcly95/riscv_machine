import os, random, cocotb
import utils
from sequences import reset_sequence
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, First


PROJ_DIR    = utils.get_proj_dir()
MAX_CLK     = 100000
SEQ_SIZE    = 1024
BASE_A      = 0x1000
BASE_B      = 0x2000
BASE_MUL    = 0x3000
BASE_MULH   = 0x4000
BASE_MULHSU = 0x5000
BASE_MULHU  = 0x6000


@cocotb.test()
async def test_seq_mul(dut):
    # Start a clock
    cocotb.start_soon(Clock(dut.clk, 1, "ns").start())

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(dut))

    # Backdoor some instructions
    utils.load_bin_to_ram(dut, f"{PROJ_DIR}/build/asm/seq_mul.bin")

    # Backdoor the multiplicands
    all_ab = []
    for i in range(SEQ_SIZE):
        a = random.randint(0, 2**32 - 1)
        b = random.randint(0, 2**32 - 1)
        all_ab.append((a, b))
        utils.ram(dut, BASE_A + (i << 2)).value = a
        utils.ram(dut, BASE_B + (i << 2)).value = b

    # Wait for ecall or max cycles
    ecall   = RisingEdge(dut.u_core.u_stage_exec.ecall)
    max_clk = ClockCycles(dut.clk, MAX_CLK)
    await First(ecall, max_clk)

    # Check the products
    for (i, (a, b)) in enumerate(all_ab):
        sa = (a - 2**32) if a >= 2**31 else a
        sb = (b - 2**32) if b >= 2**31 else b
        muluu = a  * b
        mulsu = sa * b
        mulss = sa * sb
        assert utils.ram(dut, BASE_MUL    + (i << 2)).value                == muluu & 0xffffffff
        assert utils.ram(dut, BASE_MULH   + (i << 2)).value.signed_integer == mulss >> 32
        assert utils.ram(dut, BASE_MULHSU + (i << 2)).value.signed_integer == mulsu >> 32
        assert utils.ram(dut, BASE_MULHU  + (i << 2)).value                == muluu >> 32

