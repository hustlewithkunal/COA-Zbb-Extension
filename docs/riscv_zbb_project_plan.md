# RISC-V Zbb ISA Extension Project
## Project Brief, Objectives, and End-to-End Implementation Plan

**Course:** Computer Organisation and Architecture  
**Target Platform:** Zybo Z7-10 FPGA  
**Base Core:** CV32E40P (to be refactored into a 5-stage pipeline before extension)  
**Target Extension:** Selected RISC-V Zbb instructions  
**Instruction Subset:** `clz`, `ctz`, `cpop`, `rev8`, `sext.b`, `andn`, `orn`, `xnor`

---

## 1. Brief Idea of the Project

This project focuses on extending a RISC-V processor with a subset of **Zbb (basic bit-manipulation)** instructions and evaluating whether these instructions improve software efficiency enough to justify their hardware cost.

The given course constraints require that the processor must be a **5-stage RV32I pipeline** consisting of:

- IF
- ID
- EX
- MEM
- WB

Since the selected base core, **CV32E40P**, is not already a 5-stage pipeline, the first major task of the project is to **convert or refactor it into a proper 5-stage RV32I-style pipeline**. Only after this baseline core is correct and stable will the Zbb extension be added.

The final goal is not just to “make the instructions work,” but to answer a quantitative architecture question:

> How much reduction in dynamic instruction count is achieved for bit-manipulation workloads by adding Zbb support, and what hardware cost is introduced in terms of ALU timing, FPGA resources, and maximum frequency?

The project therefore combines three aspects:

1. **Architecture design** — converting the pipeline and adding new ALU instructions  
2. **Verification** — proving correctness in simulation and on FPGA  
3. **Evaluation** — comparing baseline vs extended core using performance and hardware metrics

---

## 2. Main Objective of the Project

The main objective of this project is to build a **5-stage synthesizable RV32I processor derived from CV32E40P**, extend it with selected **RISC-V Zbb bit-manipulation instructions**, and evaluate the tradeoff between:

- **software-side benefit**  
  such as reduction in dynamic instruction count and cycle count,

and

- **hardware-side cost**  
  such as increase in ALU critical path, LUT count, FF count, and change in Fmax.

---

## 3. Specific Objectives

### 3.1 Baseline Architecture Objectives
- Study the CV32E40P core structure and identify how it differs from a standard 5-stage pipeline.
- Refactor the baseline core into a strict **5-stage RV32I pipeline**.
- Ensure that the converted core remains synthesizable.
- Preserve correct execution of baseline RV32I instructions.

### 3.2 Verification Objectives
- Verify correctness of the converted 5-stage core through simulation.
- Test the design with directed instruction-level tests, hazard tests, branch tests, and small programs.
- Implement the baseline core on the **Zybo Z7-10 FPGA** and verify it through a hardware smoke test.

### 3.3 ISA Extension Objectives
- Add support for the following Zbb instructions:

  - `clz`
  - `ctz`
  - `cpop`
  - `rev8`
  - `sext.b`
  - `andn`
  - `orn`
  - `xnor`

- Extend the instruction decode path to recognize the selected Zbb subset.
- Extend the ALU in the EX stage so these instructions execute correctly.

### 3.4 Evaluation Objectives
- Run bit-manipulation workloads such as:
  - CRC-32 kernel
  - popcount loop
- Compare baseline RV32I and RV32I+Zbb versions.
- Measure:
  - dynamic instruction count
  - cycle count
  - FPGA LUT count
  - FPGA FF count
  - BRAM usage
  - Fmax
  - critical-path impact on the ALU

### 3.5 Final Reporting Objective
- Produce a quantitative answer to the project research question.
- Present a clean comparison between the baseline and extended core.

---

## 4. Core Research Question

A suitable research question for this project is:

> What percentage reduction in dynamic instruction count is achieved by adding selected RISC-V Zbb instructions to a 5-stage RV32I processor for bit-manipulation workloads such as CRC-32 and popcount, and what critical-path and FPGA resource overhead does this extension introduce?

---

## 5. Background Theory Required

Before implementation, the following theory should be understood clearly.

### 5.1 5-Stage RISC-V Pipeline
A standard 5-stage pipeline contains the following stages:

