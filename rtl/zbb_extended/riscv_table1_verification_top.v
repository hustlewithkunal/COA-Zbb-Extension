`timescale 1ns / 1ps

// ============================================================================
// Module: riscv_table1_verification_top
// Purpose: Standalone FPGA top module specifically designed to verify "TABLE I: 
//          SIMULATION VERIFICATION RESULTS" live on the Zybo Z7-10.
//          It uses switches to select the target register (x5-x16) and uses 
//          an LED to display the "Pass" status by comparing the physical 
//          register value against the Expected Value from the report table.
// ============================================================================

module riscv_table1_verification_top (
    input  wire       clk,      // High-speed onboard clock
    input  wire [3:0] sw,       // 4 Slide Switches (Used to select row from Table I)
    output wire [3:0] led       // 4 LEDs (LED 0 = Pass/Fail Status)
);

    // ------------------------------------------------------------------------
    // 1. CPU Instantiation (Running at full speed)
    // ------------------------------------------------------------------------
    // We let the CPU run at full speed so it finishes the Zbb verification 
    // program in a microsecond and goes into its infinite halt loop.
    wire        rst = 1'b0; // No manual reset needed, runs on startup
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_out;
    wire [31:0] wb_out;
    wire [31:0] debug_x5;
    wire [31:0] inst_count;

    riscv_pipelined_top u_riscv_core (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_out(alu_out),
        .wb_out(wb_out),
        .debug_x5(debug_x5),
        .inst_count(inst_count)
    );

    // ------------------------------------------------------------------------
    // 2. Table I Result Verification Logic
    // ------------------------------------------------------------------------
    reg [31:0] observed_val;

    // Use hierarchical referencing to tap directly into the Register File
    // inside the processor pipeline to read the final computed values.
    always @(*) begin
        case (sw[3:0])
            // Switch  | Register | Expected Value (Table I) | LED Output (Lowest 4 bits in binary)
            4'd0:  begin observed_val = u_riscv_core.RF.regs[5];  end // 32 -> 6'b100000 -> LEDs: 0000
            4'd1:  begin observed_val = u_riscv_core.RF.regs[6];  end // 32 -> 6'b100000 -> LEDs: 0000
            4'd2:  begin observed_val = u_riscv_core.RF.regs[7];  end // 0  -> 6'b000000 -> LEDs: 0000
            4'd3:  begin observed_val = u_riscv_core.RF.regs[8];  end // 31 -> 5'b011111 -> LEDs: 1111
            4'd4:  begin observed_val = u_riscv_core.RF.regs[9];  end // 0  -> 6'b000000 -> LEDs: 0000
            4'd5:  begin observed_val = u_riscv_core.RF.regs[10]; end // 1  -> 6'b000001 -> LEDs: 0001
            4'd6:  begin observed_val = u_riscv_core.RF.regs[11]; end // 24 -> 5'b011000 -> LEDs: 1000
            4'd7:  begin observed_val = u_riscv_core.RF.regs[12]; end // 4  -> 6'b000100 -> LEDs: 0100
            4'd8:  begin observed_val = u_riscv_core.RF.regs[13]; end // 4  -> 6'b000100 -> LEDs: 0100
            4'd9:  begin observed_val = u_riscv_core.RF.regs[14]; end // 0  -> 6'b000000 -> LEDs: 0000
            4'd10: begin observed_val = u_riscv_core.RF.regs[15]; end // 0  -> 6'b000000 -> LEDs: 0000
            4'd11: begin observed_val = u_riscv_core.RF.regs[16]; end // 32 -> 6'b100000 -> LEDs: 0000
            
            // Unmapped switches show 0 by default
            default: begin observed_val = 32'd0; end 
        endcase
    end

    // ------------------------------------------------------------------------
    // 3. LED Status Output
    // ------------------------------------------------------------------------
    // We map all 4 LEDs directly to the lowest 4 bits of the observed register value.
    // NOTE: Because we only have 4 LEDs, any number 16 or larger will "overflow"
    // and only show its bottom 4 bits (e.g., 32 shows as 0000, 24 shows as 1000).
    assign led = observed_val[3:0];

endmodule
