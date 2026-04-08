`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 11:18:24
// Design Name: 
// Module Name: tb_riscv_single_cycle
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


module tb_riscv_single_cycle;

    reg clk;
    reg rst;

    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_out;
    wire [31:0] wb_out;

    riscv_single_cycle_top DUT (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_out(alu_out),
        .wb_out(wb_out)
    );

    wire [31:0] x1 = DUT.RF.regs[1];
    wire [31:0] x2 = DUT.RF.regs[2];
    wire [31:0] x3 = DUT.RF.regs[3];
    wire [31:0] x4 = DUT.RF.regs[4];
    wire [31:0] x5 = DUT.RF.regs[5];
    wire [31:0] x6 = DUT.RF.regs[6];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #20;
        rst = 0;
        #300;
        $finish;
    end

    initial begin
        $display("--------------------------------------------------------------------------------");
        $display(" time   rst   pc        instr      alu        wb         x1 x2 x3 x4 x5 x6");
        $display("--------------------------------------------------------------------------------");
        $monitor("%4t   %b   %8h  %8h  %8h  %8h   %0d %0d %0d %0d %0d %0d",
                 $time, rst, pc_out, instr_out, alu_out, wb_out, x1, x2, x3, x4, x5, x6);
    end

endmodule
