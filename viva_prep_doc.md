# Comprehensive Viva Preparation Guide: Zbb-Extended RISC-V Processor

This document contains everything you need to know for your viva. It is written simply and traces the exact thought process, engineering decisions, and outcomes we achieved.

---

## 1. The Core Objective (What we did and Why)

**What we did:** 
We built a standard 32-bit RISC-V 5-stage pipelined processor (Baseline) and then extended its Arithmetic Logic Unit (ALU) and Instruction Decode path to support the **Zbb Extension** (a subset of instructions meant specifically for bit-manipulation).

**Why we did it:**
In standard RISC-V (RV32I base), if you want to count the number of 1s in a register (popcount) or reverse the bytes (endianness swap), you have to write a loop in software using `shifts`, `AND` logical masks, and `additions`. These loops take a lot of clock cycles to run. By adding Zbb, we created dedicated physical hardware circuits inside the ALU to do these operations in just **1 cycle** (1 instruction). 

---

## 2. Research Question Answer (P15)

**The Handout Question:**
> *What is the reduction in dynamic instruction count for bit-manipulation kernels and what is the ALU critical-path cost?*

**Your Answer for the Examiner:**
1. **Dynamic Instruction Reduction**: By implementing the Zbb extension, we observed an **85.19% reduction** in dynamic instruction counts for our pure Popcount kernel (dropping from 27 executed instructions to just 4). For a full CRC-32 processing kernel (which relied heavily on byte-swapping), we observed an **18.68% reduction** (dropping from 455 instructions to 370). 
2. **Critical-Path Cost**: The implementation of the combinatorial logic required for Zbb (such as the 32-bit adder tree for `cpop`) introduced a negligible critical path penalty of exactly **0.007 ns (7 picoseconds)** on a 100MHz (10ns) clock constraint target. 
3. **Unexpected Core Size Benefit**: Although the ALU logic grew (using more LUTs), the compiled code footprint in the Instruction Memory crashed massively due to the denser instruction sequence. Because Vivado maps async memory to Distributed LUT RAMs, this resulted in an overall core LUT size *reduction* of **10.22%**.

---

## 3. Changes from Baseline to Zbb (How we did it)

To transform the Baseline into the Zbb-Extended version:

1. **Expanding the ALU Control Width:** We widened the `alu_ctrl` signal line from 4 bits to 5 bits to handle the 8 new operation mappings.
2. **Modifying the Decode Stage (`alu_control.v`):** We added logic to look at the `funct3` and `funct7` bits of the instruction to correctly trigger the new `alu_ctrl` modes when a Zbb opcode is fetched.
3. **Modifying the Execute Stage (`alu.v`):** We added new combinatorial blocks inside the main ALU `case` statement:
   - For `cpop`, we built an adder tree that sums up all individual bits of the 32-bit input vector.
   - For `rev8`, we explicitly cross-wired the bytes (`{in[7:0], in[15:8], in[23:16], in[31:24]}`).
   - For `clz` and `ctz`, we added a priority encoder to count leading/trailing zeros.
4. **Fixing the Pipeline Bug (Async IMEM):** In our baseline, we originally used a BRAM instruction memory. BRAM has a 1-clock-cycle delay. This meant the pipeline was fetching the wrong instructions after a branch. We solved this fundamentally by converting both versions to **Combinatorial (Async) ROM**, which allowed our standard 1-flush pipeline logic to work flawlessly.

---

## 4. The Added Instructions Explained

If the examiner asks "What do these instructions specifically do?":

*   **`cpop` (Count Population):** Counts the total number of bits set to '1' in a register. *Used heavily in parity calculation and cryptography.*
*   **`clz` (Count Leading Zeros):** Counts the number of '0' bits from the Most Significant Bit (bit 31) down to the first '1' bit. 
*   **`ctz` (Count Trailing Zeros):** Counts the number of '0' bits from the Least Significant Bit (bit 0) up to the first '1' bit.
*   **`rev8` (Reverse Bytes):** Swaps the ordering of 8-bit chunks in a 32-bit register (converts Little Endian to Big Endian). *Crucial for networking code protocols like CRC.*
*   **`sext.b` (Sign-Extend Byte):** Takes the lowest 8 bits of a register, looks at its sign bit (bit 7), and copies that sign bit all the way up to bit 31.
*   **`andn` (AND NOT):** Computes essentially `A & (~B)`.
*   **`orn` (OR NOT):** Computes essentially `A | (~B)`.
*   **`xnor` (Exclusive NOR):** Computes essentially `~(A ^ B)`.