- **IF (Instruction Fetch):** fetches the instruction from instruction memory
- **ID (Instruction Decode):** decodes instruction and reads register operands
- **EX (Execute):** performs ALU operation, branch comparison, or address calculation
- **MEM (Memory Access):** handles load/store memory access
- **WB (Write Back):** writes result back to register file

This project requires that the design must use this pipeline structure.

### 5.2 RISC-V RV32I Basics
The processor must correctly support baseline **RV32I** instructions before any extension work begins. This includes arithmetic, logical, branch, load/store, and immediate operations.

### 5.3 Zbb Bit-Manipulation Instructions
The selected Zbb subset provides hardware support for common bit-level operations:

- `clz` — count leading zeros  
- `ctz` — count trailing zeros  
- `cpop` — count number of set bits  
- `rev8` — reverse byte order  
- `sext.b` — sign-extend least-significant byte  
- `andn` — AND with negated second operand  
- `orn` — OR with negated second operand  
- `xnor` — XOR complement  

These instructions can replace multi-instruction software sequences, especially in bit-heavy kernels.

### 5.4 Dynamic Instruction Count
Dynamic instruction count means the actual number of instructions executed at runtime. It is a key measure in this project because Zbb instructions are meant to reduce the number of instructions needed to perform bit-level operations.

### 5.5 Critical Path and Fmax
The **critical path** is the longest combinational logic path in the design and determines the maximum clock frequency. Since new Zbb logic will be added in the ALU, the ALU delay may increase, reducing **Fmax**. This is a major part of the hardware cost analysis.

### 5.6 FPGA Resource Metrics
When implemented on FPGA, the design must be evaluated using:

- **LUT count**
- **FF count**
- **BRAM usage**
- **Fmax**

These are explicitly required by the course constraints.

---

## 6. End-to-End Implementation Plan

The implementation should be done in clearly separated stages. The most important rule is:

> Do not add Zbb until the converted 5-stage baseline core is fully correct.

---

## Phase 0 — Freeze Project Scope

### Tasks
- Freeze the exact instruction subset to be implemented:
  - `clz`, `ctz`, `cpop`, `rev8`, `sext.b`, `andn`, `orn`, `xnor`
- Freeze the baseline target:
  - 5-stage RV32I pipeline derived from CV32E40P
- Freeze the evaluation metrics:
  - dynamic instruction count
  - cycle count
  - LUTs
  - FFs
  - BRAMs
  - Fmax
  - critical-path impact

### Output
- A clear project definition document
- Fixed list of instructions, workloads, and metrics

---

## Phase 1 — Study the Existing CV32E40P Core

### Tasks
- Read the RTL structure of CV32E40P.
- Understand the current stage partitioning.
- Identify:
  - datapath organization
  - decode logic
  - ALU structure
  - register file read/write behavior
  - branch handling
  - hazard handling
  - existing pipeline registers
- Make a mapping from current architecture to desired 5-stage structure.

### What to identify specifically
- Which functions currently belong to fetch, decode, execute, memory, and writeback
- Where control signals are generated
- How forwarding and hazards are currently handled
- What extra PULP-specific features may need to be disabled or ignored initially

### Output
- Architecture study notes
- “Current vs target” pipeline mapping
- A list of files/modules that must be modified

---

## Phase 2 — Define the New 5-Stage Pipeline Organization

### Tasks
Define clear responsibilities for each stage.

### IF stage
- PC generation
- instruction memory request
- fetch of instruction
- PC + 4 generation

### ID stage
- instruction decode
- immediate generation
- register file read
- control generation

### EX stage
- ALU operation
- branch comparison
- branch target calculation
- effective address generation for loads/stores

### MEM stage
- data memory access for loads/stores
- memory read data capture

### WB stage
- writeback result selection
- register write enable and data writeback

### Also define
- IF/ID register
- ID/EX register
- EX/MEM register
- MEM/WB register

Each pipeline register must carry the required data and control signals.

### Output
- Final target pipeline diagram
- Stage-wise signal allocation
- Pipeline register contents list

---

## Phase 3 — Refactor CV32E40P into a 5-Stage RV32I Core

### Tasks
- Insert or modify explicit pipeline registers between all stages:
  - IF/ID
  - ID/EX
  - EX/MEM
  - MEM/WB
- Ensure control is generated in ID and passed forward through pipeline registers.
- Restructure the writeback timing so register-file write occurs cleanly in WB.
- Simplify the initial baseline to a clean RV32I-compatible design if necessary.

