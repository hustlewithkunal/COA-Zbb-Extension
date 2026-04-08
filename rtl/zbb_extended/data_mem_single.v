`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 11:17:55
// Design Name: 
// Module Name: data_mem_single
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


module data_mem_single (
    input clk,
    input mem_read,
    input mem_write,
    input [2:0] funct3,
    input [31:0] addr,
    input [31:0] write_data,
    output reg [31:0] read_data
);
    reg [7:0] mem [0:1023];
    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'd0;
    end

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: read_data = {{24{mem[addr][7]}}, mem[addr]}; // LB
                3'b001: read_data = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]}; // LH
                3'b010: read_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}; // LW
                3'b100: read_data = {24'd0, mem[addr]}; // LBU
                3'b101: read_data = {16'd0, mem[addr+1], mem[addr]}; // LHU
                default: read_data = 32'd0;
            endcase
        end else begin
            read_data = 32'd0;
        end
    end

    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[addr] <= write_data[7:0]; // SB
                3'b001: begin
                    mem[addr]   <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                end
                3'b010: begin
                    mem[addr]   <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                    mem[addr+3] <= write_data[31:24];
                end
                default: begin end
            endcase
        end
    end
endmodule
