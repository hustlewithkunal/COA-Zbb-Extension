`timescale 1ns / 1ps

// =============================================================
// Instruction Memory - BASELINE (no Zbb)
// BRAM-friendly synchronous ROM for Vivado
//
// Program: CRC-32 over 8 bytes stored at mem[50..51]
//
// Register map:
//   x5  = CRC accumulator (init 0xFFFFFFFF)
//   x6  = outer byte counter (8 -> 0)
//   x7  = byte pointer (starts at byte addr 200 = 0xC8 = mem[50])
//   x11 = CRC-32 polynomial 0xEDB88320
//   x12 = current byte loaded from memory
//   x13 = inner bit counter (8 -> 0)
//   x14 = LSB of CRC (used for branch decision)
//   x10 = RESULT (final CRC-32, written at end)
//
// Memory layout:
//   mem[0..18]  = program (19 instructions)
//   mem[50]     = 0xD8C7B6A5  (test bytes: 0xA5, 0xB6, 0xC7, 0xD8)
//   mem[51]     = 0x1C0BFAE9  (test bytes: 0xE9, 0xFA, 0x0B, 0x1C)
//
// Branch offset table (all verified):
//   beq  (instr 10): offset +8  -> lands on instr 12 (no_xor)
//   bne  (instr 13): offset -20 -> lands on instr  8 (crc_bit_loop)
//   bne  (instr 16): offset -44 -> lands on instr  5 (crc_byte_loop)
//
// Instruction count (dynamic, worst case all bits set):
//   Setup:        5 instrs  x 1  =  5
//   Outer loop:   3 instrs  x 8  = 24  (byte load + xor + bit-ctr init)
//   Inner loop: 3-4 instrs  x 64 = ~224 (andi/srli/beq/[xor]/addi/bne)
//   Teardown:     2 instrs  x 1  =  2
//   Total: ~255 dynamic instructions (baseline)
// =============================================================

module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    (* rom_style = "block" *) reg [31:0] mem [0:255];

    integer i;
    initial begin
        // Default everything to NOP: addi x0, x0, 0
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;

        // -------------------------------------------------------
        // SETUP (indices 0-4)
        // -------------------------------------------------------
        mem[ 0] = 32'hFFF00293; // addi x5,  x0, -1       | x5  = 0xFFFFFFFF (init CRC)
        mem[ 1] = 32'h00800313; // addi x6,  x0, 8        | x6  = 8 (byte counter)
        mem[ 2] = 32'h0C800393; // addi x7,  x0, 200      | x7  = 0xC8 (ptr to mem[50])
        mem[ 3] = 32'hEDB885B7; // lui  x11, 0xEDB88      | x11 = 0xEDB88000
        mem[ 4] = 32'h32058593; // addi x11, x11, 0x320   | x11 = 0xEDB88320 (polynomial)

        // -------------------------------------------------------
        // crc_byte_loop: (index 5)
        // Outer loop - processes one byte per iteration
        // -------------------------------------------------------
        mem[ 5] = 32'h0003C603; // lbu  x12, 0(x7)        | x12 = byte from memory
        mem[ 6] = 32'h00C2C2B3; // xor  x5,  x5,  x12    | x5  = CRC ^ byte
        mem[ 7] = 32'h00800693; // addi x13, x0, 8        | x13 = 8 (bit counter)

        // -------------------------------------------------------
        // crc_bit_loop: (index 8)
        // Inner loop - processes one bit per iteration (8 iters per byte)
        // -------------------------------------------------------
        mem[ 8] = 32'h0012F713; // andi x14, x5,  1       | x14 = CRC & 1 (LSB)
        mem[ 9] = 32'h0012D293; // srli x5,  x5,  1       | x5  = CRC >> 1
        mem[10] = 32'h00070463; // beq  x14, x0, +8       | if LSB==0: jump to no_xor (instr 12)
        mem[11] = 32'h00B2C2B3; // xor  x5,  x5,  x11    | x5  = CRC ^ poly (only if LSB was 1)

        // no_xor: (index 12)
        mem[12] = 32'hFFF68693; // addi x13, x13, -1      | x13-- (bit counter)
        mem[13] = 32'hFE0696E3; // bne  x13, x0,  -20     | if x13!=0: jump to crc_bit_loop (instr 8)

        // -------------------------------------------------------
        // After inner loop - advance pointer, decrement outer counter
        // -------------------------------------------------------
        mem[14] = 32'h00138393; // addi x7,  x7,  1       | x7++ (next byte)
        mem[15] = 32'hFFF30313; // addi x6,  x6,  -1      | x6-- (byte counter)
        mem[16] = 32'hFC031AE3; // bne  x6,  x0,  -44     | if x6!=0: jump to crc_byte_loop (instr 5)

        // -------------------------------------------------------
        // RESULT
        // -------------------------------------------------------
        mem[17] = 32'hFFF2C513; // xori x10, x5,  -1      | x10 = ~CRC = final CRC-32 result
        mem[18] = 32'h0000006F; // jal  x0,  0             | halt (infinite loop)

        // -------------------------------------------------------
        // DATA SECTION at byte address 0xC8 = mem[50]
        // 8 test bytes stored little-endian in two words:
        //   Byte 0: 0xA5  Byte 1: 0xB6  Byte 2: 0xC7  Byte 3: 0xD8
        //   Byte 4: 0xE9  Byte 5: 0xFA  Byte 6: 0x0B  Byte 7: 0x1C
        // -------------------------------------------------------
        mem[50] = 32'hD8C7B6A5; // bytes [0..3]: 0xA5, 0xB6, 0xC7, 0xD8
        mem[51] = 32'h1C0BFAE9; // bytes [4..7]: 0xE9, 0xFA, 0x0B, 0x1C

    end

    // Synchronous read - BRAM-friendly, matches pipeline register timing
    always @(posedge clk) begin
        instr <= mem[addr[31:2]];
    end

endmodule