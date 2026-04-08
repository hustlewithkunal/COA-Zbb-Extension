`timescale 1ns / 1ps

module control_unit (
    input  [6:0] opcode,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,
    output reg [1:0] wb_sel,       // 00=ALU, 01=MEM, 10=PC+4
    output reg branch,
    output reg jump,
    output reg jalr,
    output reg use_pc,
    output reg [1:0] alu_op
);
    always @(*) begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        alu_src   = 1'b0;
        wb_sel    = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;
        use_pc    = 1'b0;
        alu_op    = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0;
                wb_sel    = 2'b00;
                alu_op    = 2'b10;
            end

            7'b0010011: begin // I-type arithmetic
                reg_write = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = 2'b00;
                alu_op    = 2'b11;
            end

            7'b0000011: begin // LOAD
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = 2'b01;
                alu_op    = 2'b00;
            end

            7'b0100011: begin // STORE
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end

            7'b1100011: begin // BRANCH
                branch    = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b01;
            end

            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump      = 1'b1;
                wb_sel    = 2'b10;
                use_pc    = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end

            7'b1100111: begin // JALR
                reg_write = 1'b1;
                jalr      = 1'b1;
                wb_sel    = 2'b10;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end

            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = 2'b00;
                alu_op    = 2'b11;
            end

            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src   = 1'b1;
                use_pc    = 1'b1;
                wb_sel    = 2'b00;
                alu_op    = 2'b00;
            end

            default: begin
            end
        endcase
    end
endmodule