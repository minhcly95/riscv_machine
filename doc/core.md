# RISC-V Core

## Architecture
The RISC-V core consists of 3 stages:
- `FETCH`: manages the PC and fetches instructions from memory.
- `EXEC`: decodes and executes the instructions (partially for `LOAD` and `STORE`).
- `MEM`: read and write data from/to memory (for `LOAD` and `STORE`).

![](images/block-diagram.png)

These 3 stages are executed in series without pipelining.
The Controller handles the switching of the 3 stages.

The `FETCH` and `MEM` stages have access to the Memory Interface for their functions.
Only the `EXEC` stage can read the Register File,
but the data from all 3 stages can be written back to the Register File, selected using the Write-back Mux.

## Block Functions
### Controller
The Controller is a state machine that gives control to each of the 3 stages in the correct order: `FETCH`, `EXEC`, `MEM`.

The `MEM` stage is not needed if the instruction is not a `MemOp` (memory operation, i.e. a `LOAD` or a `STORE`).
This condition is conveyed by the `EXEC` stage during its turn.

The Controller also controls when the Register File is written.

### `FETCH` Stage
The `FETCH` stage holds the Program Counter (PC).
At its turn, it sends a request to the Memory Interface to fetch a new instruction.
Once the instruction has been fetched, it adds 4 to the PC and yields control to the `EXEC` stage.

The `FETCH` stage shall update its PC if there is a request from the `EXEC` stage in case of the `JUMP` and `BRANCH` commands.

The `FETCH` stage outputs its PC to be written back to the Register File for the `JAL` and `JALR` commands.

