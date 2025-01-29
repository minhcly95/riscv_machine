import os, random, cocotb
import utils
from ram import Ram
from sequences import reset_sequence


PROJ_DIR  = utils.get_proj_dir()
MAX_CLK   = 100000
SEQ_SIZE  = 1024
BASE_A    = 0x1000
BASE_B    = 0x2000
BASE_DIV  = 0x3000
BASE_DIVU = 0x4000
BASE_REM  = 0x5000
BASE_REMU = 0x6000


@cocotb.test()
async def test_seq_div(tb):
    # Start the reset sequence
    cocotb.start_soon(reset_sequence(tb))

    # Backdoor some instructions
    ram = Ram(tb.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/asm/seq_div.bin")

    # Backdoor the parameters
    all_ab = []
    for i in range(SEQ_SIZE):
        a = random.randint(0, 2**32 - 1)
        b = random.randint(0, 2**32 - 1)
        all_ab.append((a, b))
        ram.at(BASE_A + (i << 2)).value = a
        ram.at(BASE_B + (i << 2)).value = b

    # Wait for ecall or max cycles
    await utils.wait_ecall(tb, MAX_CLK)

    # Check the results
    for (i, (a, b)) in enumerate(all_ab):
        sa = (a - 2**32) if a >= 2**31 else a
        sb = (b - 2**32) if b >= 2**31 else b
        div,  rem  = sdiv_model(sa, sb)
        divu, remu = udiv_model(a, b)
        assert ram.at(BASE_DIV  + (i << 2)).value.signed_integer == div
        assert ram.at(BASE_DIVU + (i << 2)).value                == divu
        assert ram.at(BASE_REM  + (i << 2)).value.signed_integer == rem
        assert ram.at(BASE_REMU + (i << 2)).value                == remu


def udiv_model(a, b):
    if b == 0:
        return 2**32 - 1, a
    else:
        return a // b, a % b


def sdiv_model(a, b):
    if b == 0:
        return -1, a
    elif a == -2**31 and b == -1:
        return a, 0
    else:
        q, r = a // b, a % b
        # In RISC-V, r must match the sign of a.
        # However, in Python, r matches the sign of b instead.
        # So we need to do sign conversion for r.
        if (a > 0 and r < 0) or (a < 0 and r > 0):
            r -= b
            q += 1
        return q, r