---

## 5. File Structure and Data Flow

Here is exactly what every major file does, what goes in, and what comes out:

### 1. `riscv_pipelined_top.v`
*   **Objective:** This is the heart of the processor. It wires the 5 stages together (Fetch, Decode, Execute, Memory, Writeback). It contains the hazard detection mechanism and the forwarding data multiplexers.
*   **Inputs:** `clk` (Clock), `rst` (Reset)
*   **Outputs:** Probes for `pc_out`, `alu_out`, `instr_out`, `inst_count`.

### 2. `alu.v`
*   **Objective:** The calculator of the processor. Executes math and logic.
*   **Inputs:** `a`, `b` (The two 32-bit operands), `alu_ctrl` (The 5-bit instruction operation select).
*   **Outputs:** `result` (32-bit answer), `zero` (1-bit flag used for branches).

### 3. `alu_control.v`
*   **Objective:** The translator. Takes the raw instruction bits and turns them into a specific ALU action.
*   **Inputs:** `ALUOp` (From main control), `funct3`, `funct7`, `opcode`.
*   **Outputs:** `alu_ctrl` (Tells the ALU exactly what to do).

### 4. `instr_mem.v`
*   **Objective:** This is the Instruction Memory (ROM). It holds our benchmark machine code.
*   **Inputs:** `addr` (The 32-bit Program Counter value).
*   **Outputs:** `instr` (The 32-bit raw machine instruction located at that address).

### 5. `data_mem.v`
*   **Objective:** Standard Scratchpad RAM for load and store commands.
*   **Inputs:** `clk`, `we` (Write Enable), `addr`, `wdata` (Write Data).
*   **Outputs:** `rdata` (Read Data).

### 6. `riscv_resource_wrapper.v`
*   **Objective:** An FPGA synthesis wrapper. We created this exclusively to trick Vivado into compiling the entire processor without failing the physical Zybo Z7-10 50 I/O pin limitation.
*   **Inputs:** `clk`, `rst`.
*   **Outputs:** `dummy_out` (A 1-bit XOR reduction of 192 pipeline outputs).

---

## 6. How to Handle "Tricky" Viva Questions

**Q: "If you added more logic to the ALU, why did your total FPGA LUTs decrease?"**
> "Because our instruction memory (IMEM) was implemented as combinatorial LUT-based distributed RAM. The Zbb extension allowed us to replace massive ~49-instruction software loops with single instructions, shrinking the compiled machine code footprint immensely. The LUTs saved by having a structurally smaller memory ROM far outweighed the extra LUTs consumed by the `cpop` adder tree in the ALU."

**Q: "Why did your CRC-32 instruction reduction look so different from the Popcount loop reduction?"**
> "The Popcount kernel is a direct synthetic test of the `cpop` command. The CRC-32 kernel is a fully fledged processing loop that spends most of its time iterating through 8 bytes and computing XORs with polynomials, which Zbb does not modify. The 18.68% reduction in the CRC kernel specifically came exclusively from the teardown phase: replacing the 11-instruction software byte swap with `rev8`, and the software popcount verification with `cpop`. It highlights that Zbb accelerates specific bottlenecks, not the entire sequential runtime."

**Q: "How did you verify your implementation actually worked?"**
> "We wrote assembly benchmark kernels physically into the `instr_mem.v` file. We watched the simulation waveforms (specifically register `x10` for CRC results and `x14/x2` for popcounts) natively, and compared the final pipeline output of the Baseline architecture against the output of the Zbb architecture. Since the numbers matched precisely, but the Zbb version hit the `done flag` much earlier, we proved functional accuracy."
