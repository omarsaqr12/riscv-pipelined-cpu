# FemRV32 — a five-stage RISC-V processor prototype

**Verilog · computer architecture · pipeline design · simulation and verification in progress**

A three-person computer-architecture course project implementing a 32-bit RISC-V processor prototype. The main design connects instruction fetch, decode, execute, memory access and writeback through pipeline registers. It includes a register file, instruction decoder, arithmetic/shift datapath with attempted RV32M operations, unified byte-addressable memory, branch handling and a limited forwarding path. An earlier single-cycle design is retained as part of the engineering history.

**What a reviewer can inspect today:** [Pipeline RTL](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) · [architecture walkthrough](docs/ARCHITECTURE.md) · [focused testbench](tests/branch_decoder_tb.v) · [verification matrix](docs/VERIFICATION.md) · [original report](Report.docx).

> **Status:** an educational **prototype**, not a verified RV32IM-compliant CPU or a demonstrated FPGA implementation. The historical `CPU_tb.v` provides clock and reset only. This review adds a branch-decoder fix and a self-checking *unit* regression, not a full-core ISA test. Claims of complete hazard handling or fully verified instruction coverage are not supported by the checked-in evidence.

## Architecture at a glance

```text
  PC ──> unified memory / instruction fetch ──> IF/ID
    ──> decode + register file + immediate generator ──> ID/EX
    ──> ALU / shifter + branch decision ──> EX/MEM
    ──> unified memory / data access ──> MEM/WB
    ──> register writeback
                       └─ MEM/WB ALU output forwarded to EX inputs
```

