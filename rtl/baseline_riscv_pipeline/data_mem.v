`timescale 1ns / 1ps

module data_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000000;

        // Test data for CRC program
        // byte addr 200 = word addr 50
        mem[50] = 32'hD8C7B6A5; // bytes: [200]=0xA5 [201]=0xB6 [202]=0xC7 [203]=0xD8
        mem[51] = 32'h1C0BFAE9; // bytes: [204]=0xE9 [205]=0xFA [206]=0x0B [207]=0x1C
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[31:2]] <= write_data;
    end

    // Asynchronous read - pipeline's MEM/WB register provides the timing
    always @(*) begin
        if (mem_read)
            read_data = mem[addr[31:2]];
        else
            read_data = 32'h00000000;
    end

endmodule