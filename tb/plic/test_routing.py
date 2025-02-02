import os, random, cocotb
from cocotb.triggers import *
from sequences import *


NUM_INT_PER_SRC = 100
MAX_SIM_CLK     = 30000


# First entry of routes is the list of src_id for first target, and so on
async def test_routing_base(tb, routes, poll=False):
    # Start the reset sequence
    await reset_sequence(tb)
    apb = PlicApb(tb)

    # Construct sources
    sources = {i+1: IntSource(i+1, tb.int_src[i], apb) for i in range(SRC_N)}

    # Construct custom source sets for each target
    tb._log.info(f"Routes: {routes}")
    routed_src = [{id: sources[id] for id in ids} for ids in routes]

    # Construct targets with routing
    targets = [IntTarget(j, tb.int_tgt[j], apb, routed_src[j]) for j in range(TGT_N)]

    # Start the sim
    await run_sim(tb, sources, targets, MAX_SIM_CLK, add_multi=NUM_INT_PER_SRC)

    # Verify that all interrupts are handled
    for src in sources.values():
        assert src.pending == 0

    # Verify that the total count matched
    assert sum(len(tgt.history) for tgt in targets) == SRC_N * NUM_INT_PER_SRC


@cocotb.test()
async def test_routing_identity(tb):
    # Map src i to tgt i-1
    # In other words, tgt j to src j+1
    routes = [[j+1] for j in range(TGT_N)]
    await test_routing_base(tb, routes)


@cocotb.test()
async def test_routing_random(tb):
    # We randomly select 4 targets to handle a source
    routes = [[] for _ in range(TGT_N)]
    for i in range(1, SRC_N+1):
        tgts = random.sample(range(TGT_N), 4)
        for j in tgts:
            routes[j].append(i)
    await test_routing_base(tb, routes)

