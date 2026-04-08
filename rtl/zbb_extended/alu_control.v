`timescale 1ns / 1ps

module alu_control (
    input [1:0] alu_op,
    input [2:0] funct3,
    input [6:0] funct7,
    input [6:0] opcode,
    input [4:0] funct5,
    output reg [4:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 5'b00000; // ADD for load/store/auipc/jal/jalr
            2'b01: alu_ctrl = 5'b00001; // branch compare base

            2'b10: begin
                // R-type base + R-type Zbb ops
                if (opcode == 7'b0110011) begin
                    case ({funct7, funct3})
                        {7'b0000000,3'b000}: alu_ctrl = 5'b00000; // ADD
                        {7'b0100000,3'b000}: alu_ctrl = 5'b00001; // SUB
                        {7'b0000000,3'b111}: alu_ctrl = 5'b00010; // AND
                        {7'b0000000,3'b110}: alu_ctrl = 5'b00011; // OR
                        {7'b0000000,3'b100}: alu_ctrl = 5'b00100; // XOR
                        {7'b0000000,3'b010}: alu_ctrl = 5'b00101; // SLT
                        {7'b0000000,3'b011}: alu_ctrl = 5'b00110; // SLTU
                        {7'b0000000,3'b001}: alu_ctrl = 5'b00111; // SLL
                        {7'b0000000,3'b101}: alu_ctrl = 5'b01000; // SRL
                        {7'b0100000,3'b101}: alu_ctrl = 5'b01001; // SRA

                        {7'b0100000,3'b111}: alu_ctrl = 5'b01011; // ANDN
                        {7'b0100000,3'b110}: alu_ctrl = 5'b01100; // ORN
                        {7'b0100000,3'b100}: alu_ctrl = 5'b01101; // XNOR

                        default:              alu_ctrl = 5'b00000;
                    endcase
                end
                else begin
                    alu_ctrl = 5'b00000;
                end
            end

            2'b11: begin
                // I-type arithmetic + LUI + unary Zbb OP-IMM
                if (opcode == 7'b0110111) begin
                    alu_ctrl = 5'b01010; // LUI => PASS B
                end
                else if (opcode == 7'b0010011 && funct7 == 7'b0110000) begin
                    case ({funct5, funct3})
                        {5'b00000,3'b001}: alu_ctrl = 5'b10000; // CLZ
                        {5'b00001,3'b001}: alu_ctrl = 5'b10001; // CTZ
                        {5'b00010,3'b001}: alu_ctrl = 5'b10010; // CPOP
                        {5'b00100,3'b001}: alu_ctrl = 5'b01110; // SEXT.B
                        {5'b11000,3'b101}: alu_ctrl = 5'b01111; // REV8 (RV32)
                        default:           alu_ctrl = 5'b00000;
                    endcase
                end
                else begin
                    case (funct3)
                        3'b000: alu_ctrl = 5'b00000; // ADDI
                        3'b111: alu_ctrl = 5'b00010; // ANDI
                        3'b110: alu_ctrl = 5'b00011; // ORI
                        3'b100: alu_ctrl = 5'b00100; // XORI
                        3'b010: alu_ctrl = 5'b00101; // SLTI
                        3'b011: alu_ctrl = 5'b00110; // SLTIU
                        3'b001: alu_ctrl = 5'b00111; // SLLI
                        3'b101: begin
                            if (funct7 == 7'b0100000)
                                alu_ctrl = 5'b01001; // SRAI
                            else
                                alu_ctrl = 5'b01000; // SRLI
                        end
                        default: alu_ctrl = 5'b00000;
                    endcase
                end
            end

            default: alu_ctrl = 5'b00000;
        endcase
    end
endmodule