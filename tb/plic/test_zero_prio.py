import os, random, cocotb
from cocotb.triggers import *
from sequences import *


MAX_SIM_CLK = 1000


# Zero input priorities -> no interrupt at all
@cocotb.test()
async def test_zero_prio(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=0) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, MAX_SIM_CLK)

    # Verify that no interrupts are handled
    for src in sources.values():
        assert src.pending == 1

