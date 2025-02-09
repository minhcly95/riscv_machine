import os, random, cocotb
import utils
from ram import Ram
from sequences import reset_sequence


PROJ_DIR  = utils.get_proj_dir()
ITERATION = 1024
BASE_ADDR = 0x1000
BASE_DATA = 0x2000
BASE_ROOT = 0x3000
BASE_PAGE = 0x800000

RAM_BASE  = 0x80000000
PAGE_SIZE = (1 << 12)

MASK_2    = (1 << 2) - 1
MASK_10   = (1 << 10) - 1
MASK_12   = (1 << 12) - 1
MASK_34   = (1 << 34) - 1

PTE_V     = (1 << 0)
PTE_R     = (1 << 1)
PTE_W     = (1 << 2)
PTE_A     = (1 << 6)
PTE_D     = (1 << 7)


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_translate_scatter(tb):
    # Start the reset sequence
    await reset_sequence(tb)

    # Backdoor some instructions
    ram = Ram(tb.u_ram)
    ram.load_bin(f"{PROJ_DIR}/build/asm/translate_scatter.bin")

    # Generate the virtual addresses.
    # VPN[1] ranges from 0 to 1023.
    # The rest is random, but must be 4B-aligned.
    vaddr = []
    for i in range(ITERATION):
        va = (i << 22) | random.randrange(1 << 22)
        va &= MASK_34 & ~MASK_2
        vaddr.append(va)

    # Generate 2k random non-repeating PPNs
    # from address 0x80800_000 to 0x80fff_fff.
    # 1k will be PPNs for second-level tables.
    # 1k will be for data.
    random_idx = list(range(2 * ITERATION))
    random.shuffle(random_idx)

    ppns       = [(BASE_PAGE >> 12) | i for i in random_idx]
    table_ppns = ppns[:ITERATION]
    data_ppns  = ppns[ITERATION:]

    # Generate random data
    data = [random.randrange(1 << 32) for _ in range(ITERATION)]

    # Prepare the root page table
    for i in range(ITERATION):
        ram.at(BASE_ROOT | (i << 2)).value = (RAM_BASE >> 2) | (table_ppns[i] << 10) | PTE_V;

    # Prepare the second-level page tables
    for i in range(ITERATION):
        vpn0 = (vaddr[i] >> 12) & MASK_10
        ram.at((table_ppns[i] << 12) | (vpn0 << 2)).value = (RAM_BASE >> 2) | (data_ppns[i] << 10) | PTE_V | PTE_R | PTE_W | PTE_A | PTE_D;

    # Prepare the data
    for i in range(ITERATION):
        ram.at(BASE_DATA + (i << 2)).value = data[i]

    # Backdoor the virtual addresses as input
    for i in range(ITERATION):
        ram.at(BASE_ADDR + (i << 2)).value = vaddr[i]

    # Wait for ecall
    await utils.wait_ecall(tb.u_core)

    # Check the outputs
    for i in range(ITERATION):
        assert ram.at((data_ppns[i] << 12) | (vaddr[i] & MASK_12)).value == data[i]