### Important design points
- Keep the design synthesizable.
- Prefer clean and explicit control propagation over shortcut logic.
- Keep the core stable before adding optional features.

### Output
- First RTL version of the converted 5-stage RV32I baseline

---

## Phase 4 — Implement Hazard Handling for the 5-Stage Baseline

### Tasks
Implement the logic needed for correct pipelined execution.

### 4.1 Data forwarding
Add forwarding paths such as:
- EX/MEM → EX
- MEM/WB → EX

Operands that may need forwarding:
- ALU operand A
- ALU operand B
- branch comparator operands
- store data path if required

### 4.2 Load-use hazard handling
Detect cases where an instruction uses a value loaded by the immediately previous instruction and insert:
- stall
- bubble
- pipeline hold where necessary

### 4.3 Control hazard handling
Handle:
- branch instructions
- `jal`
- `jalr`

Decide:
- where branch resolution happens
- how PC redirection is done
- which stages get flushed on a taken branch

### 4.4 Pipeline control discipline
Each stage should support:
- valid bit
- stall/hold
- flush/bubble insertion

### Output
- Working hazard and control-hazard handling logic for the 5-stage baseline

---

## Phase 5 — Verify the 5-Stage Baseline in Simulation

This is a major checkpoint. No Zbb work should start before this phase is complete.

### 5.1 Module-level tests
Test these blocks individually:
- register file
- ALU
- immediate generator
- branch comparator
- forwarding unit
- hazard detection unit
- pipeline register modules

### 5.2 Directed instruction tests
Write small assembly tests for:
- arithmetic operations
- logical operations
- immediate operations
- loads and stores
- branches
- jumps
- `lui` and `auipc`

### 5.3 Pipeline-specific tests
Test:
- forwarding cases
- load-use stall cases
- branch flush cases
- store-data dependency cases

### 5.4 Small program tests
Run complete short programs such as:
- array sum
- memory copy
- loop counters
- Fibonacci
- checksum-style test

### 5.5 Reference comparison
Compare your execution traces or final register/memory signatures with a known-correct RV32I reference.

### 5.6 Build a regression suite
Create a reusable regression test suite. Every later modification must pass this suite.

### Output
- Verified 5-stage RV32I baseline in simulation
- Regression test framework

---

## Phase 6 — Baseline FPGA Synthesis and On-Board Validation

### Tasks
- Synthesize the 5-stage RV32I baseline for **Zybo Z7-10**
- Collect:
  - LUT count
  - FF count
  - BRAM usage
  - Fmax
  - critical path report
- Run a hardware smoke test using a simple program

### Suggested hardware smoke test ideas
- LED pattern / pass-fail indicator
- UART message output
- memory-based signature output

### Output
- Baseline FPGA metrics
- Baseline hardware proof of operation

This becomes your official baseline for final comparison.

---

## Phase 7 — Prepare the Zbb Extension Design

Only after the baseline is stable should extension design begin.

### Tasks
- Prepare the decode specification for each instruction:
  - opcode
  - funct3
  - funct7 / required bits
  - register usage
  - writeback behavior
- Decide the ALU control encoding for each new operation.

### Example ALU control values
- `ALU_CLZ`
- `ALU_CTZ`
- `ALU_CPOP`
- `ALU_REV8`
- `ALU_SEXTB`
- `ALU_ANDN`
- `ALU_ORN`
- `ALU_XNOR`

### Hardware planning
Classify instructions into:

#### Simple logic
- `andn`
- `orn`
- `xnor`
- `sext.b`
- `rev8`

#### Potentially timing-sensitive logic
- `clz`
- `ctz`
- `cpop`

These should be designed carefully to avoid excessive ALU delay.

### Output
- Final Zbb decode table
- Final ALU extension plan

---

## Phase 8 — Implement Zbb in RTL

### Tasks
- Extend decode logic to recognize the selected Zbb instructions.
- Extend the ALU control path.
- Add EX-stage combinational logic for all new instructions.
- Ensure results pass through the pipeline and write back correctly.
- Confirm that forwarding logic works for new ALU results.

### Important rule
The new instructions should ideally behave like normal single-cycle ALU operations in EX so that hazard handling remains simple.

### Output
- RTL for 5-stage RV32I + Zbb core

---

## Phase 9 — Verify Zbb Extension in Simulation

