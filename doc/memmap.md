# Memory Map

The RISC-V core is connected to the RAM and the UART module via an APB fabric.
The memory map is embedded within this fabric. Each region in the map must be at least 4kB.
Here is the details of the regions:

| Region | Size  | Bit-width | Start         | End           | Permissions |
|--------|-------|-----------|---------------|---------------|-------------|
| RAM    | 2GB   | 31        | `0x00000000`  | `0x7fffffff`  | `RWX`       |
| UART   | 4kB   | 12        | `0x80000000`  | `0x80000fff`  | `RW`        |

