import os, random, cocotb
from cocotb.triggers import *
from sequences import *


TGT_N       = 1   # Only need 1 target for this test
CLEAR_TIME  = 50


# We prepare sources with 2 pending interrupts each
# We only claim each source once
# After a claim, pending should be 0 until complete
# We use priority to enable the interrupt, which does not affect the pending status
@cocotb.test()
async def test_pending(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=0) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources) for j in range(TGT_N)]
    target = targets[0]

    # Register setup
    for src in sources.values():
        await src.setup()

    for tgt in targets:
        await tgt.setup()

    # Add 2 interrupts for each source
    for src in sources.values():
        src.add(2)

    await ClockCycles(tb.clk, 10)

    # We enable one source every loop
    for src in sources.values():
        # Enable the source
        src.priority = 1
        await src.setup()

        # Claim an interrupt
        src_id = await apb.claim(target.id)
        
        # The claimed ID must be the enabled source
        assert src_id == src.id

        # All interrupts must be still pending, except for the claimed one
        for other in sources.values():
            pending = await apb.is_int_pending(other.id)
            assert pending == (other != src)
        
        # Wait for some time before clearing the interrupt
        await ClockCycles(tb.clk, CLEAR_TIME)
        src.clear(target)
        
        # Complete the interrupt
        await apb.complete(target.id, src.id)

        # Check the pending status again
        # This time, all sources should be pending
        for other in sources.values():
            pending = await apb.is_int_pending(other.id)
            assert pending

        # Disable the source
        src.priority = 0
        await src.setup()


# If tgt_id of the complete does not match with the claim for a given source,
# the complete is ignored and the source is still gated.
@cocotb.test()
async def test_wrong_complete(tb):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources and targets
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb, priority=0) for i in range(SRC_N)}

    targets = [IntTarget(j, tb.int_tgt[j], apb, sources) for j in range(TGT_N)]
    target = targets[0]

    # Register setup
    for src in sources.values():
        await src.setup()

    for tgt in targets:
        await tgt.setup()

    # Add 2 interrupts for each source
    for src in sources.values():
        src.add(2)

    await ClockCycles(tb.clk, 10)

    # We enable one source every loop
    for src in sources.values():
        # Enable the source
        src.priority = 1
        await src.setup()

        # Claim an interrupt
        src_id = await apb.claim(target.id)
        
        # The claimed ID must be the enabled source
        assert src_id == src.id

        # The claimed source should not be pending
        pending = await apb.is_int_pending(src.id)
        assert not pending
        
        # Wait for some time before clearing the interrupt
        await ClockCycles(tb.clk, CLEAR_TIME)
        src.clear(target)
        
        # Complete the interrupt with a wrong tgt_id
        await apb.complete(target.id + 1, src.id)

        # Check the pending status again
        # The claimed source should still not be pending
        pending = await apb.is_int_pending(src.id)
        assert not pending

    # We cannot claim any interrupt (all are claimed)
    src_id = await apb.claim(target.id)
    assert src_id == 0

    # Verify that every source is not pending
    for src in sources.values():
        pending = await apb.is_int_pending(src.id)
        assert not pending