### `EXEC` Stage
The `EXEC` stage decodes the instructions using the [Decoder](#decoder), accesses the Register File to obtain the operand values,
and executes the instructions using its ALU.
It accomplishes all of its tasks in only 1 cycle (ignore reality for now).

If a command is neither `LOAD` nor `STORE`, the `EXEC` stage passes the control back to the `FETCH` stage to start a new command.
Otherwise, the `EXEC` stage proceeds to the `MEM` stage to complete the memory operation.

The `EXEC` stage may write a new PC to the `FETCH` stage in case of the `JUMP` and `BRANCH` commands.

The `EXEC` stage is also in charge of selecting the input of the Write-back Mux.
However, when to update the Register File is decided by the Controller.

### `MEM` Stage
The `MEM` stage sends a request to the Memory Interface to complete memory operations.
The `MEM` stage is not always executed, only during `LOAD` and `STORE` operations.

The address is provided by the `EXEC` stage.
In case of a `STORE`, the `WData` is also given by the `EXEC` stage.
In case of a `LOAD`, the `RData` is written back to the Register File.

The `MEM` stage also handles bit-extension for byte and half-word accesses.

Misaligned access is not allowed and will raise an exception.

### Register File
The Register File is an array of 32 architectural registers, with 2 read ports and 1 write port.
The read ports are combinational and are accessed only by the `EXEC` stage.
The write ports are controlled by the Controller, which is enabled either at the `EXEC` stage
or at the end of `MEM` stage depending on the commands.

### Memory Interface
The Memory Interface connects the core to the RAM of the machine via APB bus.
All addresses go in and out of the memory interface must be aligned with the bus (4B-aligned).
For narrow write transfer, write strobes should be used.

## Decoder
The Decoder is a subcomponent of the `EXEC` stage. Its job is to decode the instruction fetched from the `FETCH` stage
into the following conditions:
- Immediate type: `I`, `S`, `B`, `U`, `J`.
- ALU sources: `RR` (Reg + Reg), `RI` (Reg + Imm), `PI` (PC + Imm).
- ALU operation: `IMM`, `ADD`, `SUB`, `SLT`, `SLTU`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`.
- Write-back source: `NONE`, `ALU`, `PC4`, `MEM`.
- PC source: `NONE`, `JUMP`, `BR_Z` (branch on zero), `BR_NZ` (branch on non-zero).
- Mem operation: `NONE`, `READ`, `WRITE`.
- Mem access size: `B`, `BU`, `H`, `HU`, `W`.

### Decoding table

| Op      | Imm type | ALU src | ALU op | WB src  | PC src  | Mem op  | Access size |
|---------|----------|---------|--------|---------|---------|---------|-------------|
| `ADD`   |          | `RR`    | `ADD`  | `ALU`   |         |         |             |
| `SUB`   |          | `RR`    | `SUB`  | `ALU`   |         |         |             |
| `SLT`   |          | `RR`    | `SLT`  | `ALU`   |         |         |             |
| `SLTU`  |          | `RR`    | `SLTU` | `ALU`   |         |         |             |
| `AND`   |          | `RR`    | `AND`  | `ALU`   |         |         |             |
| `OR`    |          | `RR`    | `OR`   | `ALU`   |         |         |             |
| `XOR`   |          | `RR`    | `XOR`  | `ALU`   |         |         |             |
| `SLL`   |          | `RR`    | `SLL`  | `ALU`   |         |         |             |
| `SRL`   |          | `RR`    | `SRL`  | `ALU`   |         |         |             |
| `SRA`   |          | `RR`    | `SRA`  | `ALU`   |         |         |             |
| `ADDI`  | `I`      | `RI`    | `ADD`  | `ALU`   |         |         |             |
| `SLTI`  | `I`      | `RI`    | `SLT`  | `ALU`   |         |         |             |
| `SLTIU` | `I`      | `RI`    | `SLTU` | `ALU`   |         |         |             |
| `ANDI`  | `I`      | `RI`    | `AND`  | `ALU`   |         |         |             |
| `ORI`   | `I`      | `RI`    | `OR`   | `ALU`   |         |         |             |
| `XORI`  | `I`      | `RI`    | `XOR`  | `ALU`   |         |         |             |
| `SLLI`  | `I`      | `RI`    | `SLL`  | `ALU`   |         |         |             |
| `SRLI`  | `I`      | `RI`    | `SRL`  | `ALU`   |         |         |             |
| `SRAI`  | `I`      | `RI`    | `SRA`  | `ALU`   |         |         |             |
| `LUI`   | `U`      | `PI`    | `IMM`  | `ALU`   |         |         |             |
| `AUIPC` | `U`      | `PI`    | `ADD`  | `ALU`   |         |         |             |
| `JAL`   | `J`      | `PI`    | `ADD`  | `PC4`   | `JUMP`  |         |             |
| `JALR`  | `I`      | `RI`    | `ADD`  | `PC4`   | `JUMP`  |         |             |
| `BEQ`   | `B`      | `RR`    | `SUB`  |         | `BR_Z`  |         |             |
| `BNE`   | `B`      | `RR`    | `SUB`  |         | `BR_NZ` |         |             |
| `BLT`   | `B`      | `RR`    | `SLT`  |         | `BR_NZ` |         |             |
| `BGE`   | `B`      | `RR`    | `SLT`  |         | `BR_Z`  |         |             |
| `BLTU`  | `B`      | `RR`    | `SLTU` |         | `BR_NZ` |         |             |
| `BGEU`  | `B`      | `RR`    | `SLTU` |         | `BR_Z`  |         |             |
| `LB`    | `I`      | `RI`    | `ADD`  | `MEM`   |         | `READ`  | `B`         |
| `LH`    | `I`      | `RI`    | `ADD`  | `MEM`   |         | `READ`  | `H`         |
| `LW`    | `I`      | `RI`    | `ADD`  | `MEM`   |         | `READ`  | `W`         |
| `LBU`   | `I`      | `RI`    | `ADD`  | `MEM`   |         | `READ`  | `BU`        |
| `LHU`   | `I`      | `RI`    | `ADD`  | `MEM`   |         | `READ`  | `HU`        |
| `SB`    | `S`      | `RI`    | `ADD`  |         |         | `WRITE` | `B`         |
| `SH`    | `S`      | `RI`    | `ADD`  |         |         | `WRITE` | `H`         |
| `SW`    | `S`      | `RI`    | `ADD`  |         |         | `WRITE` | `W`         |

Empty entries are either `NONE` or N/A (e.g. immediate type is not relevant to R-type operations).
