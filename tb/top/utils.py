import os, struct
from cocotb.triggers import ClockCycles, RisingEdge, First

def get_proj_dir():
    return os.environ["PROJ_DIR"]

# Get the word in RAM at byte-address
def ram(dut, addr):
    return dut.u_ram.mem_array[addr >> 2]

# Load a binary file into the RAM of the machine
def load_bin_to_ram(dut, filename):
    i = 0
    with open(filename, "rb") as file:
        while True:
            # Read 4 bytes
            data = file.read(4)
            if len(data) < 4:
                break   # EOF
            # Convert to an integer
            word = struct.unpack('<i', data)[0]  # <i means little-endian
            # Backdoor the value
            ram(dut, i << 2).value = word
            i += 1

    dut.u_ram._log.info(f"Loaded {i} instructions into the RAM")

# Wait for either an ecall or timeout
async def wait_ecall(dut, max_clk):
    ecall   = RisingEdge(dut.u_core.u_stage_exec.ecall)
    timeout = ClockCycles(dut.clk, max_clk)
    await First(ecall, timeout)
