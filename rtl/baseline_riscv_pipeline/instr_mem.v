`timescale 1ns / 1ps

module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    // BRAM-friendly instruction ROM
    (* rom_style = "block" *) reg [31:0] mem [0:255];
    integer i;

    initial begin
        // Default all instructions to NOP: addi x0, x0, 0
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;

        // Example program (same style as your previous file)
        mem[0] = 32'h00500093; // addi x1, x0, 5
        mem[1] = 32'h00308113; // addi x2, x1, 3
        mem[2] = 32'h00410193; // addi x3, x2, 4
        mem[3] = 32'h00118233; // add  x4, x3, x1
        mem[4] = 32'h002202B3; // add  x5, x4, x2
        mem[5] = 32'h00502023; // sw   x5, 0(x0)
        mem[6] = 32'h00002303; // lw   x6, 0(x0)
        mem[7] = 32'h001303B3; // add  x7, x6, x1
        mem[8] = 32'h0000006F; // jal  x0, 0
    end

    // Synchronous read -> FPGA/BRAM friendly
    always @(posedge clk) begin
        instr <= mem[addr[31:2]];
    end

endmodule