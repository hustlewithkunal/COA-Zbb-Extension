module riscv_fpga_top (
    input  wire clk,
    input  wire rst,
    output wire [3:0] led
);

    wire [31:0] pc_out;
    wire [31:0] wb_out;
    wire [31:0] debug_x5;

    riscv_pipelined_top cpu (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(),
        .alu_out(),
        .wb_out(wb_out),
        .debug_x5(debug_x5)
    );

    assign led = debug_x5[3:0];

endmodule