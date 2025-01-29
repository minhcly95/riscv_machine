import struct

class Ram():
    def __init__(self, obj):
        self.obj = obj

    # Get the word in RAM at byte-address
    def at(self, addr):
        return self.obj.mem_array[addr >> 2]

    # Load a binary file into the RAM of the machine
    def load_bin(self, filename):
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
                self.at(i << 2).value = word
                i += 1
        self.obj._log.info(f"Loaded {i << 2} bytes into the RAM")

