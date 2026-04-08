`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 10:22:39
// Design Name: 
// Module Name: imm_gen
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


module imm_gen (
    input [31:0] instr,
    output reg [31:0] imm_out
);
    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011, // I-type ALU
            7'b0000011, // loads
            7'b1100111: // jalr
                imm_out = {{20{instr[31]}}, instr[31:20]};

            7'b0100011: // S-type
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011: // B-type
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

            7'b0110111, // lui
            7'b0010111: // auipc
                imm_out = {instr[31:12], 12'b0};

            7'b1101111: // jal
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

            default:
                imm_out = 32'd0;
        endcase
    end
endmodule
