import random
from cocotb.triggers import *
from cocotb.clock import Clock
from apb import Apb


CLK_FREQ  = 1e6
SRC_N     = 8
TGT_N     = 8
PRIO_W    = 4


# Reset
async def reset_sequence(tb):
    clk_period = round(1 / CLK_FREQ, 9)

    tb.rst_n.value   = 0
    tb.int_src.value = [0 for _ in range(SRC_N)]
    tb.psel.value    = 0
    tb.penable.value = 0

    await cocotb.start(Clock(tb.clk, clk_period, 'sec').start())
    await ClockCycles(tb.clk, 5)   # Reset for 5 cycles
    tb.rst_n.value = 1


class PlicApb(Apb):
    async def set_int_prio(self, src_id, value):
        await self.write(0x0000000 + 4 * src_id, value)

    async def is_int_pending(self, src_id):
        rdata = await self.read(0x0001000)
        return ((rdata >> src_id) & 1) != 0

    async def set_int_enable(self, tgt_id, value):
        await self.write(0x0002000 + 0x80 * tgt_id, value)

    async def set_threshold(self, tgt_id, value):
        await self.write(0x0200000 + 0x1000 * tgt_id, value)

    async def claim(self, tgt_id):
        return await self.read(0x0200004 + 0x1000 * tgt_id)

    async def complete(self, tgt_id, src_id):
        return await self.write(0x0200004 + 0x1000 * tgt_id, src_id)


class IntSource:
    def __init__(self, id, int_src, apb, priority=1):
        self.id       = id
        self.int_src  = int_src
        self.apb      = apb
        self.priority = priority
        self.pending  = 0
        self.history  = []

    # Setup the source
    async def setup(self, set_priority=True):
        if set_priority:
            await self.apb.set_int_prio(self.id, self.priority)

    # Add a pending interrupt
    def add(self, num_int=1):
        self.pending += num_int
        if self.pending > 0:
            self.int_src.value = 1

    # Clear a pending interrupt
    def clear(self, target):
        assert self.pending > 0
        self.history.append(target)
        self.pending -= 1
        if self.pending == 0:
            self.int_src.value = 0

    # Start the source's loop
    async def start(self, num_int, max_interval=300):
        for _ in range(num_int):
            # Wait for some time
            wait_time = random.randint(0, max_interval)
            if wait_time > 0:
                await ClockCycles(self.apb.clk, wait_time)
            # Add an interrupt
            self.add()


class IntTarget:
    def __init__(self, id, int_tgt, apb, src_dict, threshold=0):
        self.id        = id
        self.int_tgt   = int_tgt
        self.apb       = apb
        self.src_dict  = src_dict
        self.threshold = threshold
        self.history   = []

    # Setup the target
    async def setup(self, enable_int=True, set_threshold=True):
        if enable_int:
            # Build a bitmap of keys in src_dict
            enable_map = 0
            for src_id in self.src_dict.keys():
                enable_map |= 1 << src_id;
            # Set the bitmap
            await self.apb.set_int_enable(self.id, enable_map)
        if set_threshold:
            await self.apb.set_threshold(self.id, self.threshold)

    # Start the target's handling loop
    async def start(self, wait_int=True, min_time=50, max_time=150, max_rest=100):
        while True:
            # For a more interesting simulation,
            # a target may rest between loops
            rest_time = random.randint(0, max_rest)
            if rest_time > 0:
                await ClockCycles(self.apb.clk, rest_time)

            # Wait for notification
            if wait_int:
                while self.int_tgt.value == 0:
                    await ClockCycles(self.apb.clk, 1)

            # Claim an interrupt
            src_id = await self.apb.claim(self.id)
            
            # Go back to wait if there is no interrupt
            if src_id == 0:
                continue

            # The claimed ID must be present in src_dict
            assert src_id in self.src_dict
            source = self.src_dict[src_id]
            
            # Wait for some time before clearing the interrupt
            clear_time = random.randint(min_time, max_time)
            await ClockCycles(self.apb.clk, clear_time)
            self.history.append(source)
            source.clear(self)

            self.int_tgt._log.debug(f"Target {self.id} cleared source {source.id}")
            
            # Complete the interrupt
            await self.apb.complete(self.id, src_id)


async def run_sim(tb, sources, targets, sim_clk, add_multi=None, run_target=True, wait_int=True):
    # Register setup
    for src in sources.values():
        await src.setup()

    for tgt in targets:
        await tgt.setup()

    # Start the processes
    for src in sources.values():
        if add_multi != None:
            cocotb.start_soon(src.start(add_multi))
        else:
            src.add()

    if run_target:
        for tgt in targets:
            cocotb.start_soon(tgt.start(wait_int=wait_int))

    # Wait for some time
    await ClockCycles(tb.clk, sim_clk)

