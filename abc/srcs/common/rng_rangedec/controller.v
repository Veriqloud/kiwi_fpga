`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: Qline_turnkey
// Module Name: controller
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Bit-buffer / prefetch controller. Drains 16-bit words from the
//              upstream FIFO into a 64-bit shift buffer and presents rnd_in[7:0]
//              to basis_rangedec, consuming `take` bits per cycle.
//
// Dependencies: fifo_up_wrapper.v, basis_rangedec.v
// Revision;
// Revision 0.01 - File Created
// Revision 0.02 - No change
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// controller.v
// Provides rnd_in[7:0] to `basis_rangedec` and drives FIFO read requests.
// Maintains a 64-bit shift buffer of random bits (MSB = next bit to consume)
// and prefetches 16-bit words from the upstream FIFO to keep it stocked.
//
// Upstream FIFO is a *Standard* FIFO (NOT first-word-fall-through): asserting
// fifo_rd_en while fifo_rd_empty==0 pops the head, and fifo_rd_data becomes
// valid one clock cycle *after* the read. We therefore track a one-cycle
// delayed copy of fifo_rd_en (rd_valid) that marks the cycle in which the
// popped word is present on fifo_rd_data, and insert the word then.
//
// Operation summary:
// - rnd_in   = bit_buffer[63:56]                  (MSB-first next byte)
// - each cycle the controller consumes `take` bits (0..8) by shifting left
// - if the post-update level drops below PREFETCH_TH, assert fifo_rd_en
// - one cycle later (rd_valid high) the popped 16-bit word is inserted directly
//   below the valid bits, so it stays correctly aligned at any fill level
//
// Sizing: a request fires only while the level is < PREFETCH_TH (32). Between
// the request and the insert (one cycle later) the level can only drop, so at
// insert time avail <= 31 and the worst-case post-insert level is
// (32-1)+16 = 47 < 64; the 64-bit buffer therefore never overflows. Reads are
// pipelined (one request and one insert per cycle), so at most one read is
// ever outstanding because next_avail already counts the word arriving now.

`default_nettype none

module controller (
    input  wire        clk,
    input  wire        rst,

    // FIFO read-side (read clock domain), Standard FIFO (1-cycle read latency)
    input  wire [15:0] fifo_rd_data,
    input  wire        fifo_rd_empty,
    output reg         fifo_rd_en,

    // from range decoder
    input  wire [3:0]  take,      // number of bits consumed this cycle (0..8)

    // to range decoder
    output wire [7:0]  rnd_in,

    // current buffer fill level (valid bits, 0..64). Lets the top gate the
    // range decoder until enough real entropy has been prefetched to prime.
    output wire [6:0]  bits_level
);

    localparam integer PREFETCH_TH = 32;   // request a word when bits available < this

    reg [63:0] bit_buffer;   // valid bits occupy the top `bits_avail` positions
    reg [6:0]  bits_avail;   // number of valid bits in buffer (0..64)
    reg        rd_valid;     // 1 when fifo_rd_data holds a freshly popped word
                             // (delayed copy of fifo_rd_en; Standard FIFO latency)

    assign rnd_in     = bit_buffer[63:56];
    assign bits_level = bits_avail;

    // combinational next-state
    reg [63:0] buf_shift;    // buffer after consuming `take` bits
    reg [6:0]  avail_shift;  // bits available after consuming
    reg [6:0]  ins_shift;    // left-shift that aligns an incoming word
    reg [63:0] next_buffer;
    reg [6:0]  next_avail;

    always @* begin
        // consume `take` bits (MSB-first); clamp to avoid underflow
        if (take >= bits_avail) begin
            buf_shift   = 64'd0;
            avail_shift = 7'd0;
        end else begin
            buf_shift   = bit_buffer << take;
            avail_shift = bits_avail - take;
        end

        // optionally insert a freshly-popped 16-bit word directly below the
        // (post-consume) valid bits. avail_shift is guaranteed <= 31 whenever
        // rd_valid is high, so ins_shift lands in [17,48] with no collision.
        ins_shift = 7'd48 - avail_shift;
        if (rd_valid) begin
            next_buffer = buf_shift | ({48'd0, fifo_rd_data} << ins_shift);
            next_avail  = avail_shift + 7'd16;
        end else begin
            next_buffer = buf_shift;
            next_avail  = avail_shift;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            bit_buffer <= 64'd0;
            bits_avail <= 7'd0;
            fifo_rd_en <= 1'b0;
            rd_valid   <= 1'b0;
        end else begin
            bit_buffer <= next_buffer;
            bits_avail <= next_avail;
            // a word read this cycle (fifo_rd_en high) is valid on fifo_rd_data
            // next cycle: delay the request by one to mark the insert window.
            rd_valid   <= fifo_rd_en;
            // request another word when the resulting level is low and data is
            // available; next_avail already accounts for the word arriving this
            // cycle (rd_valid), so at most one read is ever outstanding.
            fifo_rd_en <= (next_avail < PREFETCH_TH) && ~fifo_rd_empty;
        end
    end

endmodule

`default_nettype wire
