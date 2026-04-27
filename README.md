# Design and Evaluation of a Zbb-Extended 5-Stage RISC-V Pipelined Processor
This repository contains the RTL, testbenches, reporting data, and LaTeX documentation for a standard 5-stage pipelined RISC-V soft-core, heavily optimized with a subset of the **Zbb (Bit Manipulation) Extension**.

## 📌 Problem Statement
Modern cryptographic, networking, and error-correction algorithms (like CRC-32) rely heavily on bit-wise operations: population counts (counting set bits), byte reversals (endianness swapping), and leading/trailing zero tracking. 

In a standard RISC-V integer pipeline, basic operations like `popcount` or `byte-swap` must be implemented entirely in software using expansive unrolled loops consisting of `shifts`, `AND masks`, and `OR accumulations`. This causes:
1. **High execution latency** (massive dynamic instruction counts).
2. **Poor code density** (inflated instruction memory footprint).
3. **Reduced throughput** for critical kernels.

Our goal was to integrate the RISC-V Zbb extension directly into the ALU/Decode pipeline stages to solve these software bottlenecks natively in hardware, and to synthesize the core on an FPGA to measure the true hardware cost-to-software benefit ratio.

---

## 🛠️ Our Solution
We implemented a ground-up 5-Stage Pipelined RISC-V CPU (IF, ID, EX, MEM, WB) and built two separate architectural profiles for an apples-to-apples performance comparison:
*   **Baseline Profile:** Standard RISC-V I-extension.
*   **Zbb Profile:** Augmented with hardware for `clz`, `ctz`, `cpop`, `rev8`, `sext.b`, `andn`, `orn`, and `xnor`.

### Key Technical Challenges Solved:
1.  **ALU Datapath Expansion:** We extended the Execute stage to natively support combinatorial 32-bit adder trees for `cpop`, Priority Encoders for `clz`/`ctz`, and cross-wiring for `rev8`.
2.  **Pipeline Resolving:** Upgraded to an asynchronous/combinatorial Instruction Memory (IMEM) mapping. This eradicated a severe BRAM 1-cycle latency bug that consistently broke branch target calculation and caused pipeline deadlock.
3.  **Benchmarking Accuracy:** Since an FPGA has limited I/O (the Zybo Z7-10 has ~50 pins) and our pipeline exposed 192 output bits across its internal stages, standard logic synthesis would optimize the CPU entirely away ("dead code path"). We designed a `riscv_resource_wrapper` that mathematically XOR-reduces the 192 bits down to 1 output pin, forcing Vivado to synthesize the full processor core for completely accurate LUT/FF performance reports.

---

## 📊 Benchmarking Results & Key Insights
We compiled two benchmark kernels: an raw **Unrolled Popcount Algorithm** and a **CRC-32 Teardown Module** (incorporating a byte-swap to convert endianness followed by a parity popcount).

### 1. Dynamic Instruction Count
| Benchmark Algorithm | Baseline (Inst. Count) | ZBB Target (Inst. Count) | Reduction Result |
| :--- | :---: | :---: | :---: |
| **Popcount Loop** | 27 Instructions | 4 Instructions | **`85.19% Reduction`** |
| **CRC-32 Processing** | 455 Instructions | 370 Instructions | **`18.68% Reduction`** |

*Insight:* By replacing a ~49-instruction software loop with a single hardware `cpop` instruction, and an 11-instruction software sequence with `rev8`, execution time drops fundamentally.

### 2. FPGA Resource and Timing Post-Implementation
Target Board: **Zybo Z7-10 (xc7z010clg400-1)** | Clock Target: **100MHz (10 ns)**

| Metric | Baseline Core | Zbb Core | Net Change |
| :--- | :--- | :--- | :--- |
| **LUT Logic Size** | 1389 | 1247 | **`-10.22%`** |
| **Flip-Flops** | 866 | 812 | **`-6.24%`** |
| **Crit. Path Penalty** | (Setup: 0.224ns) | (Setup: 0.217ns) | **`-0.007ns`** |

*Hardware Insight:* Normally, adding logic elements to the ALU inflates LUT size. However, the exact opposite happened! Because our ZBB assembly instructions condense massive software branches into just a few lines of code, Vivado was able to drastically down-scale the instantiated Instruction Memory ROM. **The savings in code density completely offset the logic complexity of the ALU extension**, shrinking the complete core by ~10% effectively for "free" while incurring an unnoticeable 7-picosecond critical-path penalty.

---

## 🚀 Setup Instructions (Xilinx Vivado)

If you want to run the synthesis or simulations yourself, follow these steps:

### 1. Project Initialization
1. Open Xilinx Vivado (2020.1 or later recommended).
2. Create a new RTL Project.
3. When selecting the default part/board, search for and select the **Zybo Z7-10** (`xc7z010clg400-1`).

### 2. Adding Sources & Choosing the Core Structure
Since this repository holds *both* the baseline and ZBB pipelines, you'll need to add the correct files to your project depending on what you want to test.
*   **For Baseline Synthesis:** Add all `.v` files located natively inside `rtl/baseline_riscv_pipeline/`.
*   **For Zbb Synthesis:** Add all `.v` files located natively inside `rtl/zbb_extended/`.

### 3. Simulation (`Run Behavioral Simulation`)
We have pre-written an instruction ROM with our benchmark algorithms nested natively inside `instr_mem.v`. 
1. Open `instr_mem.v` and look at the top lines.
2. Ensure you uncomment the ` \`define PROGRAM_CRC ` or ` \`define PROGRAM_POPCOUNT ` macro to choose which benchmark program is loaded into memory.
3. Add the corresponding testbench from `tb/`.
4. Right Click `tb_riscv_pipelined.v` $\rightarrow$ **Set as Top**.
5. Click **Run Behavioral Simulation**.

### 4. Implementation and Resource Verification
To duplicate our exact LUT / FF logic reports without Vivado destroying the design due to I/O pin limitations:
1. Make sure `riscv_resource_wrapper.v` is added to your Design Sources.
2. Right Click `riscv_resource_wrapper.v` $\rightarrow$ **Set as Top**.
3. Under the constraints manager (XDC), add a simple clock constraint:
   `create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]`
4. Click **Run Implementation**.b
5. When finished, open the Implemented Design and run `report_utilization` and `report_timing_summary` to view the core scaling.

### 5. On-Silicon Hardware Validation (ILA)
To prove the physical execution of the CPU on actual silicon, we embedded an **Integrated Logic Analyzer (ILA)** core into the top-level FPGA design (`riscv_fpga_top.v`). 
1. The ILA probes critical pipeline signals: `pc_out`, `instr_out`, `alu_out`, and `wb_out`.
2. The trigger is set to `0x0000006F` (`jal x0, 0`), which captures the exact moment the benchmark finishes execution.
3. Once triggered, the physical waveform is extracted directly from the Zybo Z7-10 chip at 100MHz, matching the behavioral simulation perfectly (including NOP pipeline bubbles) and guaranteeing structural success.

---

*Author:* Kunal Mittal (B24491) - IIT Mandi