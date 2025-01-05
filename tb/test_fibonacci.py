import os, struct, cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


PROJ_DIR = os.environ["PROJ_DIR"]


async def reset_sequence(dut):
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)   # Reset for 5 cycles
    dut.rst_n.value = 1


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
            dut.u_ram.mem_array[i].value = word
            i += 1

    dut.u_ram._log.info(f"Loaded {i} instructions into the RAM")


@cocotb.test()
async def test_fibonacci(dut):
    # Start a clock
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Start the reset sequence
    cocotb.start_soon(reset_sequence(dut))

    # Backdoor some instructions
    load_bin_to_ram(dut, f"{PROJ_DIR}/build/asm/fibonacci.bin")

    # Wait for 1000 cycles
    await ClockCycles(dut.clk, 1000)

    # Check the final result is RAM (starting at 0x1000)
    start_word = 0x1000 // 4;
    with open(f"{PROJ_DIR}/asm/fibonacci.ref", "r") as file:
        for i, line in enumerate(file):
            # Convert to int
            number = int(line)
            # Compare with the value in RAM
            assert dut.u_ram.mem_array[start_word + i].value == number

