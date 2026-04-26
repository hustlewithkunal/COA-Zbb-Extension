module riscv_fpga_top (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] sw,
    output reg  [3:0] led
);
    wire [31:0] pc_out;
    wire [31:0] wb_out;
    wire [31:0] debug_x5;   // same as baseline - only x5 exposed

    riscv_pipelined_top cpu (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(),
        .alu_out(),
        .wb_out(wb_out),
        .debug_x5(debug_x5),
        // tie off all other debug outputs
        .debug_x6(),
        .debug_x7(),
        .debug_x8(),
        .debug_x9(),
        .debug_x10(),
        .debug_x11(),
        .debug_x12(),
        .debug_x13(),
        .debug_x14(),
        .debug_x15(),
        .debug_x16(),
        .inst_count()
    );

    always @(*) begin
        case (sw)
            4'b0000: led = pc_out[3:0];
            4'b0001: led = debug_x5[3:0];
            default: led = 4'b0000;
        endcase
    end

endmodule