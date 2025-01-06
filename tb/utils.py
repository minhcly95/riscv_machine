import os, struct

def get_proj_dir():
    return os.environ["PROJ_DIR"]

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

