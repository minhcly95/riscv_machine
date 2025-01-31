import os
from cocotb.triggers import RisingEdge


def get_proj_dir():
    return os.environ["PROJ_DIR"]


async def wait_ecall(core):
    await RisingEdge(core.u_stage_exec.ecall)

