# FemRV32: a course-project RISC-V processor in Verilog

A team-built, educational 32-bit RISC-V processor project containing a five-stage **pipeline prototype** and an earlier single-cycle datapath. The RTL includes instruction decoding, a register file, ALU with attempted RV32M operations, unified byte-addressable memory, pipeline registers, a forwarding path, and branch redirection. This is a repository of real hardware-design work **in progress**, not a verified RV32IM-compliant core or a proven FPGA implementation.

> **Verification status:** The original `CPU_tb.v` drives only clock and reset; it has no functional assertions or pass/fail result. A self-checking *branch-decoder unit test* has been added in this audit. Full-core instruction execution, RV32M arithmetic, pipeline hazards, synthesis, timing, and FPGA behavior have **not** been independently verified here. See [verification and known issues](#verification-and-known-issues) before reusing the design.

## Design at a glance

The main `RISCV_Pipeline` prototype follows fetch → decode → execute → memory → writeback, with IF/ID, ID/EX, EX/MEM, and MEM/WB registers. Its `singleMemory` time-multiplexes instruction reads and data accesses across clock phases. `forwarding_unit` currently checks only a MEM/WB register match and forwards the **ALU output**, not the final writeback value. `hazard_detection_unit` is a redirect flush signal, not a full load-use stall detector. Consequently, do not assume back-to-back dependent instructions work. The earlier `final_top.v` is separate historical RTL, not a validated reference implementation.

| Area | Source |
| --- | --- |
| Pipeline and stage connections | [`RISCV_Pipeline.v`](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) |
| Control and immediate decode | [`controlUnit.v`](ArchProject/ArchProject.srcs/sources_1/controlUnit.v), [`prv32_imm.v`](ArchProject/ArchProject.srcs/sources_1/prv32_imm.v) |
| Arithmetic and shifts | [`prv32_ALU.v`](ArchProject/ArchProject.srcs/sources_1/prv32_ALU.v), [`shifter.v`](ArchProject/ArchProject.srcs/sources_1/shifter.v) |
| Dependencies and hazards | [`forwarding_unit.v`](ArchProject/ArchProject.srcs/sources_1/forwarding_unit.v), [`hazard_detection_unit.v`](ArchProject/ArchProject.srcs/sources_1/hazard_detection_unit.v) |
| Instruction/data memory | [`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v) |
| Simulation harness | [`CPU_tb.v`](ArchProject/ArchProject.srcs/sources_1/CPU_tb.v) |
| Original design report | [`Report.docx`](Report.docx) |

## Inspecting and running

For a focused, self-checking **decoder-only** regression, install Icarus Verilog and run from the repository root:

```bash
iverilog -g2012 -s branch_decoder_tb -o /tmp/branch_decoder_tb \
  tests/branch_decoder_tb.v ArchProject/ArchProject.srcs/sources_1/branchDecoder.v
vvp /tmp/branch_decoder_tb
```

The test covers taken and untaken branch conditions, including a taken-then-untaken BEQ regression. It does **not** exercise the whole processor. This command is supplied for independent reproduction; no HDL simulator was available in the audit environment, so its result is **not claimed as PASS**.

To explore the historical top-level design in Vivado, create a **new** project, add the Verilog files in `ArchProject/ArchProject.srcs/sources_1/`, and use `CPU_tb` as simulation top and `RISCV_Pipeline` as DUT. Do not rely on `ArchProject/ArchProject.xpr` as a portable project: it references removed `imports/Downloads/...` and `sources_1/new/...` files from the original author's machine. Use Vivado 2024.2 if possible, though the new-project flow is not verified here. Place [`Test_cases/program.mem`](Test_cases/program.mem) in the simulation working directory: `singleMemory.v` calls `$readmemb("program.mem", mem)` and expects one binary byte per line, little-endian within a word. Inspect traces critically; the original clock/reset-only simulation cannot tell you whether instructions executed correctly.

**Do not run the historical program generator as a quickstart.** [`Instruction_generator.py`](ArchProject/Instruction_generator.py) defaults to 10,000,000 instructions / 1,000,000 labels, far beyond the 4 KiB RTL memory. Its random branch targets are not constrained to representable branch/jump offsets, and generated programs do not come with an independent execution oracle. The sample image is a historical input, not a passing test fixture.

## Verification and known issues

The following are source-inspection findings, not claims of reproduced hardware failures:

| Priority | Evidence and implication |
| --- | --- |
| High | The original BEQ path in `branchDecoder.v` left `branchOrNot` unchanged when equality was false, inferring state; this audit supplies a combinational fix and a regression test. The regression has not been run in HDL simulation here. |
| High | `prv32_ALU.v` uses nonblocking assignments to temporary divide/remainder operands and results inside a combinational block; signed/unsigned corner cases and divide-by-zero handling remain unverified. Do not claim complete RV32M. |
| High | `forwarding_unit.v` only selects MEM/WB and `RISCV_Pipeline.v` forwards its ALU value rather than final writeback data. Load-to-use, jump-link, and other dependent paths require architectural tests and probably design changes. |
| High | `CPU_tb.v` has no assertions, finish condition, register/memory scoreboard, or ISA oracle. `Test_cases/WhatTheInstructionsDo.txt` is an explanatory worksheet, not an executable test. |
| Medium | `ArchProject.xpr` has machine-specific source references; a fresh-checkout Vivado project must use the checked-in source files. |
| Medium | The generator's default workload exceeds memory capacity and branch/jump offset constraints; it is retained for provenance but is not a runnable verification workflow. |

A meaningful next verification milestone is a bounded program with an **independent RV32I reference model**, an explicit stop condition, architectural register/memory comparisons, and directed hazards, branch not-taken cases, negative immediates, JALR target-bit clearing, multiplication high halves, signed remainder, division by zero, and overflow. Only after that should the README enumerate instructions as *verified*. FPGA synthesis and timing require a separate, documented board/target and constraints.

## Attribution and provenance

Original course-project team: **Omar Saqr, Noor, and Abed**. The contemporaneous [`Journal/journal.txt`](Journal/journal.txt) records examples of individual contributions, including Omar's branch and forwarding work; this public repository is team work, not solely authored by Omar. Existing [`Test_cases/`](Test_cases/) and the original [report](Report.docx) remain available as historical artifacts. The original source files and generator are retained, with an isolated decoder fix and test, rather than being silently rewritten. See [LICENSE](LICENSE).
