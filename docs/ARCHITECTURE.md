# FemRV32 architecture: source-guided tour

This is an educational processor design with two historical datapaths, **not** a formally verified or ISA-certified core. The main prototype is [`RISCV_Pipeline.v`](../ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v). The earlier [`final_top.v`](../ArchProject/ArchProject.srcs/sources_1/final_top.v) instantiates separate instruction/data memories and is preserved for historical context, not as a known-good reference.

```text
PC + shared byte memory (IF on one clock phase)
   → IF/ID register
   → decode + register file + immediate generator
   → ID/EX register
   → ALU / shifts / branch decision / jump target
   → EX/MEM register
   → shared byte memory (data access on other phase)
   → MEM/WB register
   → destination register writeback
                └──── MEM/WB ALU-result forwarding to EX operands
```

The code uses both `clk` and `~clk` in pipeline stages. The timing/structural-hazard assumptions are implementation-specific and require simulation and synthesis; a five-stage diagram alone does not prove throughput or correctness. The `singleMemory` array holds both instruction bytes and program-visible data. Stores can therefore modify executable bytes (and a load from address zero reads instruction bytes), unlike the separate memories used by the earlier single-cycle datapath.

## Follow one instruction through the sources

| Stage / block | File | Actual responsibility and caution |
| --- | --- | --- |
| Program counter and pipeline boundaries | [`RISCV_Pipeline.v`](../ArchProject/ArchProject.srcs/sources_1/RISCV_Pipeline.v) | PC selection, IF/ID, ID/EX, EX/MEM and MEM/WB register concatenations and clock phases. |
| Reusable registers | [`NRegister.v`](../ArchProject/ArchProject.srcs/sources_1/NRegister.v), [`DFlipFlop.v`](../ArchProject/ArchProject.srcs/sources_1/DFlipFlop.v) | Bitwise register bank built from async-reset flip-flops. |
| Decode / immediates | [`controlUnit.v`](../ArchProject/ArchProject.srcs/sources_1/controlUnit.v), [`ALUCU.v`](../ArchProject/ArchProject.srcs/sources_1/ALUCU.v), [`prv32_imm.v`](../ArchProject/ArchProject.srcs/sources_1/prv32_imm.v) | Opcode/control decoding, operation selection and immediate assembly. Invalid encodings and widths need tests. |
| Register state | [`RegisterFile.v`](../ArchProject/ArchProject.srcs/sources_1/RegisterFile.v) | 32 architectural registers; write port is selected by the pipeline WB path. |
| Arithmetic | [`prv32_ALU.v`](../ArchProject/ArchProject.srcs/sources_1/prv32_ALU.v), [`shifter.v`](../ArchProject/ArchProject.srcs/sources_1/shifter.v) | Adds, comparisons, bitwise ops, shifts and attempted RV32M operations. Do not assume arithmetic extension conformance. |
| Branch choice / redirect | [`branchDecoder.v`](../ArchProject/ArchProject.srcs/sources_1/branchDecoder.v), [`hazard_detection_unit.v`](../ArchProject/ArchProject.srcs/sources_1/hazard_detection_unit.v) | Branch condition and redirect flush. The latter contains no load-use stall detection. |
| Forwarding | [`forwarding_unit.v`](../ArchProject/ArchProject.srcs/sources_1/forwarding_unit.v) | One MEM/WB destination comparison, not full EX/MEM priority/bypass coverage. |
| Storage | [`singleMemory.v`](../ArchProject/ArchProject.srcs/sources_1/singleMemory.v) | 4 KiB of byte-addressable unified memory, sub-word loads/stores, `$readmemb("program.mem", mem)` from the simulator working directory. |
| Historical separate-memory design | [`final_top.v`](../ArchProject/ArchProject.srcs/sources_1/final_top.v), [`InstMem.v`](../ArchProject/ArchProject.srcs/sources_1/InstMem.v), [`DataMem.v`](../ArchProject/ArchProject.srcs/sources_1/DataMem.v) | Earlier implementation; do not compile it as if it were another pipeline submodule or use it as an independent oracle. |

## Read the limitations before using this as a reference design

1. The pipeline forwards `MEM_WB_ALUoutput`, **not** `MEM_WB_writingData`. A dependent instruction after a load or jump may see a different value from the one committed to the register file. Source: `RISCV_Pipeline.v` forwarding assignments.
2. The `hazard_detection_unit` expression is a flush on jump/taken branch. There is no explicit load-use stall/enable signal in it. A description such as “complete hazard detection” would overstate the RTL.
3. The JALR target is `ID_EX_rs1data + ID_EX_imm` and does not clear bit zero. The [RISC-V RV32I specification](https://docs.riscv.org/reference/isa/v20240411/unpriv/rv32.html) requires clearing the least-significant bit; JALR register forwarding is also absent in this target path.
4. `prv32_ALU.v` uses nonblocking updates for temporary division/remainder variables in `always @*`; the complete RV32M corner-case matrix is not verified. The [RISC-V M extension](https://docs.riscv.org/reference/isa/v20240411/unpriv/m-st-ext.html) specifies division-by-zero and overflow semantics that need explicit assertions.
5. The bundled [`program.mem`](../Test_cases/program.mem) is a byte-per-line historical image loaded into **unified** memory. [`WhatTheInstructionsDo.txt`](../Test_cases/WhatTheInstructionsDo.txt) documents a separate-memory style of expected load values and contains malformed/duplicate instruction assignments. Treat it as a historical worksheet, not a machine-checkable oracle.

For runnable unit-level steps and the verification matrix, see [VERIFICATION.md](VERIFICATION.md). For a first-screen overview, return to the [README](../README.md).
