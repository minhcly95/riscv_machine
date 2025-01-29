import os
from cocotb.triggers import ClockCycles, RisingEdge, First


def get_proj_dir():
    return os.environ["PROJ_DIR"]


# Wait for either an ecall or timeout
async def wait_ecall(tb, max_clk):
    ecall   = RisingEdge(tb.u_core.u_stage_exec.ecall)
    timeout = ClockCycles(tb.clk, max_clk)
    await First(ecall, timeout)

