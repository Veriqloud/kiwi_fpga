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
// clk cycle AFTER 'fifo_rd_en' is asserted on a non-empty FIFO.
//
// PREFETCH: the next FIFO word is fetched into a 1-word lookahead buffer (pbuf)
// while the current word (sbuf) is still being emitted. When the LAST pair of
// sbuf is taken, sbuf is reloaded from pbuf on the SAME cycle, so 'pairs' never
// returns to 0 and 'pair' changes ONLY on an accepted 'pair_take'. Consequently
// 'pair' stays valid and stable between takes (no refill bubble), even on the
// uneven path where every take consumes a whole word. This matters for the
// recombine: the {E,U,E,U} nibble is then never assembled from a stale/zero pair.
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
//              with a valid/take handshake and a 1-word prefetch so the pair
//              output holds stable between takes (even and uneven recombine paths).
//
// Dependencies: none
// Revision:
// Revision 0.02 - Add 1-word prefetch: pair holds stable, no drain-to-0 bubble
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

    reg [IN_W-1:0] sbuf;     // current word, emits LSB pair first
    reg [CW-1:0]   pairs;    // valid pairs remaining in sbuf (0 => sbuf empty)
    reg [IN_W-1:0] pbuf;     // 1-word lookahead (prefetched next word)
    reg            pfull;    // pbuf holds a valid word
    reg            rd_pend;  // read launched last cycle, dout valid this cycle

    assign pair       = sbuf[1:0];
    assign pair_valid = (pairs != 0);

    // Keep the lookahead slot full: read whenever it is empty, no read is already
    // in flight, and the FIFO has data. (pfull=1 blocks further reads, so at most
    // one word is prefetched.)
    assign fifo_rd_en = ~rd_pend & ~pfull & ~fifo_empty;

    wire take = pair_take & pair_valid;

    always @(posedge clk) begin
        if (rst) begin
            sbuf    <= {IN_W{1'b0}};
            pairs   <= {CW{1'b0}};
            pbuf    <= {IN_W{1'b0}};
            pfull   <= 1'b0;
            rd_pend <= 1'b0;
        end else begin
            // (1) complete a pending read into the lookahead slot
            if (rd_pend) begin
                pbuf    <= fifo_dout;
                pfull   <= 1'b1;
                rd_pend <= 1'b0;
            end

            // (2) emit / reload the current word
            if (take) begin
                if (pairs > 1) begin
                    // more pairs in sbuf: shift the next one down
                    sbuf  <= sbuf >> 2;
                    pairs <= pairs - 1'b1;
                end else if (pfull) begin
                    // last pair taken: jump straight to the prefetched word
                    sbuf  <= pbuf;
                    pairs <= NPAIR[CW-1:0];
                    pfull <= 1'b0;
                end else begin
                    // lookahead not ready (source starved): drop to empty
                    pairs <= {CW{1'b0}};
                end
            end else if (pairs == 0 && pfull) begin
                // prime the (empty) current word from the lookahead
                sbuf  <= pbuf;
                pairs <= NPAIR[CW-1:0];
                pfull <= 1'b0;
            end

            // (3) issue the next prefetch read
            if (fifo_rd_en) rd_pend <= 1'b1;
        end
    end

endmodule

`default_nettype wire
