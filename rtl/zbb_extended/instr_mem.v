`timescale 1ns / 1ps

// =============================================================
// Instruction Memory - ZBB EXTENDED (with Zbb extension)
//
// Contains TWO programs — uncomment ONE at a time:
//   `define PROGRAM_CRC        ← CRC-32 kernel  (inst_count: 370)
//   `define PROGRAM_POPCOUNT   ← Popcount kernel (inst_count: 4)
//
// To switch programs:
//   1. Comment out the current `define
//   2. Uncomment the other `define
//   3. Relaunch simulation (Run All)
// =============================================================

// ===== SELECT PROGRAM (uncomment ONE) =====
`define PROGRAM_CRC
//`define PROGRAM_POPCOUNT
// ==========================================

module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;  // default NOP

`ifdef PROGRAM_CRC
        // ==========================================================
        // PROGRAM 1: CRC-32 over 8 bytes (ZBB EXTENDED)
        //
        // Register map: (identical to baseline)
        //   x5  = CRC accumulator (init 0xFFFFFFFF)
        //   x6  = outer byte counter (8 → 0)
        //   x7  = byte pointer (byte addr 200 = mem[50])
        //   x10 = final CRC-32 result (byte-swapped via rev8)
        //   x11 = polynomial 0xEDB88320
        //   x12 = loaded byte
        //   x13 = inner bit counter (8 → 0)
        //   x14 = LSB / popcount result (via cpop)
        //   x31 = done flag
        //
        // ZBB advantages over baseline:
        //   • rev8: 1 instruction replaces 11-instruction byte-swap
        //   • cpop: 1 instruction replaces ~49-instruction Kernighan loop
        //   Total saving: ~85 instructions (455 → 370)
        // ==========================================================

        // --- SETUP (0-4) — identical to baseline ---
        mem[ 0] = 32'hFFF00293; // addi x5,  x0, -1       | x5  = 0xFFFFFFFF
        mem[ 1] = 32'h00800313; // addi x6,  x0, 8        | x6  = 8
        mem[ 2] = 32'h0C800393; // addi x7,  x0, 200      | x7  = 0xC8
        mem[ 3] = 32'hEDB885B7; // lui  x11, 0xEDB88      | x11 = 0xEDB88000
        mem[ 4] = 32'h32058593; // addi x11, x11, 0x320   | x11 = 0xEDB88320

        // --- crc_byte_loop (5-7) — identical to baseline ---
        mem[ 5] = 32'h0003C603; // lbu  x12, 0(x7)        | load byte
        mem[ 6] = 32'h00C2C2B3; // xor  x5,  x5,  x12    | CRC ^= byte
        mem[ 7] = 32'h00800693; // addi x13, x0, 8        | bit counter = 8

        // --- crc_bit_loop (8-13) — identical to baseline ---
        mem[ 8] = 32'h0012F713; // andi x14, x5,  1       | x14 = LSB
        mem[ 9] = 32'h0012D293; // srli x5,  x5,  1       | CRC >>= 1
        mem[10] = 32'h00070463; // beq  x14, x0, +8       | skip xor if LSB==0
        mem[11] = 32'h00B2C2B3; // xor  x5,  x5,  x11    | CRC ^= poly
        mem[12] = 32'hFFF68693; // addi x13, x13, -1      | bit counter--
        mem[13] = 32'hFE0696E3; // bne  x13, x0,  -20     | loop → instr 8

        // --- outer loop advance (14-16) — identical to baseline ---
        mem[14] = 32'h00138393; // addi x7,  x7,  1       | ptr++
        mem[15] = 32'hFFF30313; // addi x6,  x6,  -1      | byte counter--
        mem[16] = 32'hFC031AE3; // bne  x6,  x0,  -44     | loop → instr 5

        // --- RESULT: ZBB DIVERGES HERE ---
        mem[17] = 32'hFFF2C513; // xori x10, x5,  -1      | x10 = ~CRC
        mem[18] = 32'h69855513; // rev8 x10, x10           | byte-swap (1 vs 11 baseline)
        mem[19] = 32'h60251713; // cpop x14, x10           | popcount  (1 vs ~49 baseline)

        // --- Done + halt ---
        mem[20] = 32'h00100F93; // addi x31, x0, 1        | DONE
        mem[21] = 32'h0000006F; // jal  x0,  0             | halt

        // --- DATA at mem[50] (byte addr 200) ---
        mem[50] = 32'hD8C7B6A5; // bytes: 0xA5, 0xB6, 0xC7, 0xD8
        mem[51] = 32'h1C0BFAE9; // bytes: 0xE9, 0xFA, 0x0B, 0x1C

`elsif PROGRAM_POPCOUNT
        // ==========================================================
        // PROGRAM 2: POPCOUNT of 240 (ZBB — single cpop instruction)
        //
        // Input:  x1 = 240 = 0b11110000
        // Output: x2 = 4 (number of set bits)
        //
        // ZBB inst_count:       4
        // Baseline inst_count: 27
        // Improvement: 85% reduction
        // ==========================================================

        mem[ 0] = 32'h0F000093; // addi x1, x0, 240       | x1 = 240
        mem[ 1] = 32'h60209113; // cpop x2, x1             | x2 = popcount(x1) = 4
        mem[ 2] = 32'h00100F93; // addi x31, x0, 1        | DONE
        mem[ 3] = 32'h0000006F; // jal  x0, 0              | halt

`endif

    end

    // Combinatorial (async) read
    always @(*) begin
        instr = mem[addr[31:2]];
    end

endmodule