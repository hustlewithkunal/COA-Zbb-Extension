`timescale 1ns / 1ps

module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    (* rom_style = "block" *) reg [31:0] mem [0:255];
    integer i;

    initial begin
        // Default all instructions to NOP
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;   // addi x0, x0, 0

        // ------------------------------------------------
        // Final-group Zbb test: CLZ / CTZ / CPOP
        //
        // x1 = 0x00000000
        // x2 = 0x00000001
        // x3 = 0x000000F0
        // x4 = 0xFFFFFFFF
        //
        // Expected:
        // x5  = clz(x1)  = 32
        // x6  = ctz(x1)  = 32
        // x7  = cpop(x1) = 0
        //
        // x8  = clz(x2)  = 31
        // x9  = ctz(x2)  = 0
        // x10 = cpop(x2) = 1
        //
        // x11 = clz(x3)  = 24
        // x12 = ctz(x3)  = 4
        // x13 = cpop(x3) = 4
        //
        // x14 = clz(x4)  = 0
        // x15 = ctz(x4)  = 0
        // x16 = cpop(x4) = 32
        // ------------------------------------------------

        // x1 = 0x00000000
        mem[0]  = 32'h00000093; // addi x1, x0, 0

        // x2 = 0x00000001
        mem[1]  = 32'h00100113; // addi x2, x0, 1

        // x3 = 0x000000F0
        mem[2]  = 32'h0F000193; // addi x3, x0, 240

        // x4 = 0xFFFFFFFF
        mem[3]  = 32'hFFF00213; // addi x4, x0, -1

        // clz/ctz/cpop on x1
        mem[4]  = 32'h60009293; // clz  x5,  x1
        mem[5]  = 32'h60109313; // ctz  x6,  x1
        mem[6]  = 32'h60209393; // cpop x7,  x1

        // clz/ctz/cpop on x2
        mem[7]  = 32'h60011413; // clz  x8,  x2
        mem[8]  = 32'h60111493; // ctz  x9,  x2
        mem[9]  = 32'h60211513; // cpop x10, x2

        // clz/ctz/cpop on x3
        mem[10] = 32'h60019593; // clz  x11, x3
        mem[11] = 32'h60119613; // ctz  x12, x3
        mem[12] = 32'h60219693; // cpop x13, x3

        // clz/ctz/cpop on x4
        mem[13] = 32'h60021713; // clz  x14, x4
        mem[14] = 32'h60121793; // ctz  x15, x4
        mem[15] = 32'h60221813; // cpop x16, x4

        // loop forever
        mem[16] = 32'h0000006F; // jal x0, 0
    end

    always @(posedge clk) begin
        instr <= mem[addr[31:2]];
    end

endmodule