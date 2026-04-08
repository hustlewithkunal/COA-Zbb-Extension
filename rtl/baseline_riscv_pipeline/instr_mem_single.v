`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 11:17:55
// Design Name: 
// Module Name: instr_mem_single
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module instr_mem_single (
    input  [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013; // NOP

        // Demo program
        mem[0]  = 32'h00A00093; // addi x1, x0, 10
        mem[1]  = 32'h01400113; // addi x2, x0, 20
        mem[2]  = 32'h002081B3; // add x3, x1, x2
        mem[3]  = 32'h00302023; // sw x3, 0(x0)
        mem[4]  = 32'h00002203; // lw x4, 0(x0)
        mem[5]  = 32'h00520293; // addi x5, x4, 5
        mem[6]  = 32'h00028463; // beq x5, x0, +8
        mem[7]  = 32'h00100313; // addi x6, x0, 1
        mem[8]  = 32'h0000006F; // jal x0, 0
    end

    assign instr = mem[addr[31:2]];
endmodule
