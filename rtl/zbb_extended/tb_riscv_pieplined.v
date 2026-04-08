`timescale 1ns / 1ps

module tb_riscv_pipelined;

    reg clk;
    reg rst;

    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_out;
    wire [31:0] wb_out;

    riscv_pipelined_top DUT (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_out(alu_out),
        .wb_out(wb_out)
    );

    // -----------------------------
    // IF stage signals
    // -----------------------------
    wire [31:0] pc_current      = DUT.pc_current;
    wire [31:0] pc_next         = DUT.pc_next;
    wire [31:0] instr_if        = DUT.instr_if;

    // -----------------------------
    // IF/ID pipeline register
    // -----------------------------
    wire [31:0] if_id_pc        = DUT.if_id_pc;
    wire [31:0] if_id_pc4       = DUT.if_id_pc4;
    wire [31:0] if_id_instr     = DUT.if_id_instr;

    // -----------------------------
    // ID stage signals
    // -----------------------------
    wire [4:0]  if_id_rs1       = DUT.if_id_rs1;
    wire [4:0]  if_id_rs2       = DUT.if_id_rs2;
    wire [4:0]  if_id_rd        = DUT.if_id_rd;
    wire [6:0]  if_id_opcode    = DUT.if_id_opcode;
    wire [2:0]  if_id_funct3    = DUT.if_id_funct3;
    wire [6:0]  if_id_funct7    = DUT.if_id_funct7;

    wire [31:0] reg_rdata1      = DUT.reg_rdata1;
    wire [31:0] reg_rdata2      = DUT.reg_rdata2;
    wire [31:0] imm_id          = DUT.imm_id;

    // ID control signals
    wire        ctrl_reg_write  = DUT.ctrl_reg_write;
    wire        ctrl_mem_read   = DUT.ctrl_mem_read;
    wire        ctrl_mem_write  = DUT.ctrl_mem_write;
    wire        ctrl_alu_src    = DUT.ctrl_alu_src;
    wire [1:0]  ctrl_wb_sel     = DUT.ctrl_wb_sel;
    wire        ctrl_branch     = DUT.ctrl_branch;
    wire        ctrl_jump       = DUT.ctrl_jump;
    wire        ctrl_jalr       = DUT.ctrl_jalr;
    wire        ctrl_use_pc     = DUT.ctrl_use_pc;
    wire [1:0]  ctrl_alu_op     = DUT.ctrl_alu_op;

    // -----------------------------
    // EX / MEM / WB stage signals
    // -----------------------------
    wire [31:0] alu_result_ex   = DUT.alu_result_ex;
    wire [31:0] mem_read_data   = DUT.mem_read_data;
    wire [31:0] wb_write_data   = DUT.wb_write_data;

    wire        stall_pipeline  = DUT.stall_pipeline;
    wire        branch_taken_ex = DUT.branch_taken_ex;
    wire [1:0]  forward_a       = DUT.forward_a;
    wire [1:0]  forward_b       = DUT.forward_b;

    wire [4:0]  id_ex_rd        = DUT.id_ex_rd;
    wire [4:0]  ex_mem_rd       = DUT.ex_mem_rd;
    wire [4:0]  mem_wb_rd       = DUT.mem_wb_rd;

    // -----------------------------
    // Register file contents
    // -----------------------------
    wire [31:0] x1 = DUT.RF.regs[1];
    wire [31:0] x2 = DUT.RF.regs[2];
    wire [31:0] x3 = DUT.RF.regs[3];
    wire [31:0] x4 = DUT.RF.regs[4];
    wire [31:0] x5 = DUT.RF.regs[5];
    wire [31:0] x6 = DUT.RF.regs[6];
    wire [31:0] x7 = DUT.RF.regs[7];
    wire [31:0] x8  = DUT.RF.regs[8];
    wire [31:0] x9  = DUT.RF.regs[9];
    wire [31:0] x10 = DUT.RF.regs[10];
    wire [31:0] x11 = DUT.RF.regs[11];
    wire [31:0] x12 = DUT.RF.regs[12];
    wire [31:0] x13 = DUT.RF.regs[13];
    wire [31:0] x14 = DUT.RF.regs[14];
    wire [31:0] x15 = DUT.RF.regs[15];
    wire [31:0] x16 = DUT.RF.regs[16];

    // -----------------------------
    // Optional: word-level data memory probe
    // Use this only if your data memory instance name is actually DMEM
    // and your top module instantiated it like: data_mem DMEM (...)
    // -----------------------------
    // wire [31:0] mem_word0 = DUT.DMEM.mem[0];

    // -----------------------------
    // Clock
    // -----------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------------
    // Reset and runtime
    // -----------------------------
    initial begin
        rst = 1;
        #20;
        rst = 0;

        #300;
        $finish;
    end

    // -----------------------------
    // Console monitor
    // -----------------------------
    initial begin
        $display("------------------------------------------------------------------------------------------------------------------------------------------------");
        $display("time rst pc_current instr_if   if_id_instr rs1 rs2 rd reg1     reg2     imm      alu_result mem_data  wb_data   x1 x2 x3 x4 x5 x6 x7");
        $display("------------------------------------------------------------------------------------------------------------------------------------------------");

        $monitor("%4t  %b   %8h %8h %8h %2d %2d %2d %8h %8h %8h %8h %8h %8h %0d %0d %0d %0d %0d %0d %0d",
                 $time, rst,
                 pc_current,
                 instr_if,
                 if_id_instr,
                 if_id_rs1,
                 if_id_rs2,
                 if_id_rd,
                 reg_rdata1,
                 reg_rdata2,
                 imm_id,
                 alu_result_ex,
                 mem_read_data,
                 wb_write_data,
                 x1, x2, x3, x4, x5, x6, x7);
    end

endmodule