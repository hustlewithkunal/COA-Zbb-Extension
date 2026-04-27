`timescale 1ns / 1ps

module tb_riscv_pipelined;

    reg clk;
    reg rst;

    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_out;
    wire [31:0] wb_out;

    wire [31:0] inst_count;

    riscv_pipelined_top DUT (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_out(alu_out),
        .wb_out(wb_out),
        .inst_count(inst_count)
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
    wire [31:0] x31 = DUT.RF.regs[31];

    // -----------------------------
    // Optional: word-level data memory probe
    // Use this only if your data memory instance name is actually DMEM
    // and your top module instantiated it like: data_mem DMEM (...)
    // -----------------------------
    // wire [31:0] mem_word0 = DUT.DMEM.mem[0];

    // --------------------------------------------------
    // Clock: 10 ns period
    // --------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------
    // Reset and run
    // The CRC program needs ~650 cycles (~6500 ns) to
    // complete.  Run this simulation with "Run All" in
    // Vivado (NOT "Run for 1000 ns") so $finish fires.
    // --------------------------------------------------
    initial begin
        rst = 1;
        #20;
        rst = 0;

        // Wait until the program sets x31=1 (done flag)
        wait (x31 === 32'd1);
        #20;
        $display("=== CRC-32 BASELINE DONE at %0t ns ===", $time);
        $display("  CRC-32 result (x10) = 0x%08X", DUT.RF.regs[10]);
        $display("  Instruction count   = %0d",     inst_count);
        $finish;
    end

    // Safety timeout - fires only if program fails to complete
    initial begin
        #100000;
        $display("TIMEOUT at %0t: x31=%0d x6=%0d x5=0x%h",
                 $time, DUT.RF.regs[31], DUT.RF.regs[6], DUT.RF.regs[5]);
        $finish;
    end

    // === DIAGNOSTIC: verify correct source file is compiled ===
    // Print instr_mem[18] and [19] - if the fix is compiled correctly:
    //   mem[18] should be 0x00100F93 (addi x31, x0, 1)
    //   mem[19] should be 0x00000013 (NOP)
    //   mem[20] should be 0x0000006F (jal x0, 0)
    initial begin
        #1; // wait 1 ns so initial blocks settle
        $display("=== INSTR MEM CONTENTS (verify correct compile) ===");
        $display("  mem[17]=0x%08X (expect 0xFFF2C513 xori x10)", DUT.IMEM.mem[17]);
        $display("  mem[18]=0x%08X (expect 0x00100F93 addi x31)",  DUT.IMEM.mem[18]);
        $display("  mem[19]=0x%08X (expect 0x00000013 NOP)",        DUT.IMEM.mem[19]);
        $display("  mem[20]=0x%08X (expect 0x0000006F jal)",        DUT.IMEM.mem[20]);
        $display("  IF branch flush bug check - 2-flush lines removed? (check riscv_pipelined_top.v)");
    end

    // Heartbeat: print x6 (outer byte counter) every 500 ns
    // so you can confirm the loop is running in the console
    always #500 begin
        if (!rst)
            $display("  t=%0t: x5=0x%h x6=%0d x7=%0d x13=%0d",
                     $time,
                     DUT.RF.regs[5],
                     DUT.RF.regs[6],
                     DUT.RF.regs[7],
                     DUT.RF.regs[13]);
    end

endmodule