`timescale 1ns / 1ps

module riscv_pipelined_top (
    input clk,
    input rst,
    output [31:0] pc_out,
    output [31:0] instr_out,
    output [31:0] alu_out,
    output [31:0] wb_out,

    output reg [31:0] debug_x5,
    output reg [31:0] debug_x6,
    output reg [31:0] debug_x7,
    output reg [31:0] debug_x8,
    output reg [31:0] debug_x9,
    output reg [31:0] debug_x10,
    output reg [31:0] debug_x11,
    output reg [31:0] debug_x12,
    output reg [31:0] debug_x13,
    output reg [31:0] debug_x14,
    output reg [31:0] debug_x15,
    output reg [31:0] debug_x16,
    output reg [31:0] inst_count
);
    // =========================================================
    // IF STAGE
    // =========================================================
    wire [31:0] pc_current;
    wire [31:0] instr_if;
    wire [31:0] pc_plus4_if;
    reg  [31:0] pc_next;

    wire pc_enable;
    assign pc_plus4_if = pc_current + 32'd4;

    pc_reg PC (
        .clk(clk),
        .rst(rst),
        .en(pc_enable),
        .pc_next(pc_next),
        .pc(pc_current)
    );

    instr_mem IMEM (
        .clk(clk),
        .addr(pc_current),
        .instr(instr_if)
    );

    // =========================================================
    // IF/ID PIPELINE REG
    // =========================================================
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc4;
    reg [31:0] if_id_instr;

    wire if_id_enable;
    reg flush_if_id;

    wire [4:0] if_id_rs1 = if_id_instr[19:15];
    wire [4:0] if_id_rs2 = if_id_instr[24:20];
    wire [4:0] if_id_rd  = if_id_instr[11:7];
    wire [6:0] if_id_opcode = if_id_instr[6:0];
    wire [2:0] if_id_funct3 = if_id_instr[14:12];
    wire [6:0] if_id_funct7 = if_id_instr[31:25];
    wire [4:0] if_id_funct5 = if_id_instr[24:20];

    // =========================================================
    // ID STAGE
    // =========================================================
    wire ctrl_reg_write, ctrl_mem_read, ctrl_mem_write, ctrl_alu_src;
    wire ctrl_branch, ctrl_jump, ctrl_jalr, ctrl_use_pc;
    wire [1:0] ctrl_wb_sel;
    wire [1:0] ctrl_alu_op;

    control_unit CU (
        .opcode(if_id_opcode),
        .reg_write(ctrl_reg_write),
        .mem_read(ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .alu_src(ctrl_alu_src),
        .wb_sel(ctrl_wb_sel),
        .branch(ctrl_branch),
        .jump(ctrl_jump),
        .jalr(ctrl_jalr),
        .use_pc(ctrl_use_pc),
        .alu_op(ctrl_alu_op)
    );

    wire [31:0] reg_rdata1, reg_rdata2;
    wire [31:0] wb_write_data;
    reg mem_wb_reg_write;
    reg [4:0] mem_wb_rd;

    reg_file_pipe_bypass RF (
        .clk(clk),
        .reg_write(mem_wb_reg_write),
        .rs1(if_id_rs1),
        .rs2(if_id_rs2),
        .rd(mem_wb_rd),
        .write_data(wb_write_data),
        .read_data1(reg_rdata1),
        .read_data2(reg_rdata2)
    );

    wire [31:0] imm_id;
    imm_gen IMMGEN (
        .instr(if_id_instr),
        .imm_out(imm_id)
    );

    // =========================================================
    // HAZARD UNIT
    // =========================================================
    wire stall_pipeline;
    reg flush_id_ex;
    reg branch_taken_ex_r;

    hazard_unit HZU (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),
        .stall(stall_pipeline)
    );

    assign pc_enable    = ~stall_pipeline;
    assign if_id_enable = ~stall_pipeline;

    // =========================================================
    // ID/EX PIPELINE REG
    // =========================================================
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_pc4;
    reg [31:0] id_ex_rdata1;
    reg [31:0] id_ex_rdata2;
    reg [31:0] id_ex_imm;

    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;
    reg [4:0] id_ex_rd;

    reg [2:0] id_ex_funct3;
    reg [6:0] id_ex_funct7;
    reg [6:0] id_ex_opcode;
    reg [4:0] id_ex_funct5;

    reg id_ex_reg_write;
    reg id_ex_mem_read;
    reg id_ex_mem_write;
    reg id_ex_alu_src;
    reg [1:0] id_ex_wb_sel;
    reg id_ex_branch;
    reg id_ex_jump;
    reg id_ex_jalr;
    reg id_ex_use_pc;
    reg [1:0] id_ex_alu_op;

    // =========================================================
    // EX STAGE
    // =========================================================
    wire [4:0] alu_ctrl_ex;

    alu_control ALUCTRL (
        .alu_op(id_ex_alu_op),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .opcode(id_ex_opcode),
        .funct5(id_ex_funct5),
        .alu_ctrl(alu_ctrl_ex)
    );

    wire [1:0] forward_a, forward_b;
    forwarding_unit FWU (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    reg [31:0] ex_src_a_raw, ex_src_b_raw;
    reg [31:0] ex_src_a_final, ex_src_b_final;
    wire [31:0] alu_result_ex;
    wire alu_zero_ex;

    always @(*) begin
        case (forward_a)
            2'b00: ex_src_a_raw = id_ex_rdata1;
            2'b01: ex_src_a_raw = wb_write_data;
            2'b10: ex_src_a_raw = ex_mem_alu_result;
            default: ex_src_a_raw = id_ex_rdata1;
        endcase

        case (forward_b)
            2'b00: ex_src_b_raw = id_ex_rdata2;
            2'b01: ex_src_b_raw = wb_write_data;
            2'b10: ex_src_b_raw = ex_mem_alu_result;
            default: ex_src_b_raw = id_ex_rdata2;
        endcase
    end

    always @(*) begin
        ex_src_a_final = (id_ex_use_pc) ? id_ex_pc : ex_src_a_raw;
        ex_src_b_final = (id_ex_alu_src) ? id_ex_imm : ex_src_b_raw;
    end

    alu ALU (
        .a(ex_src_a_final),
        .b(ex_src_b_final),
        .alu_ctrl(alu_ctrl_ex),
        .result(alu_result_ex),
        .zero(alu_zero_ex)
    );

    reg branch_taken_ex;
    reg [31:0] branch_target_ex;

    always @(*) begin
        branch_taken_ex = 1'b0;
        branch_target_ex = id_ex_pc + id_ex_imm;

        if (id_ex_branch) begin
            case (id_ex_funct3)
                3'b000: branch_taken_ex = (ex_src_a_raw == ex_src_b_raw);                       // BEQ
                3'b001: branch_taken_ex = (ex_src_a_raw != ex_src_b_raw);                       // BNE
                3'b100: branch_taken_ex = ($signed(ex_src_a_raw) <  $signed(ex_src_b_raw));     // BLT
                3'b101: branch_taken_ex = ($signed(ex_src_a_raw) >= $signed(ex_src_b_raw));     // BGE
                3'b110: branch_taken_ex = (ex_src_a_raw < ex_src_b_raw);                         // BLTU
                3'b111: branch_taken_ex = (ex_src_a_raw >= ex_src_b_raw);                        // BGEU
                default: branch_taken_ex = 1'b0;
            endcase
        end

        if (id_ex_jump) begin
            branch_taken_ex = 1'b1;
            branch_target_ex = id_ex_pc + id_ex_imm; // JAL
        end

        if (id_ex_jalr) begin
            branch_taken_ex = 1'b1;
            branch_target_ex = (ex_src_a_raw + id_ex_imm) & 32'hFFFFFFFE; // JALR
        end
    end

    // =========================================================
    // EX/MEM PIPELINE REG
    // =========================================================
    reg [31:0] ex_mem_pc4;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_store_data;
    reg [4:0]  ex_mem_rd;
    reg [2:0]  ex_mem_funct3;

    reg ex_mem_reg_write;
    reg ex_mem_mem_read;
    reg ex_mem_mem_write;
    reg [1:0] ex_mem_wb_sel;

    // =========================================================
    // MEM STAGE
    // =========================================================
    wire [31:0] mem_read_data;

    wire ex_mem_mem_write_internal;
    assign ex_mem_mem_write_internal = ex_mem_mem_write;
    
    data_mem dmem (
        .clk(clk),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write_internal),
        .addr(ex_mem_alu_result),
        .write_data(ex_mem_store_data),
        .read_data(mem_read_data)
    );

    // =========================================================
    // MEM/WB PIPELINE REG
    // =========================================================
    reg [31:0] mem_wb_pc4;
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_data;
    reg [1:0]  mem_wb_wb_sel;
    reg [2:0] mem_wb_funct3;

    // =========================================================
    // WB STAGE
    // =========================================================
    // Byte/halfword selection for load instructions
    // mem_wb_alu_result[1:0] gives the byte offset within the word
    wire [31:0] mem_load_data;
    wire [1:0]  load_byte_offset = mem_wb_alu_result[1:0];

    assign mem_load_data =
        (mem_wb_funct3 == 3'b000) ?                          // LB  (sign extend)
            {{24{mem_wb_mem_data[load_byte_offset*8 +: 1]}},
              mem_wb_mem_data[load_byte_offset*8 +: 8]}   :
        (mem_wb_funct3 == 3'b100) ?                          // LBU (zero extend)
            {24'b0, mem_wb_mem_data[load_byte_offset*8 +: 8]} :
        (mem_wb_funct3 == 3'b001) ?                          // LH  (sign extend)
            {{16{mem_wb_mem_data[load_byte_offset[1]*16 +: 1]}},
              mem_wb_mem_data[load_byte_offset[1]*16 +: 16]} :
        (mem_wb_funct3 == 3'b101) ?                          // LHU (zero extend)
            {16'b0, mem_wb_mem_data[load_byte_offset[1]*16 +: 16]} :
        mem_wb_mem_data;                                     // LW  (full word)

    assign wb_write_data =
        (mem_wb_wb_sel == 2'b00) ? mem_wb_alu_result :
        (mem_wb_wb_sel == 2'b01) ? mem_load_data     :   // ← use byte-selected version
        (mem_wb_wb_sel == 2'b10) ? mem_wb_pc4        :
                                   32'd0;

    // =========================================================
    // NEXT PC LOGIC
    // =========================================================
    always @(*) begin
        if (branch_taken_ex)
            pc_next = branch_target_ex;
        else
            pc_next = pc_plus4_if;
    end

    // =========================================================
    // PIPELINE REGISTER UPDATES
    // =========================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // IF/ID
            if_id_pc    <= 32'd0;
            if_id_pc4   <= 32'd0;
            if_id_instr <= 32'h00000013;

            // ID/EX
            id_ex_pc        <= 32'd0;
            id_ex_pc4       <= 32'd0;
            id_ex_rdata1    <= 32'd0;
            id_ex_rdata2    <= 32'd0;
            id_ex_imm       <= 32'd0;
            id_ex_rs1       <= 5'd0;
            id_ex_rs2       <= 5'd0;
            id_ex_rd        <= 5'd0;
            id_ex_funct3    <= 3'd0;
            id_ex_funct7    <= 7'd0;
            id_ex_opcode    <= 7'd0;
            id_ex_funct5    <= 5'd0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_read  <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_alu_src   <= 1'b0;
            id_ex_wb_sel    <= 2'b00;
            id_ex_branch    <= 1'b0;
            id_ex_jump      <= 1'b0;
            id_ex_jalr      <= 1'b0;
            id_ex_use_pc    <= 1'b0;
            id_ex_alu_op    <= 2'b00;

            // EX/MEM
            ex_mem_pc4       <= 32'd0;
            ex_mem_alu_result<= 32'd0;
            ex_mem_store_data<= 32'd0;
            ex_mem_rd        <= 5'd0;
            ex_mem_funct3    <= 3'd0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_read  <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_wb_sel    <= 2'b00;

            // MEM/WB
            mem_wb_pc4       <= 32'd0;
            mem_wb_alu_result<= 32'd0;
            mem_wb_mem_data  <= 32'd0;
            mem_wb_rd        <= 5'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_wb_sel    <= 2'b00;
            mem_wb_funct3    <= 3'd0;   // ← ADD THIS LINE
            
            inst_count        <= 32'd0;
            branch_taken_ex_r <= 1'b0;
        end else begin
            // Registered branch: covers synchronous IMEM 1-cycle lag
            branch_taken_ex_r <= branch_taken_ex;

            // -----------------------------
            // IF/ID
            // -----------------------------
            if (branch_taken_ex || branch_taken_ex_r) begin
                if_id_pc    <= 32'd0;
                if_id_pc4   <= 32'd0;
                if_id_instr <= 32'h00000013; // flush as NOP (covers 2-cycle IMEM lag)
            end else if (if_id_enable) begin
                if_id_pc    <= pc_current;
                if_id_pc4   <= pc_plus4_if;
                if_id_instr <= instr_if;
            end

            // -----------------------------
            // ID/EX
            // Bubble on stall or flush
            // -----------------------------
            if (stall_pipeline || branch_taken_ex) begin
                id_ex_pc        <= 32'd0;
                id_ex_pc4       <= 32'd0;
                id_ex_rdata1    <= 32'd0;
                id_ex_rdata2    <= 32'd0;
                id_ex_imm       <= 32'd0;
                id_ex_rs1       <= 5'd0;
                id_ex_rs2       <= 5'd0;
                id_ex_rd        <= 5'd0;
                id_ex_funct3    <= 3'd0;
                id_ex_funct7    <= 7'd0;
                id_ex_opcode    <= 7'd0;
                id_ex_funct5    <= 5'd0;
                id_ex_reg_write <= 1'b0;
                id_ex_mem_read  <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_alu_src   <= 1'b0;
                id_ex_wb_sel    <= 2'b00;
                id_ex_branch    <= 1'b0;
                id_ex_jump      <= 1'b0;
                id_ex_jalr      <= 1'b0;
                id_ex_use_pc    <= 1'b0;
                id_ex_alu_op    <= 2'b00;
            end else begin
                id_ex_pc        <= if_id_pc;
                id_ex_pc4       <= if_id_pc4;
                id_ex_rdata1    <= reg_rdata1;
                id_ex_rdata2    <= reg_rdata2;
                id_ex_imm       <= imm_id;
                id_ex_rs1       <= if_id_rs1;
                id_ex_rs2       <= if_id_rs2;
                id_ex_rd        <= if_id_rd;
                id_ex_funct3    <= if_id_funct3;
                id_ex_funct7    <= if_id_funct7;
                id_ex_opcode    <= if_id_opcode;
                id_ex_funct5    <= if_id_funct5;
                id_ex_reg_write <= ctrl_reg_write;
                id_ex_mem_read  <= ctrl_mem_read;
                id_ex_mem_write <= ctrl_mem_write;
                id_ex_alu_src   <= ctrl_alu_src;
                id_ex_wb_sel    <= ctrl_wb_sel;
                id_ex_branch    <= ctrl_branch;
                id_ex_jump      <= ctrl_jump;
                id_ex_jalr      <= ctrl_jalr;
                id_ex_use_pc    <= ctrl_use_pc;
                id_ex_alu_op    <= ctrl_alu_op;
            end

            // -----------------------------
            // EX/MEM
            // -----------------------------
            ex_mem_pc4        <= id_ex_pc4;
            ex_mem_alu_result <= alu_result_ex;
            ex_mem_store_data <= ex_src_b_raw; // forwarded store data
            ex_mem_rd         <= id_ex_rd;
            ex_mem_funct3     <= id_ex_funct3;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_wb_sel     <= id_ex_wb_sel;

            // -----------------------------
            // MEM/WB
            // -----------------------------
            mem_wb_pc4        <= ex_mem_pc4;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_data   <= mem_read_data;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_wb_sel     <= ex_mem_wb_sel;
            mem_wb_funct3     <= ex_mem_funct3;   // ← ADD THIS LINE
            
            if (mem_wb_reg_write)
                inst_count <= inst_count + 1;
        end
    end
    
    assign pc_out    = pc_current;
    assign instr_out = instr_if;
    assign alu_out   = alu_result_ex;
    assign wb_out    = wb_write_data;
    
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        debug_x5  <= 32'd0;
        debug_x6  <= 32'd0;
        debug_x7  <= 32'd0;
        debug_x8  <= 32'd0;
        debug_x9  <= 32'd0;
        debug_x10 <= 32'd0;
        debug_x11 <= 32'd0;
        debug_x12 <= 32'd0;
        debug_x13 <= 32'd0;
        debug_x14 <= 32'd0;
        debug_x15 <= 32'd0;
        debug_x16 <= 32'd0;
    end else begin
        debug_x5  <= RF.regs[5];
        debug_x6  <= RF.regs[6];
        debug_x7  <= RF.regs[7];
        debug_x8  <= RF.regs[8];
        debug_x9  <= RF.regs[9];
        debug_x10 <= RF.regs[10];
        debug_x11 <= RF.regs[11];
        debug_x12 <= RF.regs[12];
        debug_x13 <= RF.regs[13];
        debug_x14 <= RF.regs[14];
        debug_x15 <= RF.regs[15];
        debug_x16 <= RF.regs[16];
    end
end

endmodule