# FemRV32 | Five-stage RISC-V CPU prototype

**Verilog · processor microarchitecture · RTL design · hardware verification**

FemRV32 is a three-person computer-architecture project that implements a 32-bit RISC-V processor *prototype*. Its main design connects instruction fetch, decode, execute, memory access, and register writeback through explicit pipeline registers. The repository includes the RTL, a sample instruction image, a design report, and focused automated checks. An earlier single-cycle datapath is preserved for comparison and project history.

[Explore the pipeline RTL](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) · [Architecture walkthrough](docs/ARCHITECTURE.md) · [Run the decoder regression](#run-the-focused-tests) · [Verification status](docs/VERIFICATION.md) · [Original report](Report.docx)

## What the project demonstrates

| Engineering area | Implementation to inspect |
| --- | --- |
| Pipeline organization | IF/ID, ID/EX, EX/MEM and MEM/WB register boundaries in [`RISCV_Pipeline.v`](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) |
| Datapath and control | Opcode and immediate decoding, arithmetic/shift logic and branch selection in [`ArchProject/`](ArchProject/) |
| Memory design | A time-multiplexed, unified 4 KiB byte-addressable instruction/data memory in [`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v) |
| Dependency handling | A limited MEM/WB forwarding path and control-flow flushing, documented with their current limitations in the [architecture guide](docs/ARCHITECTURE.md) |
| Verification practice | A corrected combinational BEQ decision, a self-checking decoder testbench, and CI checks for the committed program image and documentation links |

**Scope:** this is an educational pipeline prototype, **not** an independently verified RV32IM-compliant processor or an FPGA deployment. The original [`CPU_tb.v`](ArchProject/ArchProject.srcs/sources_1/CPU_tb.v) only supplies clock and reset; the newly added checks verify individual artifacts, not end-to-end instruction execution. The [verification matrix](docs/VERIFICATION.md) spells out what remains to be tested.

## Datapath at a glance

```text
PC → shared memory / instruction fetch → IF/ID
   → decode + register file + immediate generator → ID/EX
   → ALU / shifter + branch and jump control → EX/MEM
   → shared memory / data access → MEM/WB
   → register writeback
               └── MEM/WB ALU result → selected EX operands
```

The memory serves instruction fetch and data access on different clock phases. The forwarding path uses the MEM/WB **ALU result**, rather than the final writeback value; the flush unit does not implement load-use stalls. These choices are visible in the source and are not presented as complete hazard handling. Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) for stage-level signal flow and the retained [single-cycle design](ArchProject/ArchProject.srcs/sources_1/final_top.v).

## Run the focused tests

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/) and run from the repository root:

```bash
iverilog -g2012 -s branch_decoder_tb -o /tmp/femrv32_branch_tb \
  tests/branch_decoder_tb.v ArchProject/ArchProject.srcs/sources_1/branchDecoder.v
vvp /tmp/femrv32_branch_tb

python3 -m unittest discover -s tests -p 'test_*.py' -v
```

The Verilog regression tests taken and untaken decisions for all six branch conditions, invalid function codes, and the original **taken BEQ → untaken BEQ** bug. The Python tests check the sample image and local documentation links. See the [GitHub Actions workflow](.github/workflows/branch-decoder.yml) and [its runs](https://github.com/omarsaqr12/riscv-pipelined-cpu/actions/workflows/branch-decoder.yml) for recorded results. A passing decoder test checks the decision **given input flags**; it does not validate flag generation, the full pipeline, all instructions, or FPGA timing.

## Explore the historical simulation

To inspect the full pipeline in Vivado, create a **new project** from the checked-in Verilog sources under [`ArchProject/ArchProject.srcs/sources_1/`](ArchProject/ArchProject.srcs/sources_1/). Choose `CPU_tb` as simulation top and `RISCV_Pipeline` as its design under test. Put [`Test_cases/program.mem`](Test_cases/program.mem) in the simulator's working directory as `program.mem`; [`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v) reads one binary byte per line using `$readmemb`. These setup steps are documented guidance, **not** a newly verified full-core simulation.

The committed [`ArchProject.xpr`](ArchProject/ArchProject.xpr) contains machine-specific source paths, so it should not be treated as a portable fresh-checkout project. The historical [`Instruction_generator.py`](ArchProject/Instruction_generator.py) defaults to **10 million instructions**, beyond the 4 KiB memory, and its branch targets are not constrained to encodable offsets; it is preserved for provenance, not recommended as a quickstart. The [test-case notes](Test_cases/README.md) distinguish the sample image from a golden execution trace.

## Code and evidence map

| Area | Entry point |
| --- | --- |
| Pipeline and shared memory | [`RISCV_Pipeline.v`](ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) · [`singleMemory.v`](ArchProject/ArchProject.srcs/sources_1/singleMemory.v) |
| Decode, ALU and register state | [`controlUnit.v`](ArchProject/ArchProject.srcs/sources_1/controlUnit.v) · [`prv32_ALU.v`](ArchProject/ArchProject.srcs/sources_1/prv32_ALU.v) · [`RegisterFile.v`](ArchProject/ArchProject.srcs/sources_1/RegisterFile.v) |
| Forwarding and branch logic | [`forwarding_unit.v`](ArchProject/ArchProject.srcs/sources_1/forwarding_unit.v) · [`branchDecoder.v`](ArchProject/ArchProject.srcs/sources_1/branchDecoder.v) |
| Verification and next steps | [`tests/`](tests/) · [`docs/VERIFICATION.md`](docs/VERIFICATION.md) |
| Original project materials | [`Report.docx`](Report.docx) · [`Journal/journal.txt`](Journal/journal.txt) · [`Test_cases/`](Test_cases/) |

## Verification boundaries and contributors

Source inspection identifies additional work needed for full ISA conformance: load-use and jump-link forwarding/stalls, clearing JALR target bit zero, independently checked ALU flags, RV32M signedness and division edge cases, and full-core architectural tests. These findings and a prioritized test plan are documented in [VERIFICATION.md](docs/VERIFICATION.md); **none is claimed solved by the branch-decoder regression**.

Built by **Omar Saqr, Noor, and Abed**. The [contemporaneous journal](Journal/journal.txt) records team contributions, including Omar's branch/control and forwarding work. Repository ownership does not imply sole authorship. The original report, worksheet, generator, and older datapath have been retained. See [LICENSE](LICENSE).
