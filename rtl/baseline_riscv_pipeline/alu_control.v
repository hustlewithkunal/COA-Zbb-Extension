`timescale 1ns / 1ps

module alu_control (
    input [1:0] alu_op,
    input [2:0] funct3,
    input [6:0] funct7,
    input [6:0] opcode,
    output reg [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // ADD for load/store/auipc/jal/jalr

            2'b01: alu_ctrl = 4'b0001; // SUB-style compare basis for branch

            2'b10: begin // R-type
                case ({funct7, funct3})
                    {7'b0000000,3'b000}: alu_ctrl = 4'b0000; // ADD
                    {7'b0100000,3'b000}: alu_ctrl = 4'b0001; // SUB
                    {7'b0000000,3'b111}: alu_ctrl = 4'b0010; // AND
                    {7'b0000000,3'b110}: alu_ctrl = 4'b0011; // OR
                    {7'b0000000,3'b100}: alu_ctrl = 4'b0100; // XOR
                    {7'b0000000,3'b010}: alu_ctrl = 4'b0101; // SLT
                    {7'b0000000,3'b011}: alu_ctrl = 4'b0110; // SLTU
                    {7'b0000000,3'b001}: alu_ctrl = 4'b0111; // SLL
                    {7'b0000000,3'b101}: alu_ctrl = 4'b1000; // SRL
                    {7'b0100000,3'b101}: alu_ctrl = 4'b1001; // SRA
                    default:              alu_ctrl = 4'b0000;
                endcase
            end

            2'b11: begin // I-type arithmetic + LUI
                if (opcode == 7'b0110111) begin
                    alu_ctrl = 4'b1010; // LUI => PASS B
                end else begin
                    case (funct3)
                        3'b000: alu_ctrl = 4'b0000; // ADDI
                        3'b111: alu_ctrl = 4'b0010; // ANDI
                        3'b110: alu_ctrl = 4'b0011; // ORI
                        3'b100: alu_ctrl = 4'b0100; // XORI
                        3'b010: alu_ctrl = 4'b0101; // SLTI
                        3'b011: alu_ctrl = 4'b0110; // SLTIU
                        3'b001: alu_ctrl = 4'b0111; // SLLI
                        3'b101: begin
                            if (funct7 == 7'b0100000)
                                alu_ctrl = 4'b1001; // SRAI
                            else
                                alu_ctrl = 4'b1000; // SRLI
                        end
                        default: alu_ctrl = 4'b0000;
                    endcase
                end
            end

            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule