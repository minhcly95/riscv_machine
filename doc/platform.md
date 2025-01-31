# Platform Architecture

## Memory Map

The RISC-V core is connected to the RAM and the UART module via an APB fabric.
The memory map is embedded within this fabric. Each region in the map must be at least 4kB.
Here is the details of the regions:

| Region | Size  | Bit-width | Start         | End           | Permissions |
|--------|-------|-----------|---------------|---------------|-------------|
| RAM    | 2GB   | 31        | `0x00000000`  | `0x7fffffff`  | RWX         |
| UART   | 4kB   | 12        | `0x80000000`  | `0x80000fff`  | RW          |
| PLIC   | 64MB  | 26        | `0x90000000`  | `0x93ffffff`  | RW          |

## Interrupt Map

Every interrupt source is connected to the PLIC to be forwarded to the RISC-V core.
An ID is assigned to each source as follows:

| Source | Source ID |
|--------|-----------|
| UART   | 1         |

Each target (aka interrupt context) also has an ID, specified as follows:

| Target        | Target ID |
|---------------|-----------|
| Hart 0 M-mode | 0         |
| Hart 0 S-mode | 1         |