The main source is [`RISCV_Pipeline.v`](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v). Its [`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v) time-multiplexes instruction and data access using clock phases and stores both in one 4 KiB byte array. Pipeline registers are built with [`NRegister.v`](ArchProject/ArchProject.srcs/sources_1/NRegister.v) and [`DFlipFlop.v`](ArchProject/ArchProject.srcs/sources_1/DFlipFlop.v). The [`forwarding_unit.v`](ArchProject/ArchProject.srcs/sources_1/forwarding_unit.v) checks only a MEM/WB match, and [`hazard_detection_unit.v`](ArchProject/ArchProject.srcs/sources_1/hazard_detection_unit.v) generates a control-flow flush rather than a complete load-use stall protocol.

See the [source-by-source architecture guide](docs/ARCHITECTURE.md) for signal flow, assumptions, and the differences from the older [`final_top.v`](ArchProject/ArchProject.srcs/sources_1/final_top.v), which is **not** an independent known-good reference core.

## Reproduce a focused, self-checking demonstration

The branch decoder had a concrete source-level defect: after a taken BEQ, a subsequent untaken BEQ could retain the previous result. The review branch fixes the missing assignment and adds an assertion-based regression for all six branch-condition codes. From a checkout of **this PR branch**, install [Icarus Verilog](https://steveicarus.github.io/iverilog/) and run:

```bash
iverilog -g2012 -s branch_decoder_tb -o /tmp/femrv32_branch_tb \
  tests/branch_decoder_tb.v ArchProject/ArchProject.srcs/sources_1/branchDecoder.v
vvp /tmp/femrv32_branch_tb
```

Also inspect the committed sample program image with a standard-library test:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

The decoder test checks branch decisions when *given* flags; the image test checks byte formatting, memory capacity and the first little-endian instruction. Neither proves ALU flags or complete CPU behavior. GitHub Actions is configured to run both on PRs; **consult the actual workflow results** before treating either as passed. Local HDL simulation was unavailable during the initial review. The [verification guide](docs/VERIFICATION.md) distinguishes unit checks, CPU-level conformance and FPGA implementation.

## Explore the original CPU in Vivado

1. Create a **new** Vivado project (the historical [`ArchProject.xpr`](ArchProject/ArchProject.xpr) retains paths to deleted, machine-specific source locations). Add the checked-in `.v` files from `ArchProject/ArchProject.srcs/sources_1/` and choose `CPU_tb` as simulation top, with `RISCV_Pipeline` as the design under test. These steps are guidance, not a recently executed fresh-project build.
2. Put [`Test_cases/program.mem`](Test_cases/program.mem) in the simulator working directory as `program.mem`. `singleMemory.v` loads one 8-bit binary value per line with `$readmemb`, little-endian within each 32-bit instruction.
3. Inspect the waveforms **as exploratory signals**. The original testbench has no pass/fail assertions or termination, and the sample image is not an independently verified architectural test.

Do **not** run [`Instruction_generator.py`](ArchProject/Instruction_generator.py) as a quickstart. Its current defaults generate ten million instructions and one million labels, far more than the memory can hold; random control-flow targets are not restricted to representable offsets and no independent execution oracle is generated. It remains in the repository to preserve the historical work.

## Source and artifact map

| What you want to inspect | Where to start |
| --- | --- |
| Pipeline wiring and register boundaries | [`RISCV_Pipeline.v`](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) |
| Opcode / ALU control and immediates | [`controlUnit.v`](ArchProject/ArchProject.srcs/sources_1/controlUnit.v), [`ALUCU.v`](ArchProject/ArchProject.srcs/sources_1/ALUCU.v), [`prv32_imm.v`](ArchProject/ArchProject.srcs/sources_1/prv32_imm.v) |
| Arithmetic, multiplication/division and shifts | [`prv32_ALU.v`](ArchProject/ArchProject.srcs/sources_1/prv32_ALU.v), [`shifter.v`](ArchProject/ArchProject.srcs/sources_1/shifter.v) |
| Hazards, forwarding and branch decisions | [`forwarding_unit.v`](ArchProject/ArchProject.srcs/sources_1/forwarding_unit.v), [`hazard_detection_unit.v`](ArchProject/ArchProject.srcs/sources_1/hazard_detection_unit.v), [`branchDecoder.v`](ArchProject/ArchProject.srcs/sources_1/branchDecoder.v) |
| Historical design and worksheet | [`final_top.v`](ArchProject/ArchProject.srcs/sources_1/final_top.v), [`Test_cases/`](Test_cases/), [`Report.docx`](Report.docx) |
| Independent evidence and unresolved cases | [`tests/`](tests/), [`docs/VERIFICATION.md`](docs/VERIFICATION.md) |

## Limitations that matter

| Source-inspection finding | Why it matters |
| --- | --- |
| `CPU_tb.v` only drives clock/reset | No instruction-level pass/fail evidence from the historical testbench |
| MEM/WB forwarding routes the ALU value rather than the committed writeback value | Load-use and jump-link dependencies require additional bypassing/stalling and tests |
| `ID_EX_jradder` does not clear the target's low bit | The [ratified RV32I JALR rule](https://docs.riscv.org/reference/isa/v20240411/unpriv/rv32.html) is not implemented on that path |
| RV32M division/remainder use nonblocking temporary updates in combinational logic | Signedness, zero-divisor and overflow semantics cannot be claimed correct without independent known-answer tests |
| Legacy `ArchProject.xpr` lists old paths | Recreate a project from checked-in sources rather than promising the historical project opens unchanged |
| Historical worksheet assumes different memory initialization | Do not use [`WhatTheInstructionsDo.txt`](Test_cases/WhatTheInstructionsDo.txt) as a passing oracle for unified-memory pipeline execution |

These are **source-inspection findings**, not claims that complete CPU simulations were run. The remaining work is enumerated in [VERIFICATION.md](docs/VERIFICATION.md). The branch-decoder fix is deliberately small; a full redesign of the hazard network, arithmetic unit or memory system requires a separate specification and test plan.

## Team, provenance and license

Built by **Omar Saqr, Noor and Abed** as the *FemRV32* course project. The [development journal](Journal/journal.txt) records dated team contributions, including Omar's work on branch/control and forwarding fixes; repository ownership alone does not imply sole authorship. The original [report](Report.docx), sample image, worksheet, single-cycle design and generator remain preserved as historical artifacts. See [LICENSE](LICENSE) for repository licensing; the GitHub review PR makes no license change.
