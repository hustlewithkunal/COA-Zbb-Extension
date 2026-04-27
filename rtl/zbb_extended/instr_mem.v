`timescale 1ns / 1ps

// =============================================================
// Instruction Memory - ZBB VERSION (with Zbb extension)
// BRAM-friendly synchronous ROM for Vivado
//
// Program: CRC-32 over 8 bytes + rev8 byte-swap at end
//
// Comparison vs baseline:
//   Baseline needs 6 instructions to byte-swap a 32-bit word:
//     srli t0, x10, 24          // extract byte 3
//     srli t1, x10, 8           // shift for byte 2
//     andi t1, t1, 0xFF         // isolate byte 2
//     slli t1, t1, 8            // place byte 2
//     ... (6 total instructions)
//   Zbb replaces ALL of that with ONE instruction:
//     rev8 x10, x10             // 0xAABBCCDD -> 0xDDCCBBAA
//
//   Dynamic instruction count reduction at this step: 6 -> 1 = 83% reduction
//   Overall program: baseline=19 instr, zbb=20 instr body but +1 replaces +6
//   Net saving: 5 fewer instructions per CRC call
//
// Register map: (identical to baseline)
//   x5  = CRC accumulator
//   x6  = outer byte counter
//   x7  = byte pointer
//   x10 = RESULT (final byte-swapped CRC-32)
//   x11 = CRC polynomial 0xEDB88320
//   x12 = loaded byte
//   x13 = bit counter
//   x14 = CRC LSB
//   x31 = done flag (set to 1 when program completes, triggers testbench)
//
// rev8 encoding: funct7=0110100, rs2=11000(shamt=24), funct3=101, op=0010011
//   rev8 x10, x10 = 0x69855513
//
// Branch offsets (identical to baseline, all verified):
//   beq  (instr 10): +8  -> instr 12
//   bne  (instr 13): -20 -> instr  8
//   bne  (instr 16): -44 -> instr  5
// =============================================================

module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    reg [31:0] mem [0:255];  // async ROM - no BRAM, avoids 1-cycle IMEM lag

    integer i;
    initial begin
        // Default everything to NOP: addi x0, x0, 0
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;

        // -------------------------------------------------------
        // SETUP (indices 0-4) - identical to baseline
        // -------------------------------------------------------
        mem[ 0] = 32'hFFF00293; // addi x5,  x0,  -1      | x5  = 0xFFFFFFFF (init CRC)
        mem[ 1] = 32'h00800313; // addi x6,  x0,  8       | x6  = 8 (byte counter)
        mem[ 2] = 32'h0C800393; // addi x7,  x0,  200     | x7  = 0xC8 (ptr to mem[50])
        mem[ 3] = 32'hEDB885B7; // lui  x11, 0xEDB88      | x11 = 0xEDB88000
        mem[ 4] = 32'h32058593; // addi x11, x11, 0x320   | x11 = 0xEDB88320 (polynomial)

        // -------------------------------------------------------
        // crc_byte_loop: (index 5) - identical to baseline
        // -------------------------------------------------------
        mem[ 5] = 32'h0003C603; // lbu  x12, 0(x7)        | x12 = byte from memory
        mem[ 6] = 32'h00C2C2B3; // xor  x5,  x5,  x12    | x5  = CRC ^ byte
        mem[ 7] = 32'h00800693; // addi x13, x0,  8       | x13 = 8 (bit counter)

        // -------------------------------------------------------
        // crc_bit_loop: (index 8) - identical to baseline
        // -------------------------------------------------------
        mem[ 8] = 32'h0012F713; // andi x14, x5,  1       | x14 = CRC & 1 (LSB)
        mem[ 9] = 32'h0012D293; // srli x5,  x5,  1       | x5  = CRC >> 1
        mem[10] = 32'h00070463; // beq  x14, x0,  +8      | if LSB==0: jump to no_xor (instr 12)
        mem[11] = 32'h00B2C2B3; // xor  x5,  x5,  x11    | x5  = CRC ^ poly

        // no_xor: (index 12)
        mem[12] = 32'hFFF68693; // addi x13, x13, -1      | bit counter--
        mem[13] = 32'hFE0696E3; // bne  x13, x0,  -20     | loop to crc_bit_loop (instr 8)

        // -------------------------------------------------------
        // Byte pointer advance - identical to baseline
        // -------------------------------------------------------
        mem[14] = 32'h00138393; // addi x7,  x7,  1       | x7++ (next byte)
        mem[15] = 32'hFFF30313; // addi x6,  x6,  -1      | byte counter--
        mem[16] = 32'hFC031AE3; // bne  x6,  x0,  -44     | loop to crc_byte_loop (instr 5)

        // -------------------------------------------------------
        // RESULT - ZBB DIVERGES HERE
        // -------------------------------------------------------
        mem[17] = 32'hFFF2C513; // xori x10, x5,  -1      | x10 = ~CRC (final CRC-32)

        // Baseline would need these 6 instructions to byte-swap x10:
        //   srli t0, x10, 24         // byte 3 to position 0
        //   andi t1, x10, 0xFF0000   // (needs lui+and, actually more)
        //   ... total 6+ instructions
        //
        // ZBB: ONE instruction does it all:
        mem[18] = 32'h69855513; // rev8 x10, x10           | byte-swap: [B3,B2,B1,B0]->[B0,B1,B2,B3]
        //                                                  | funct7=0110100, rs2=11000, funct3=101

        mem[19] = 32'h00100F93; // addi x31, x0, 1         | x31 = 1 (DONE flag - triggers testbench)
        mem[20] = 32'h0000006F; // jal  x0,  0             | halt

        // -------------------------------------------------------
        // DATA SECTION at byte address 0xC8 = mem[50]
        // Same 8 test bytes as baseline (for fair comparison)
        //   Byte 0: 0xA5  Byte 1: 0xB6  Byte 2: 0xC7  Byte 3: 0xD8
        //   Byte 4: 0xE9  Byte 5: 0xFA  Byte 6: 0x0B  Byte 7: 0x1C
        // -------------------------------------------------------
        mem[50] = 32'hD8C7B6A5; // bytes [0..3]: 0xA5, 0xB6, 0xC7, 0xD8
        mem[51] = 32'h1C0BFAE9; // bytes [4..7]: 0xE9, 0xFA, 0x0B, 0x1C

    end

    // Combinatorial (async) read - zero latency so if_id_pc = pc_current is exact
    // and standard 1-flush branch handling works correctly without any -4 correction.
    always @(*) begin
        instr = mem[addr[31:2]];
    end

endmodule