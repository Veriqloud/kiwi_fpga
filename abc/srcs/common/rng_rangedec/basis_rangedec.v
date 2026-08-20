`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: Qline_turnkey
// Module Name: basis_rangedec
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Bernoulli(p) biased-bit generator. A binary range decoder used as
//              a sampler over a uniform bit stream; emits one biased symbol per
//              clock once primed, consuming on average H(p) uniform bits/symbol.
//
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - No change
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


// ============================================================================
// basis_rangedec.v
//
// Bernoulli(p) bit generator from a uniform bit stream, via a binary range
// DECODER used as a sampler.  Emits one biased symbol per clock once primed,
// consuming on average H(p) ~= 0.469 uniform bits/symbol for p=0.1.
//
//   bound = (range >> PREC) * P0          // width of the "0" sub-interval
//   bit   = (code >= bound)               // 0 w.p. ~P0/2^PREC, else 1
//   renormalize so range stays in [2^31, 2^32), refilling code's LSBs
//
// Renorm is done in ONE cycle: a leading-zero count gives the exact shift,
// and up to 4 fresh bits (for p=0.1) are pulled from rnd_in in the same cycle.
//
// Input handshake: each cycle the module presents 'take' = the number of
// uniform bits it consumed; drive it from a small bit-FIFO and pop 'take'
// bits.  rnd_in[7] is the NEXT bit to consume (MSB-first); the module uses
// the top 'take' bits.  During the 4-cycle prime phase take = 8.
//
// Verified bit-exact against a C golden model (biasgen.c) via tb_basis_rangedec.
//
//   Realized p = P0/2^PREC + a small (~2e-5) finite-precision term from the
//   (range>>PREC) floor.  Measure it with the C model and record that value.
//   Make P0 a register-map field if you want p runtime-tunable.
// ============================================================================

`default_nettype none

module basis_rangedec #(
    parameter        PREC = 15              // probability precision (Q-format)
)(
    input  wire        clk,
    input  wire        rst,                 // synchronous, active high
    input  wire [15:0] p0_i,                // P(bit==0) in Q(PREC); runtime (AXIL) value,
                                            //   quasi-static -- see wrapper CDC note
    input  wire [7:0]  rnd_in,              // up to 8 uniform bits; [7] = next
    output wire [3:0]  take,                // uniform bits consumed this cycle (0..8)
    output wire        basis_bit,           // the biased output bit
    output wire        basis_valid          // high when basis_bit is a real symbol
);
    localparam [31:0] TOP        = 32'h8000_0000;
    localparam [31:0] RANGE_INIT = 32'hFFFF_FFFF;

    // ---- state ----
    reg [31:0] range;
    reg [31:0] code;
    reg [5:0]  pcnt;        // prime progress: 0,8,16,24
    reg        primed;

    // ---- combinational decode ----
    wire [31:0] bound = (range >> PREC) * p0_i;      // one small multiply (runtime p0)
    wire        bit_d = (code >= bound);            // 0 -> lower interval
    wire [31:0] r_sel = bit_d ? (range - bound) : bound;
    wire [31:0] c_sel = bit_d ? (code  - bound) : code;

    // leading-zero count -> minimal single-shot renorm shift
    // (for p=0.1, r_sel >= 2^27 always, so the result is in {0,1,3,4})
    function [5:0] clz32;
        input [31:0] x;
        integer i;
        reg done;
        begin
            clz32 = 6'd0;
            done  = 1'b0;
            for (i = 31; i >= 0; i = i - 1)
                if (!done) begin
                    if (x[i]) done = 1'b1;
                    else      clz32 = clz32 + 6'd1;
                end
        end
    endfunction

    wire [5:0]  s      = clz32(r_sel);
    wire [31:0] r_norm = r_sel << s;
    // pull the top 's' bits of rnd_in (MSB-first) into code's LSBs.
    // equivalent to s iterations of code = (code<<1)|next_bit.
    wire [31:0] c_norm = (c_sel << s) | (rnd_in >> (8 - s));

    // ---- outputs ----
    // during prime we consume a full 8-bit chunk; after, exactly 's' bits
    assign take        = primed ? {2'b00, s[3:0]} : 4'd8;
    assign basis_bit   = bit_d;
    assign basis_valid = primed & ~rst;

    // ---- sequential state ----
    always @(posedge clk) begin
        if (rst) begin
            range  <= RANGE_INIT;
            code   <= 32'd0;
            pcnt   <= 6'd0;
            primed <= 1'b0;
        end else if (!primed) begin
            code <= (code << 8) | rnd_in;           // accumulate 8 prime bits
            if (pcnt == 6'd24) primed <= 1'b1;      // after the 4th chunk -> 32 bits
            pcnt <= pcnt + 6'd8;
        end else begin
            range <= r_norm;
            code  <= c_norm;
        end
    end
endmodule

`default_nettype wire