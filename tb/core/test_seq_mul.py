import os, random, cocotb
import utils
from ram import Ram
from sequences import reset_sequence


PROJ_DIR    = utils.get_proj_dir()
SEQ_SIZE    = 1024
BASE_A      = 0x1000
BASE_B      = 0x2000
BASE_MUL    = 0x3000
BASE_MULH   = 0x4000
BASE_MULHSU = 0x5000
BASE_MULHU  = 0x6000


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_seq_mul(tb):
    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    ram = Ram(tb.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/asm/seq_mul.bin")

    # Backdoor the multiplicands
    all_ab = []
    for i in range(SEQ_SIZE):
        a = random.randint(0, 2**32 - 1)
        b = random.randint(0, 2**32 - 1)
        all_ab.append((a, b))
        ram.at(BASE_A + (i << 2)).value = a
        ram.at(BASE_B + (i << 2)).value = b

    # Wait for ecall
    await utils.wait_ecall(tb.u_core)

    # Check the products
    for (i, (a, b)) in enumerate(all_ab):
        sa = (a - 2**32) if a >= 2**31 else a
        sb = (b - 2**32) if b >= 2**31 else b
        muluu = a  * b
        mulsu = sa * b
        mulss = sa * sb
        assert ram.at(BASE_MUL    + (i << 2)).value                == muluu & 0xffffffff
        assert ram.at(BASE_MULH   + (i << 2)).value.signed_integer == mulss >> 32
        assert ram.at(BASE_MULHSU + (i << 2)).value.signed_integer == mulsu >> 32
        assert ram.at(BASE_MULHU  + (i << 2)).value                == muluu >> 32

