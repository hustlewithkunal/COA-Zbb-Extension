`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 11:17:55
// Design Name: 
// Module Name: riscv_single_cycle_top
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


module riscv_single_cycle_top (
    input clk,
    input rst,
    output [31:0] pc_out,
    output [31:0] instr_out,
    output [31:0] alu_out,
    output [31:0] wb_out
);

    // -------------------------
    // PC and instruction fetch
    // -------------------------
    wire [31:0] pc_current;
    reg  [31:0] pc_next;
    wire [31:0] instr;
    wire [31:0] pc_plus4;

    assign pc_plus4 = pc_current + 32'd4;

    pc_reg PC (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .pc_next(pc_next),
        .pc(pc_current)
    );

    instr_mem_single IMEM (
        .addr(pc_current),
        .instr(instr)
    );

    // -------------------------
    // Decode fields
    // -------------------------
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    // -------------------------
    // Control
    // -------------------------
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire [1:0] wb_sel;
    wire branch;
    wire jump;
    wire jalr;
    wire use_pc;
    wire [1:0] alu_op;

    control_unit_single CU (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .wb_sel(wb_sel),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .use_pc(use_pc),
        .alu_op(alu_op)
    );

    // -------------------------
    // Register file
    // -------------------------
    wire [31:0] reg_rdata1;
    wire [31:0] reg_rdata2;
    wire [31:0] wb_write_data;

    reg_file RF (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(wb_write_data),
        .read_data1(reg_rdata1),
        .read_data2(reg_rdata2)
    );

    // -------------------------
    // Immediate generation
    // -------------------------
    wire [31:0] imm;

    imm_gen_single IMMGEN (
        .instr(instr),
        .imm_out(imm)
    );

    // -------------------------
    // ALU control
    // -------------------------
    wire [3:0] alu_ctrl;

    alu_control_single ALUCTRL (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .alu_ctrl(alu_ctrl)
    );

    // -------------------------
    // ALU operand selection
    // -------------------------
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;
    wire [31:0] alu_result;
    wire alu_zero;

    assign alu_in_a = (use_pc) ? pc_current : reg_rdata1;
    assign alu_in_b = (alu_src) ? imm : reg_rdata2;

    alu ALU (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );

    // -------------------------
    // Branch decision
    // -------------------------
    reg branch_taken;
    reg [31:0] branch_target;

    always @(*) begin
        branch_taken  = 1'b0;
        branch_target = pc_plus4;

        if (branch) begin
            case (funct3)
                3'b000: branch_taken = (reg_rdata1 == reg_rdata2);                     // BEQ
                3'b001: branch_taken = (reg_rdata1 != reg_rdata2);                     // BNE
                3'b100: branch_taken = ($signed(reg_rdata1) <  $signed(reg_rdata2));   // BLT
                3'b101: branch_taken = ($signed(reg_rdata1) >= $signed(reg_rdata2));   // BGE
                3'b110: branch_taken = (reg_rdata1 < reg_rdata2);                      // BLTU
                3'b111: branch_taken = (reg_rdata1 >= reg_rdata2);                     // BGEU
                default: branch_taken = 1'b0;
            endcase

            if (branch_taken)
                branch_target = pc_current + imm;
        end

        if (jump) begin
            branch_taken  = 1'b1;
            branch_target = pc_current + imm; // JAL
        end

        if (jalr) begin
            branch_taken  = 1'b1;
            branch_target = (reg_rdata1 + imm) & 32'hFFFFFFFE; // JALR
        end
    end

    // -------------------------
    // Data memory
    // -------------------------
    wire [31:0] mem_read_data;

    data_mem_single DMEM (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(alu_result),
        .write_data(reg_rdata2),
        .read_data(mem_read_data)
    );

    // -------------------------
    // Write back
    // -------------------------
    assign wb_write_data =
        (wb_sel == 2'b00) ? alu_result    :
        (wb_sel == 2'b01) ? mem_read_data :
        (wb_sel == 2'b10) ? pc_plus4      :
                            32'd0;

    // -------------------------
    // Next PC
    // -------------------------
    always @(*) begin
        if (branch_taken)
            pc_next = branch_target;
        else
            pc_next = pc_plus4;
    end

    // -------------------------
    // Outputs for synthesis/debug
    // -------------------------
    assign pc_out    = pc_current;
    assign instr_out = instr;
    assign alu_out   = alu_result;
    assign wb_out    = wb_write_data;

endmodule
