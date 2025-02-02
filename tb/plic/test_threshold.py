import os, random, cocotb
from cocotb.triggers import *
from sequences import *


MAX_THRESHOLD = (1 << 32) - 1


# Max threshold -> no notification
@cocotb.test()
async def test_threshold_max(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources, threshold=MAX_THRESHOLD) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, 10, run_target=False)

    # Verify that no notification is produced
    for tgt in targets:
        assert tgt.int_tgt.value == 0


# We setup sources with different priorities and targets with different thresholds.
# We enable the sources gradually, lower priority first.
# Then, we check if the threshold works correctly.
@cocotb.test()
async def test_threshold_scan(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=i+1) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources, threshold=j) for j in range(TGT_N)]

    # Register setup
    for src in sources.values():
        await src.setup()

    for tgt in targets:
        await tgt.setup()

    await ClockCycles(tb.clk, 10)

    # Check that there is no notification at first
    for tgt in targets:
        assert tgt.int_tgt.value == 0

    # We enable the sources gradually
    for i in range(1, SRC_N+1):
        # Enable the source
        src = sources[i]
        src.add()

        await ClockCycles(tb.clk, 10)

        # Targets before i-1 should have notifications
        # Targets after i should have no notifications
        for tgt in targets:
            assert tgt.int_tgt.value == (tgt.id < i)

        await ClockCycles(tb.clk, 10)


