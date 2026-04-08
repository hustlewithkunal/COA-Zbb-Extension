`timescale 1ns / 1ps

module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [4:0]  alu_ctrl,
    output reg [31:0] result,
    output zero
);

    integer j;
    integer count;
    reg found;

    always @(*) begin
        result = 32'd0;
        count  = 0;
        found  = 1'b0;

        case (alu_ctrl)
            5'b00000: result = a + b;
            5'b00001: result = a - b;
            5'b00010: result = a & b;
            5'b00011: result = a | b;
            5'b00100: result = a ^ b;
            5'b00101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            5'b00110: result = (a < b) ? 32'd1 : 32'd0;
            5'b00111: result = a << b[4:0];
            5'b01000: result = a >> b[4:0];
            5'b01001: result = $signed(a) >>> b[4:0];
            5'b01010: result = b;

            5'b01011: result = a & ~b;                                // ANDN
            5'b01100: result = a | ~b;                                // ORN
            5'b01101: result = ~(a ^ b);                              // XNOR
            5'b01110: result = {{24{a[7]}}, a[7:0]};                  // SEXT.B
            5'b01111: result = {a[7:0], a[15:8], a[23:16], a[31:24]}; // REV8

            5'b10000: begin // CLZ
                result = 32;
                found  = 1'b0;
                for (j = 31; j >= 0; j = j - 1) begin
                    if (!found && a[j]) begin
                        result = 31 - j;
                        found  = 1'b1;
                    end
                end
            end

            5'b10001: begin // CTZ
                result = 32;
                found  = 1'b0;
                for (j = 0; j < 32; j = j + 1) begin
                    if (!found && a[j]) begin
                        result = j;
                        found  = 1'b1;
                    end
                end
            end

            5'b10010: begin // CPOP
                count = 0;
                for (j = 0; j < 32; j = j + 1)
                    count = count + a[j];
                result = count[31:0];
            end

            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule