import os, random, cocotb
from cocotb.triggers import *
from sequences import *

SRC_N       = 8
TGT_N       = 1   # Only need 1 target for this test
MAX_SIM_CLK = 3000


# We prepare sources with different priority
# The target must clear the one with higher priority first
@cocotb.test()
async def test_prio_order(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=i+1) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, MAX_SIM_CLK)

    # Verify that all interrupts are handled
    for src in sources.values():
        assert src.pending == 0

    # The target must clear the ones with higher priorities first
    assert [src.id for src in targets[0].history] == [8, 7, 6, 5, 4, 3, 2, 1]


# We prepare sources with same priority
# The target must clear the one with lower ID first
@cocotb.test()
async def test_id_order(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=1) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, MAX_SIM_CLK)

    # Verify that all interrupts are handled
    for src in sources.values():
        assert src.pending == 0

    # The target must clear the ones with lower ID first
    assert [src.id for src in targets[0].history] == [1, 2, 3, 4, 5, 6, 7, 8]


# We prepare some sources with same priority
# High priority should take precedence over lower ID
@cocotb.test()
async def test_mixed_order(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=(i%4)+1) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, MAX_SIM_CLK)

    # Verify that all interrupts are handled
    for src in sources.values():
        assert src.pending == 0

    # The target must clear the sources in order
    assert [src.id for src in targets[0].history] == [4, 8, 3, 7, 2, 6, 1, 5]

