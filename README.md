# RISC-V Pipelined CPU (RV32IM)

![HDL](https://img.shields.io/badge/HDL-Verilog-1f6feb)
![ISA](https://img.shields.io/badge/ISA-RV32I%20%2B%20RV32M-orange)
![Simulation](https://img.shields.io/badge/Sim-Vivado%20XSim-2ea043)
![License](https://img.shields.io/badge/License-MIT-yellow)

A 32-bit RISC-V soft-core processor written from scratch in Verilog. It implements the
**RV32I** base integer instruction set plus the **RV32M** multiply/divide extension in a
five-stage pipeline with data forwarding and control-hazard handling. The design is
functionally verified in **Xilinx Vivado (XSim)** using a directed, instruction-by-instruction
testbench and a Python-based randomized program generator.

> Originally built as a computer-architecture course project ("FemRV32"). The repository
> includes two complementary cores: an initial **single-cycle** datapath and the main
> **5-stage pipelined** core that the testbench exercises.

---

## Highlights

- **Complete RV32I base ISA** — loads/stores (byte / half / word, signed & unsigned),
  register/immediate ALU ops, shifts, `SLT`/`SLTU`, all six branches, `JAL`/`JALR`,
  `LUI`/`AUIPC`.
- **RV32M extension** in the ALU — `MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`,
  `REM`, `REMU`.
- **5-stage pipeline** (IF → ID → EX → MEM → WB) with explicit pipeline registers.
- **Data forwarding** unit plus a **flush unit** that squashes the pipeline on taken
  branches and jumps.
- **Byte-addressable memory** with sub-word access and correct sign/zero extension on loads.
- **Two verification paths** — a self-documenting directed test that touches every base
  instruction, and a randomized RV32I program generator for stress testing.

## Supported instructions

| Category | Instructions |
|---|---|
| Loads | `LB` `LH` `LW` `LBU` `LHU` |
| Stores | `SB` `SH` `SW` |
| ALU (register) | `ADD` `SUB` `SLL` `SLT` `SLTU` `XOR` `SRL` `SRA` `OR` `AND` |
| ALU (immediate) | `ADDI` `SLTI` `SLTIU` `XORI` `ORI` `ANDI` `SLLI` `SRLI` `SRAI` |
| Branches | `BEQ` `BNE` `BLT` `BGE` `BLTU` `BGEU` |
| Jumps | `JAL` `JALR` |
| Upper immediate | `LUI` `AUIPC` |
| RV32M | `MUL` `MULH` `MULHSU` `MULHU` `DIV` `DIVU` `REM` `REMU` |
| System | `FENCE` (decoded as a no-op) |

## Architecture

```
        IF              ID                 EX               MEM              WB
   +-----------+   +-------------+   +-------------+   +-----------+   +-----------+
   | PC /      |   | Decode /    |   | ALU /       |   | Data      |   | Write     |
   | Fetch     |-->| Reg File /  |-->| Shifter /   |-->| Memory    |-->| back to   |
   |           |   | ImmGen /    |   | Branch cmp  |   | access    |   | Reg File  |
   +-----------+   | Control     |   +-------------+   +-----------+   +-----------+
        ^          +-------------+         ^                                 |
        |                                  |  forward (WB result -> EX)      |
        |                                  +---------------------------------+
        |
        +-- redirect / flush on taken branch, JAL, or JALR
```

Key microarchitecture choices:

- **Pipeline registers** `IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB` carry data and control
  signals down the pipe (see [`RISCV_Pipeline.v`](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v)).
- **Shared single-port memory** ([`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v))
  services instruction fetch on one clock phase and data access on the other, removing the
  structural hazard of a single memory without a separate I/D cache.
- **Forwarding** ([`forwarding_unit.v`](ArchProject/ArchProject.srcs/sources_1/forwarding_unit.v))
  routes the write-back result into the execute stage when a source register matches a
  pending destination, avoiding read-after-write stalls.
- **Control hazards** ([`hazard_detection_unit.v`](ArchProject/ArchProject.srcs/sources_1/hazard_detection_unit.v))
  are resolved by flushing the in-flight instruction when a branch is taken or a jump
  executes, then redirecting the PC.
- **ALU control** ([`ALUCU.v`](ArchProject/ArchProject.srcs/sources_1/ALUCU.v)) decodes the
  opcode class, `funct3`, and `funct7` bits into a 5-bit ALU operation select that also
  selects the RV32M datapath.

## Repository structure

```
.
├── ArchProject/
│   ├── ArchProject.srcs/sources_1/      # Verilog RTL + testbench
│   │   ├── RISCV_Pipeline.v             # main 5-stage pipelined core (DUT)
│   │   ├── final_top.v                  # earlier single-cycle datapath (reference)
│   │   ├── CPU_tb.v                     # testbench (clock/reset, drives the pipeline)
│   │   ├── controlUnit.v  ALUCU.v  branchDecoder.v  prv32_imm.v
│   │   ├── prv32_ALU.v  shifter.v       # ALU + barrel shifter (RV32I/M)
│   │   ├── RegisterFile.v  NRegister.v  DFlipFlop.v
│   │   └── singleMemory.v  InstMem.v  DataMem.v
│   ├── Instruction_generator.py         # randomized RV32I program generator
│   └── ArchProject.xpr                  # Vivado project file
├── Test_cases/
│   ├── program.mem                      # sample program image ($readmemb input)
│   └── WhatTheInstructionsDo.txt        # directed test: expected per-instruction effects
├── Journal/journal.txt                  # development log
├── Report.docx                          # full project report
├── LICENSE
└── README.md
```

## Getting started

**Prerequisites:** Xilinx Vivado (tested with the built-in XSim simulator) and Python 3.8+.

### Run the simulation

1. Open `ArchProject/ArchProject.xpr` in Vivado (**File → Open Project**), or create a new
   project and add every `.v` file under `ArchProject/ArchProject.srcs/sources_1/`.
2. Set [`CPU_tb`](ArchProject/ArchProject.srcs/sources_1/CPU_tb.v) as the simulation top.
3. Make the program image visible to the simulator (see below), then run **Behavioral
   Simulation** and inspect the register file / memory in the waveform viewer.

### Load a program

The core initializes its memory with Verilog `$readmemb` from a byte-per-line image
(one 8-bit value per line, little-endian within each 32-bit word). A ready-to-use sample
is at [`Test_cases/program.mem`](Test_cases/program.mem).

`$readmemb` resolves its path relative to the simulator's working directory, so either copy
`program.mem` into the XSim run directory, add it as a simulation source, or edit the path
string in [`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v).

To generate a fresh randomized program:

```bash
python ArchProject/Instruction_generator.py
```

This writes `program.txt` (human-readable listing) and `program.bin.txt` (the byte-encoded
image); rename or point the simulator at the byte image to load it.

## Verification

The processor is verified in two complementary ways:

1. **Directed test** — a hand-assembled program that exercises every base instruction with
   pre-computed expected results, documented step by step (including register and PC
   transitions) in [`WhatTheInstructionsDo.txt`](Test_cases/WhatTheInstructionsDo.txt).
   This makes it straightforward to diff observed waveform state against expected state.
2. **Randomized stress testing** — [`Instruction_generator.py`](ArchProject/Instruction_generator.py)
   emits large random RV32I programs (with valid encodings and branch/jump targets) to
   shake out hazard, forwarding, and control-flow corner cases.

## Roadmap

Natural next steps for the project:

- FPGA synthesis and implementation with board constraints (e.g. Artix-7 / Nexys A7),
  including timing closure and a top-level I/O wrapper.
- Full forwarding paths and explicit load-use stall insertion.
- Integration with the official RISC-V architectural test suite (e.g. `riscof`).

## Authors

Built by a three-person team for a computer-architecture course: **Omar Saqr**, **Noor**,
and **Abed**. See [`Journal/journal.txt`](Journal/journal.txt) for the development log.

## License

Released under the [MIT License](LICENSE).
