import os, random, cocotb
from cocotb.triggers import *
from sequences import *


NUM_INT_PER_SRC   = 100
MIN_CLEAR_PER_TGT = 90
MAX_SIM_CLK       = 30000

MAX_THRESHOLD = (1 << 32) - 1


# Normal claim/complete sequence
async def test_normal_base(tb, poll=False):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources, threshold=MAX_THRESHOLD if poll else 0) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, MAX_SIM_CLK, add_multi=NUM_INT_PER_SRC, wait_int=not poll)

    # Verify that all interrupts are handled
    for src in sources.values():
        assert src.pending == 0

    # Verify that the total count matched
    assert sum(len(tgt.history) for tgt in targets) == SRC_N * NUM_INT_PER_SRC

    # Each target should have a fair share of interrupts
    for tgt in targets:
        assert len(tgt.history) >= MIN_CLEAR_PER_TGT


@cocotb.test()
async def test_normal_notify(tb):
    await test_normal_base(tb, poll=False)


@cocotb.test()
async def test_normal_poll(tb):
    await test_normal_base(tb, poll=True)