### 9.1 Directed tests for each instruction
Create specific tests for:
- `andn`
- `orn`
- `xnor`
- `sext.b`
- `rev8`
- `cpop`
- `clz`
- `ctz`

### 9.2 Corner case testing
Examples:
- all-zero input
- all-one input
- alternating bit patterns
- sign-sensitive byte values
- only MSB set
- only LSB set
- random values

### 9.3 Golden reference comparison
Compare RTL output with expected software or script-generated results.

### 9.4 Pipeline dependency tests
Ensure forwarding and writeback are correct for Zbb instructions followed immediately by dependent instructions.

### 9.5 Full regression
Run:
- old RV32I regression suite
- new Zbb tests
- mixed programs

### Output
- Verified Zbb functionality in simulation
- Proof that old RV32I functionality is still correct

---

## Phase 10 — Benchmark Preparation

### Tasks
Prepare two versions of the required workloads:

### Baseline RV32I versions
- CRC-32 kernel using only RV32I instructions
- popcount loop using only RV32I instructions

### Zbb-optimized versions
- popcount loop using `cpop`
- CRC-32 or helper bit-processing routines optimized using the new Zbb instructions where applicable

### Benchmark requirements
- Same input data for both versions
- Same output result
- Same stopping condition
- Deterministic execution

### Output
- Benchmark sources for fair baseline vs extended comparison

---

## Phase 11 — Performance Measurement

### Tasks
Measure and compare:

- dynamic instruction count
- cycle count
- possibly CPI
- output correctness

### For each benchmark record
- benchmark name
- input size
- baseline instruction count
- baseline cycle count
- extended instruction count
- extended cycle count
- percentage reduction

### Output
- Performance comparison tables
- Quantitative answer for software-side gain

---

## Phase 12 — FPGA Synthesis and Timing for Extended Core

### Tasks
- Synthesize the 5-stage RV32I + Zbb core for Zybo Z7-10
- Collect:
  - LUT count
  - FF count
  - BRAM usage
  - Fmax
  - critical-path report

### Compare against baseline
Create a direct table:

- Baseline 5-stage RV32I
- Extended 5-stage RV32I + Zbb

### Analyze specifically
- whether `clz`, `ctz`, or `cpop` contribute to critical path
- whether ALU delay increased significantly
- whether Fmax reduced

### Output
- Hardware cost comparison table
- Timing/critical-path analysis

---

## Phase 13 — Final Validation

### Tasks
Run one final full validation pass including:

- baseline instruction tests
- pipeline hazard tests
- branch and memory tests
- Zbb instruction tests
- benchmark correctness tests
- FPGA smoke test for extended core

### Output
- Final validated project package

---

## 7. Testing Strategy to Follow Throughout

A good rule for this project is:

### After every major RTL change, run 3 levels of testing

#### Level 1 — Local module test
Test only the changed block.

#### Level 2 — Pipeline test
Run a small assembly sequence that exercises the changed logic inside the pipeline.

#### Level 3 — Full regression
Run the full working regression suite to make sure nothing old broke.

This discipline will save a lot of debugging time.

---

## 8. Final Deliverables

By the end of the project, you should have:

### RTL Deliverables
- 5-stage baseline RV32I core derived from CV32E40P
- extended 5-stage RV32I + Zbb core
- hazard, forwarding, and control logic

### Verification Deliverables
- module-level testbenches
- directed assembly tests
- regression suite
- benchmark correctness results

### FPGA Deliverables
- synthesis reports for baseline and extended designs
- LUT, FF, BRAM, and Fmax comparison
- critical-path/timing analysis
- hardware smoke-test evidence

### Performance Deliverables
- dynamic instruction count comparison
- cycle count comparison
- benchmark output verification

### Report Deliverables
- project motivation
- objectives
- architecture changes
- testing methodology
- results and tables
- final conclusion answering the research question

---

## 9. Final Summary

This project should be executed in two major parts:

1. **Convert CV32E40P into a correct 5-stage RV32I processor and verify it thoroughly**
2. **Add the selected Zbb instructions and measure their software benefit and hardware cost**

The most important principle is to keep the work layered and disciplined:

- first architecture conversion
- then correctness
- then FPGA validation
- then ISA extension
- then benchmarking
- then final quantitative comparison

If this order is followed properly, the project will remain manageable, and the final report will naturally produce a strong architecture story with solid quantitative results.
