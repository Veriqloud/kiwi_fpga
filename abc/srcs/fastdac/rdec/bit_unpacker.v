// ============================================================================
// bit_unpacker.v
//
// Reads a Standard (NOT FWFT) async/sync FIFO that returns IN_W bits per read
// and presents them downstream two bits at a time ("pairs"), with a simple
// valid/take handshake. See docs/architecture.md ("Even-bit framing").
//
//   - even path : IN_W = 16 (fifo_up_true word -> 8 pairs)
//   - uneven path: IN_W = 2 (fifo_uneven word  -> 1 pair)
//
// Read timing matches the FIFO Generator Standard FIFO: 'fifo_dout' is valid one
// clk cycle AFTER 'fifo_rd_en' is asserted on a non-empty FIFO. A read is
// launched only when the local buffer is drained (pairs == 0), so there is a
// 2-cycle refill bubble per word; both paths still beat the 40 MHz nibble rate.
//
// 'rst' is synchronous active-high in this clk domain.
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/30/2026
// Design Name: rng_test
// Module Name: bit_unpacker
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Standard-FIFO reader that unpacks IN_W-bit words into 2-bit pairs
//              with a valid/take handshake (even and uneven recombine paths).
//
// Dependencies: none
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module bit_unpacker #(
    parameter integer IN_W = 16          // FIFO read width (must be even)
)(
    input  wire            clk,
    input  wire            rst,          // sync active-high

    // ---- upstream Standard FIFO read side (1-cycle dout latency) ----
    input  wire [IN_W-1:0] fifo_dout,
    input  wire            fifo_empty,
    output wire            fifo_rd_en,

    // ---- downstream 2-bit pair interface ----
    output wire [1:0]      pair,
    output wire            pair_valid,
    input  wire            pair_take
);

    localparam integer NPAIR = IN_W/2;            // pairs per FIFO word
    localparam integer CW    = $clog2(NPAIR+1);   // pair-counter width

    reg [IN_W-1:0] sbuf;     // shift buffer, emits LSB pair first
    reg [CW-1:0]   pairs;    // valid pairs remaining in sbuf
    reg            rd_pend;  // read launched, dout arrives next cycle

    assign pair_valid = (pairs != 0);
    assign pair       = sbuf[1:0];
    assign fifo_rd_en = ~rd_pend & (pairs == 0) & ~fifo_empty;

    always @(posedge clk) begin
        if (rst) begin
            sbuf    <= {IN_W{1'b0}};
            pairs   <= {CW{1'b0}};
            rd_pend <= 1'b0;
        end else begin
            if (rd_pend) begin
                // capture the word requested last cycle
                sbuf    <= fifo_dout;
                pairs   <= NPAIR[CW-1:0];
                rd_pend <= 1'b0;
            end else if (pair_take & pair_valid) begin
                // hand off the LSB pair, shift the next one down
                sbuf  <= sbuf >> 2;
                pairs <= pairs - 1'b1;
            end

            // launch a refill read when drained (pairs==0 => take is inactive)
            if (fifo_rd_en) rd_pend <= 1'b1;
        end
    end

endmodule

`default_nettype wire
