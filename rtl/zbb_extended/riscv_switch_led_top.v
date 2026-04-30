`timescale 1ns / 1ps

// ============================================================================
// Module: riscv_switch_led_top
// Purpose: Standalone top-level wrapper for manual FPGA validation using 
//          the Zybo Z7-10's onboard switches and LEDs.
// ============================================================================

module riscv_switch_led_top (
    input  wire       sysclk,   // High-speed onboard clock (typically 125MHz on Zybo Z7)
    input  wire [3:0] sw,       // 4 Slide Switches
    output wire [3:0] led       // 4 LEDs
);

    // ------------------------------------------------------------------------
    // 1. Clock Divider for Human-Readable Execution Speed
    // ------------------------------------------------------------------------
    // A 125MHz clock is too fast to see LEDs blink. 
    // We divide the clock by 2^26 to get approx ~1.8 Hz clock for the CPU.
    reg [26:0] clk_div;
    always @(posedge sysclk) begin
        if (sw[0]) begin // If reset is active, hold divider at 0
            clk_div <= 0;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
    
    // CPU clock is derived from the divider.
    // sw[1] acts as a "Pause" switch. If sw[1] is UP, the CPU clock stops.
    wire cpu_clk = sw[1] ? 1'b0 : clk_div[26]; 
    
    // ------------------------------------------------------------------------
    // 2. CPU Instantiation
    // ------------------------------------------------------------------------
    wire        rst = sw[0]; // sw[0] acts as the global asynchronous reset
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_out;
    wire [31:0] wb_out;
    wire [31:0] debug_x5;
    wire [31:0] inst_count;

    riscv_pipelined_top u_riscv_core (
        .clk(cpu_clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_out(alu_out),
        .wb_out(wb_out),
        .debug_x5(debug_x5),
        .inst_count(inst_count)
    );

    // ------------------------------------------------------------------------
    // 3. LED Output Multiplexer (Controlled by sw[3:2])
    // ------------------------------------------------------------------------
    // This allows you to inspect different parts of the CPU pipeline live on 
    // the 4 LEDs by flipping the top two switches.
    reg [3:0] led_mux;
    
    always @(*) begin
        case (sw[3:2])
            2'b00: led_mux = alu_out[3:0];       // Show ALU result
            2'b01: led_mux = wb_out[3:0];        // Show Write-back data
            2'b10: led_mux = debug_x5[3:0];      // Show specific test register (x5)
            2'b11: led_mux = pc_out[5:2];        // Show Program Counter (word aligned)
        endcase
    end

    assign led = led_mux;

endmodule
