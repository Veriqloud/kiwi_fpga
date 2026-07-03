// ============================================================================
// angles_top_wrapper.v
//
// Source split for the mixed-distribution RNG (see docs/architecture.md).
//
// A single 128-bit true-RNG stream enters as an AXI4-Stream slave fed by the
// XDMA H2C channel (s_axis_aclk = 250 MHz; we are the stream SINK). A beat is
// 'din' = s_axis_tdata[127:0], accepted when s_axis_tvalid & s_axis_tready.
// A small word demux/arbiter routes each accepted 128-bit beat to ONE of two
// branches by backpressure:
//
//   even  / "true"  path : fifo_up_true_wrapper  (fifo1_true, 128->16 async)
//                          read @clk200 -> downstream even-bit unpacker
//   uneven / "basis" path: rangedec_top_wrapper  (fifo_up + controller +
//                          basis_rangedec), 2 biased bits @clk200
//
// Any true bit is interchangeable, so routing whole 128-bit words adds NO bias.
// The split lives entirely in the wr_clk domain, before either branch's FIFO,
// so each branch keeps its own clean async CDC.
//
// Arbitration = weighted round-robin + redirect-on-full:
//   - The even path consumes 80 Mbit/s, the basis entropy draw ~37.5 Mbit/s
//     (~1:2). So 1 of every 3 accepted words is *preferred* to the basis path,
//     the other 2 to the even path -- matching the rate budget.
//   - If the preferred branch is full, the word is redirected to the other
//     branch (no wasted word, no needless backpressure).
//   - s_axis_tready deasserts (stream backpressure) only when BOTH branches are
//     full, i.e. there is nowhere to put the beat.
//   - Surplus over each branch's consumption is dropped naturally via that
//     branch's full flag (the source over-produces: 160 > 80 + 37.5).
//
// s_axis_tkeep / s_axis_tlast are accepted for direct XDMA connectivity but
// IGNORED: the host always sends full 128-bit beats and packet boundaries carry
// no meaning for a raw entropy stream.
//
// Clock domains: s_axis_aclk = 250 MHz (producer) / clk80 (basis processing) /
// clk200 (output). 'rst' is asynchronous, active high.
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/30/2026
// Design Name: rng_test
// Module Name: angles_top_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Mixed-distribution RNG top. Splits one 128-bit AXI4-Stream
//              true-RNG stream (XDMA H2C, 250 MHz) into the even
//              (fifo_up_true_wrapper) and uneven/basis (rangedec_top_wrapper)
//              paths by weighted backpressure, then recombines via bit_unpacker
//              + nibble_assembler into fifo2 (fifo_4x4_wrapper) -> dout[3:0]
//              {E,U,E,U} @ 40 MHz.
//
// Dependencies: fifo_up_true_wrapper.v, rangedec_top_wrapper.v, bit_unpacker.v,
//               nibble_assembler.v, fifo_4x4_wrapper.v
//               (-> fifo_up_wrapper.v, controller.v, basis_rangedec.v,
//                   fifo_uneven_1x2_wrapper.v)
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module angles_top_wrapper #(
    parameter        PREC = 15
)(
    input  wire         rst,                  // async active-high (to FIFOs)

    // ---- entropy producer: AXI4-Stream slave (XDMA H2C, 250 MHz) ----
    input  wire         s_axis_aclk,
    input  wire [127:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,        // deasserts when both branches full
    input  wire [15:0]  s_axis_tkeep,         // ignored (always full beats)
    input  wire         s_axis_tlast,         // ignored (continuous stream)

    // ---- basis processing clock (80 MHz domain) ----
    input  wire         clk80,
    input  wire [15:0]  rdec_p0_i,            // P(bit==0) in Q(PREC); MUST be clk80-synchronous
                                             //   (latched upstream via the reg_enable handshake)

    // ---- output / consumer domain (200 MHz) ----
    input  wire         clk200,

    // mixed-distribution RNG output: 4 bits {E,U,E,U} @ 40 MHz (fifo2 read side)
    input  wire         rd_en_4,              // 40 MHz read strobe (200/5)
    output wire [3:0]   dout,                 // {even,uneven,even,uneven}
    output wire         dout_empty,

    // even/true 128->16 entropy-FIFO status (mirrors the legacy fifo_128x16 flags)
    output wire         even_almost_full,
    output wire         even_empty
);

    // ---------------------------------------------------------------------
    // clk200-synchronized reset (async assert, sync deassert) for the
    // recombine logic and fifo2 synchronous reset.
    // ---------------------------------------------------------------------
    reg [1:0] rst200_sync;
    always @(posedge clk200 or posedge rst) begin
        if (rst) rst200_sync <= 2'b11;
        else     rst200_sync <= {rst200_sync[0], 1'b0};
    end
    wire rst200 = rst200_sync[1];

    // ---------------------------------------------------------------------
    // branch fill flags (read back from each branch's write side)
    // ---------------------------------------------------------------------
    wire up_full;          // basis path entropy FIFO full        (rangedec ent_full)
    wire tr_full;          // even  path entropy FIFO full        (fifo_up_true full)
    wire up_almost_full;   // basis path entropy FIFO almost_full (rangedec ent_almost_full)
    wire tr_almost_full;   // even  path entropy FIFO almost_full (fifo_up_true almost_full)

    // A branch accepts new beats only while it is NOT almost-full, leaving write
    // headroom so it never reaches 'full'. This mirrors the old fifo_128x16,
    // whose almost_full flag gated s_axis_tready to prevent overflow.
    wire up_can = ~up_almost_full;   // basis branch has headroom
    wire tr_can = ~tr_almost_full;   // even  branch has headroom
    wire any_can = up_can | tr_can;

    // AXI4-Stream handshake: ready when at least one branch has room; a beat is
    // accepted on tvalid & tready.
    assign s_axis_tready = any_can;
    wire   word_go       = s_axis_tvalid & s_axis_tready;

    // ---------------------------------------------------------------------
    // weighted round-robin: 1 of every 3 accepted beats prefers the basis path
    // (rate ratio ~37.5 : 80 Mbit/s). rr advances only on an accepted beat.
    // ---------------------------------------------------------------------
    reg [1:0] rr;
    always @(posedge s_axis_aclk) begin
        if (rst)            rr <= 2'd0;
        else if (word_go)   rr <= (rr == 2'd2) ? 2'd0 : (rr + 2'd1);
    end

    wire prefer_up = (rr == 2'd0);

    // route to basis when it can accept AND (it is preferred OR the even branch
    // is full); otherwise route to the even branch if it can accept. Mutually
    // exclusive: one word -> exactly one branch.
    wire route_up   = up_can & (prefer_up | ~tr_can);
    wire route_true = tr_can & ~route_up;

    // 'full' is a hard backstop: never assert a write into a full FIFO, even if
    // almost_full arbitration above ever let a beat slip through.
    wire up_wr_en = word_go & route_up   & ~up_full;
    wire tr_wr_en = word_go & route_true & ~tr_full;

    // ---------------------------------------------------------------------
    // uneven / basis path: full biased datapath (own fifo_up inside)
    // ---------------------------------------------------------------------
    rangedec_top_wrapper #(
        .PREC (PREC)
    ) u_basis (
        .rst         (rst),
        // entropy write side (s_axis_aclk): fed by the arbiter
        .wr_clk      (s_axis_aclk),
        .ent_din     (s_axis_tdata),
        .ent_wr_en   (up_wr_en),
        .ent_full    (up_full),
        .ent_almost_full (up_almost_full),
        // processing clock
        .clk80       (clk80),
        .rdec_p0_i   (rdec_p0_i),   // runtime P0, clk80-synced upstream
        // biased read side (clk200) -> uneven unpacker
        .clk200       (clk200),
        .uneven_rd_en (uv_rd_en),
        .uneven_dout  (uv_dout),
        .uneven_empty (uv_empty)
    );

    // ---------------------------------------------------------------------
    // even / true path: 128->16 async FIFO, read @clk200 -> even-bit unpacker
    // ---------------------------------------------------------------------
    fifo_up_true_wrapper u_true (
        .rst           (rst),
        // write side (s_axis_aclk): fed by the arbiter
        .wr_clk        (s_axis_aclk),
        .din           (s_axis_tdata),
        .wr_en         (tr_wr_en),
        .full          (tr_full),
        .almost_full   (tr_almost_full),   // -> arbiter up/tr_can + status below
        .wr_data_count (/* unused */),
        // read side (clk200) -> even unpacker
        .rd_clk        (clk200),
        .rd_en         (tr_rd_en),
        .dout          (tr_dout),
        .empty         (tr_empty),
        .rd_data_count (/* unused */),
        // status (unused)
        .wr_rst_busy   (/* unused */),
        .rd_rst_busy   (/* unused */)
    );

    // expose the even/true 128->16 FIFO status (mirrors legacy fifo_128x16 flags):
    // almost_full also gates the arbiter above; empty is the read-side flag used
    // by the even unpacker below.
    assign even_almost_full = tr_almost_full;
    assign even_empty       = tr_empty;

    // =====================================================================
    // RECOMBINE (clk200): unpack each path to 2-bit pairs, assemble {E,U,E,U}
    // nibbles, buffer in fifo2 (fifo_4x4), drain at 40 MHz on rd_en_4.
    // =====================================================================

    // even path: fifo_up_true (16b word) -> 8 pairs
    wire [15:0] tr_dout;
    wire        tr_empty;
    wire        tr_rd_en;
    wire [1:0]  even_pair;
    wire        even_valid;
    wire        even_take;

    bit_unpacker #(.IN_W(16)) u_even_unpack (
        .clk        (clk200),
        .rst        (rst200),
        .fifo_dout  (tr_dout),
        .fifo_empty (tr_empty),
        .fifo_rd_en (tr_rd_en),
        .pair       (even_pair),
        .pair_valid (even_valid),
        .pair_take  (even_take)
    );

    // uneven path: fifo_uneven (2b word) -> 1 pair
    wire [1:0]  uv_dout;
    wire        uv_empty;
    wire        uv_rd_en;
    wire [1:0]  uneven_pair;
    wire        uneven_valid;
    wire        uneven_take;

    bit_unpacker #(.IN_W(2)) u_uneven_unpack (
        .clk        (clk200),
        .rst        (rst200),
        .fifo_dout  (uv_dout),
        .fifo_empty (uv_empty),
        .fifo_rd_en (uv_rd_en),
        .pair       (uneven_pair),
        .pair_valid (uneven_valid),
        .pair_take  (uneven_take)
    );

    // assemble one {E,U,E,U} nibble when both pairs are ready and fifo2 has room
    wire [3:0] nibble;
    wire       nibble_wr_en;
    wire       fifo2_full;

    nibble_assembler u_assemble (
        .even_pair    (even_pair),
        .even_valid   (even_valid),
        .even_take    (even_take),
        .uneven_pair  (uneven_pair),
        .uneven_valid (uneven_valid),
        .uneven_take  (uneven_take),
        .nibble       (nibble),
        .nibble_wr_en (nibble_wr_en),
        .fifo2_full   (fifo2_full)
    );

    // fifo2: common-clock 4->4, drained at 40 MHz by rd_en_4
    fifo_4x4_wrapper u_fifo2 (
        .clk         (clk200),
        .srst        (rst200),
        .din         (nibble),
        .wr_en       (nibble_wr_en),
        .rd_en       (rd_en_4),
        .dout        (dout),
        .full        (fifo2_full),
        .empty       (dout_empty),
        .wr_rst_busy (/* unused */),
        .rd_rst_busy (/* unused */)
    );

endmodule

`default_nettype wire
