module reg_file_pipe_bypass (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else begin
            if (reg_write && (rd != 5'd0))
                regs[rd] <= write_data;
        end
    end

    // x0 is always zero
    // simple bypass for same-cycle read/write on same register
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 :
                        (reg_write && (rd != 5'd0) && (rd == rs1)) ? write_data :
                        regs[rs1];

    assign read_data2 = (rs2 == 5'd0) ? 32'd0 :
                        (reg_write && (rd != 5'd0) && (rd == rs2)) ? write_data :
                        regs[rs2];

endmodule