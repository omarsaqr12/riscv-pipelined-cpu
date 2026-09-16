# Verification plan and current evidence

**Scope:** educational FemRV32 source code at the PR branch. There is no demonstrated processor-level ISA compliance, synthesis timing closure, or FPGA deployment in this audit. The existing `CPU_tb.v` is only a clock/reset driver. Historical instruction comments and a waveform are not a passing architectural test.

## Checks available now

From a checkout of this PR branch, with [Icarus Verilog](https://steveicarus.github.io/iverilog/) installed:

```bash
iverilog -g2012 -s branch_decoder_tb -o /tmp/femrv32_branch_tb \
  tests/branch_decoder_tb.v ArchProject/ArchProject.srcs/sources_1/branchDecoder.v
vvp /tmp/femrv32_branch_tb
```

The new testbench uses `!==` to reject unknown values and `$fatal(1)` on a mismatch. Its cases cover both directions of BEQ/BNE/BLT/BGE/BLTU/BGEU, invalid branch function codes, and the original taken-then-not-taken BEQ latch regression. It verifies **only the decoder given supplied flags**, not correctness of ALU flag generation, the pipeline, or programs. A separate standard-library test checks the committed sample image's byte format and 4 KiB capacity:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

The `.github/workflows/branch-decoder.yml` workflow is intended to run both checks on a pull request. **A workflow file is not evidence of a passed CI run.** Verify the actual checks on the PR before merging.

## Architectural conformance work remaining

| Priority | Test needed | Why it matters | Status in this audit |
| --- | --- | --- | --- |
| P0 | Full-core simulator elaboration with a deterministic stop condition | `CPU_tb.v` currently has no `$finish` or assertions; `ArchProject.xpr` points to missing files | NOT RUN |
| P0 | Known-answer RV32I program + independent reference model | Compare all architectural register writes, final PC, memory bytes and control flow | NOT RUN |
| P0 | Back-to-back ALU, load-use and jump-link dependencies | `forwarding_unit` selects MEM/WB only and the pipeline forwards ALU output, not final WB value | NOT RUN |
| P0 | JALR odd target, dependency and link-register tests | RV32I requires target bit zero to be cleared; code uses unmasked unforwarded source register | NOT RUN |
| P0 | Signed/unsigned RV32M and division edge cases | Incomplete combinational temporary updates and signedness need an independent oracle | NOT RUN |
| P1 | Branch flag generation including negative/overflow cases | A correct decoder cannot compensate for wrong ALU flags or pipeline timing | NOT RUN |
| P1 | Boundary/misaligned and out-of-range loads and stores | Unified memory is 4 KiB; the memory interface has 12-bit addresses and multi-byte indexing | NOT RUN |
| P1 | Synthesis, target constraints, clocks and FPGA board validation | Simulation, synthesis and physical implementation are separate evidence | NOT RUN |

RV32M known-answer cases should include `MULH`/`MULHU`/`MULHSU` operand signedness, `DIV`/`DIVU` with zero divisor, `REM`/`REMU` with zero divisor, and `INT_MIN / -1` overflow. Use the [ratified M extension](https://docs.riscv.org/reference/isa/v20240411/unpriv/m-st-ext.html), not comments in the legacy worksheet, as the oracle. For branches and JALR, consult the [ratified RV32I specification](https://docs.riscv.org/reference/isa/v20240411/unpriv/rv32.html).

## Recreating a Vivado project without changing historical artifacts

The committed `ArchProject/ArchProject.xpr` references old `imports/Downloads/...` and `sources_1/new/...` locations. Use it as historical context, not as a guaranteed portable project. Create a new Vivado project, add checked-in Verilog sources from `ArchProject/ArchProject.srcs/sources_1/`, and select `CPU_tb` as the *simulation* top. For pipeline synthesis, the design top is `RISCV_Pipeline` instead; including `final_top.v` as a competing top does not make it a reference model. In the simulator's current working directory, place [`Test_cases/program.mem`](../Test_cases/program.mem) as `program.mem` because `singleMemory.v` uses `$readmemb("program.mem", mem)`.

**Important:** that sample starts with a load from address zero while instruction/data memory are shared; it does not reproduce the historical worksheet's separate data-memory initialization. Do not assert the worksheet's expected register values as a valid golden trace for the pipeline without independently reconstructing the memory image and reference model.

The historical `Instruction_generator.py` is not a safe test runner: it requests 10 million instructions and a million labels by default, exceeds the memory size, and does not constrain random branch targets to encoding ranges. Do not execute it as the README quickstart or claim it provides independent randomized verification.

## Evidence labels for contributions or resumes

**Supported by source:** built a 32-bit RISC-V pipeline *prototype* with register file, arithmetic/shift datapath, shared memory, basic forwarding and branch control in a three-person course project. **Not currently supported:** fully RV32IM-compliant, fully verified, 100% instruction coverage, FPGA deployed, meets timing, or zero-stall pipeline. The [team journal](../Journal/journal.txt) records dated individual contributions; it is not a replacement for a working functional test.
