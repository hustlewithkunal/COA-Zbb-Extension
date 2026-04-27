`timescale 1ns / 1ps

// =====================================================================
// RISC-V Resource Benchmark Wrapper
//
// Purpose:
// This wrapper is used ONLY for accurately measuring resource utilization 
// and timing of the pipeline without hitting FPGA I/O pin limits.
// 
// Why do we need this?
// The riscv_pipelined_top module has six 32-bit output ports (192 pins). 
// The Zybo Z7-10 only has ~50 available I/O pins. If we try to synthesize
// the pipelined top directly, Vivado fails with a [Place 30-58] error.
//
// How this works:
// This module instantiates the pipeline and XOR-reduces all 192 output 
// bits into a single 1-bit output pin (`dummy_out`). 
//
// Benefits:
// 1. Fits on the FPGA (uses exactly 1 output pin and 2 input pins).
// 2. Prevents Vivado from optimizing away the pipeline logic as "dead code".
// 3. Allows for a true apples-to-apples comparison of core logic.
// =====================================================================

module riscv_resource_wrapper (
    input  wire clk,
    input  wire rst,
    output wire dummy_out
);

    // Wires to connect to the pipeline outputs
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_out;
    wire [31:0] wb_out;
    wire [31:0] debug_x5;
    wire [31:0] inst_count;

    // Instantiate the pipeline core
    riscv_pipelined_top core (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_out(alu_out),
        .wb_out(wb_out),
        .debug_x5(debug_x5),
        .inst_count(inst_count)
    );

    // XOR reduction of all output signals
    // This forces Vivado to synthesize and place the entire pipeline 
    // because every bit technically influences the final output.
    wire [31:0] combined_out = pc_out ^ instr_out ^ alu_out ^ wb_out ^ debug_x5 ^ inst_count;
    
    // Final single-bit reduction
    assign dummy_out = ^combined_out;

endmodule
