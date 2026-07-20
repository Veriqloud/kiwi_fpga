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
// clk200 (output). Resets are active-high and arrive PRE-SYNCHRONIZED per
// domain from clk_rst_mngt (rst_clk250 / rst_clk80 / rst_clk200).
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
//              and captures one {E,U,E,U} nibble per rd_en_4 tick into dout[3:0]
//              @ 40 MHz (no output FIFO).
//
// Dependencies: fifo_up_true_wrapper.v, rangedec_top_wrapper.v, bit_unpacker.v,
//               reset_register.v
//               (nibble_assembler.v / fifo_4x4_wrapper.v + fifo_4x4 IP no longer used)
//               (-> fifo_up_wrapper.v, controller.v, basis_rangedec.v,
//                   fifo_uneven_1x2_wrapper.v)
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module angles_top_wrapper #(
    parameter         PREC        = 15
)(
    input  wire         rst_clk200,
    input  wire         rst_clk80,
    input  wire         rst_clk250,

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

    // mixed-distribution RNG output: 4 bits {E,U,E,U} @ 40 MHz (registered on rd_en_4)
    input  wire         rd_en_4,              // 40 MHz read strobe (200/5)
    output wire [3:0]   dout,                 // {even,uneven,even,uneven}, valid 2 cyc after rd_en_4
    output wire         dout_empty,           // asserted when a branch is not ready this tick

    // even/true 128->16 entropy-FIFO status (mirrors the legacy fifo_128x16 flags)
    output wire         even_almost_full,
    output wire         even_empty,

    // uneven 128->16 entropy-FIFO status 
    output wire         up_almost_full,   // write-side (clk80)
    output wire         up_empty,          // read-side  (clk200)

    // uneven/basis output-FIFO (fifo_1x2) status
    output wire         uneven_almost_full,   // write-side (clk80)
    output wire         uneven_empty,         // read-side  (clk200)

    // sticky error flags (docs/monitoring.md §2). Each is 1 bit and quasi-
    // static in its native domain: cross with a plain 2-FF synchronizer
    // (ASYNC_REG) at the consumer; cleared only by that domain's reset.
    output wire         err_ctrl_underrun,    // E1 (clk80) : decoder ran on missing entropy
    output wire         err_uneven_gate,      // E2 (clk200): fifo_1x2 read-while-empty (never-event)
    output wire         err_endpoint_ovread   // E3 (clk200): rd_en_4 on a not-ready tick
);

    // ---------------------------------------------------------------------
    // resets: rst_clk250 / rst_clk80 / rst_clk200 arrive pre-synchronized per
    // domain from clk_rst_mngt and are used directly (no local sync). The old
    // local synchronizer is kept below for reference only.
    // (* ASYNC_REG = "TRUE" *) reg [2:0] rng_rst_r;
    // initial begin rng_rst_r <= 0; end
    // always @(posedge s_axis_aclk) begin
    //     rng_rst_r <= {rng_rst_r[1:0], rst};
    // end

    // wire rst_saxi;   // active-high reset, s_axis_aclk domain
    // reset_register #(.RST_ACTIVE_LEVEL("HIGH")) u_rst_saxi (
    //     .clk_i  (s_axis_aclk),
    //     .rst_i  (rng_rst_r[1]),
    //     .clk_o  (/* unused */),
    //     .rstn_o (/* unused */),
    //     .rst_o  (rst_saxi)
    // );

    // ---------------------------------------------------------------------
    // branch fill flags (read back from each branch's write side)
    // ---------------------------------------------------------------------
    wire up_full;          // basis path entropy FIFO full        (rangedec ent_full)
    wire tr_full;          // even  path entropy FIFO full        (fifo_up_true full)
    // up_almost_full is an output port above (driven by rangedec ent_almost_full)
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
        if (rst_clk250)       rr <= 2'd0;
        else if (word_go)   rr <= (rr == 2'd2) ? 2'd0 : (rr + 2'd1);
    end

    wire prefer_up = (rr == 2'd0);

    // route to basis when it can accept AND (it is preferred OR the even branch
    // is full); otherwise route to the even branch if it can accept. Mutually
    // exclusive: one word -> exactly one branch.
    wire route_up   = up_can & (prefer_up | ~tr_can);
    wire route_true = tr_can & ~route_up;

    // Gate writes on almost_full (leave write headroom); 'full' stays as a hard
    // backstop. route_* already implies ~almost_full via up_can/tr_can, so the
    // ~almost_full term is belt-and-suspenders -- matches the uneven-FIFO write
    // gate in rangedec_top_wrapper and makes the intent explicit at the write.
    wire up_wr_en = word_go & route_up   & ~up_almost_full & ~up_full;
    wire tr_wr_en = word_go & route_true & ~tr_almost_full & ~tr_full;

    // ---------------------------------------------------------------------
    // branch <-> unpacker signals (declared here: used by the instances below)
    // ---------------------------------------------------------------------
    wire [15:0] tr_dout;         // even path: fifo_up_true read data (clk200)
    wire        tr_empty;
    wire        tr_rd_en;
    wire [1:0]  uv_dout;         // uneven path: fifo_1x2 read data (clk200)
    wire        uv_empty;
    wire        uv_almost_full;
    wire        uv_rd_en;

    // ---------------------------------------------------------------------
    // uneven / basis path: full biased datapath (own fifo_up inside)
    // ---------------------------------------------------------------------
    rangedec_top_wrapper #(
        .PREC (PREC)
    ) u_basis (
        .rst_clk80    (rst_clk80),
        .rst_clk250   (rst_clk250),
        // entropy write side (s_axis_aclk): fed by the arbiter
        .wr_clk      (s_axis_aclk),
        .ent_din     (s_axis_tdata),
        .ent_wr_en   (up_wr_en),
        .ent_full    (up_full),
        .ent_almost_full (up_almost_full),
        .up_empty    (up_empty),
        // processing clock
        .clk80       (clk80),
        .rdec_p0_i   (rdec_p0_i),   // runtime P0, clk80-synced upstream
        // biased read side (clk200) -> uneven unpacker
        .clk200       (clk200),
        .uneven_rd_en (uv_rd_en),
        .uneven_dout  (uv_dout),
        .uneven_empty (uv_empty),
        .uneven_almost_full (uv_almost_full),
        // E1 sticky, latched inside in clk80 (take-clamp event)
        .err_ctrl_underrun (err_ctrl_underrun)
    );

    // ---------------------------------------------------------------------
    // even / true path: 128->16 async FIFO, read @clk200 -> even-bit unpacker
    // ---------------------------------------------------------------------
    fifo_up_true_wrapper u_true (
        .rst           (rst_clk250),
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

    // expose the uneven/basis output-FIFO (fifo_1x2) status: read-side empty
    // (feeds the uneven unpacker below); write-side almost_full is driven
    // directly from u_basis above.
    assign uneven_empty     = uv_empty;
    assign uneven_almost_full = uv_almost_full;
    // =====================================================================
    // RECOMBINE (clk200): unpack each path to 2-bit pairs and capture one
    // {E,U,E,U} nibble per rd_en_4 tick directly (no fifo2 buffer).
    // =====================================================================

    // even path: fifo_up_true (16b word) -> 8 pairs
    wire [1:0]  even_pair;
    wire        even_valid;
    wire        even_take;

    bit_unpacker #(.IN_W(16)) u_even_unpack (
        .clk        (clk200),
        .rst        (rst_clk200),
        .fifo_dout  (tr_dout),
        .fifo_empty (tr_empty),
        .fifo_rd_en (tr_rd_en),
        .pair       (even_pair),
        .pair_valid (even_valid),
        .pair_take  (even_take)
    );

    // uneven path: fifo_uneven (2b word) -> 1 pair
    wire [1:0]  uneven_pair;
    wire        uneven_valid;
    wire        uneven_take;

    bit_unpacker #(.IN_W(2)) u_uneven_unpack (
        .clk        (clk200),
        .rst        (rst_clk200),
        .fifo_dout  (uv_dout),
        .fifo_empty (uv_empty),
        .fifo_rd_en (uv_rd_en),
        .pair       (uneven_pair),
        .pair_valid (uneven_valid),
        .pair_take  (uneven_take)
    );

    // ---------------------------------------------------------------------
    // NIBBLE CAPTURE (clk200) -- no fifo2. Both unpackers hold their current
    // pair until taken. On each rd_en_4 tick, if both branches are ready, we
    // advance both unpackers by one pair and register the assembled {E,U,E,U}
    // nibble. Each bit_unpacker prefetches its next word, so its pair stays
    // valid continuously between takes -> both_ready holds and no underflow
    // once primed.
    //
    // LATENCY: the replaced fifo_16x4 was a Standard FIFO with embedded output
    // registers (C_PRELOAD_LATENCY = 2), i.e. dout appeared 2 clk200 cycles
    // after the rd_en_4 edge. We reproduce that exactly with a 2-stage register
    // (capture -> pipeline) so the consumer's rd_en_4 -> rd_en_4_shift[0]
    // sampling in jesd_transport needs no change. dout is registered (not
    // combinational) and holds stable across the whole 40 MHz period.
    // ---------------------------------------------------------------------
    wire       both_ready = even_valid & uneven_valid;
    wire [3:0] nibble     = {even_pair[1], uneven_pair[1], even_pair[0], uneven_pair[0]};
    wire       pop        = rd_en_4 & both_ready;   // consume one pair from each branch

    assign even_take   = pop;
    assign uneven_take = pop;

    reg [3:0] dout_r0;   // stage 1: captured on pop      (1 cycle after rd_en_4)
    reg [3:0] dout_r;    // stage 2: pipeline to match fifo_16x4 (2 cycles after rd_en_4)
    always @(posedge clk200) begin
        if (rst_clk200) begin
            dout_r0 <= 4'b0;
            dout_r  <= 4'b0;
        end else begin
            if (pop) dout_r0 <= nibble;             // hold until next tick (stable 5 cycles)
            dout_r <= dout_r0;                       // second stage = embedded-register latency
        end
    end

    assign dout       = dout_r;
    assign dout_empty = ~both_ready;                // a read on this tick would underflow

    // ---------------------------------------------------------------------
    // E2/E3 -- sticky output-side error flags (docs/monitoring.md §2.2, §2.3).
    // E2 is a never-event: the bit_unpacker gate (fifo_rd_en = ~rd_pend &
    //     ~pfull & ~fifo_empty) makes a read-while-empty impossible; if this
    //     latches, the fifo_1x2 read contract broke (CDC fault or an edit
    //     upstream). Also the fabric equivalent of the IP Underflow_Flag.
    // E3 latches when the endpoint pops on a tick with a branch not ready --
    //     dout then holds the PREVIOUS nibble (silent repeat downstream).
    //     Self-contained: rd_en_4 & ~both_ready, nothing else. NOTE: the
    //     endpoint (jesd_transport) free-runs rd_en_4 from the first PPS
    //     edge and ignores dout_empty, so entropy streaming must be up and
    //     the pipe primed BEFORE rd_en_4 starts ticking -- otherwise E3
    //     latches at bring-up and every dead tick after it is masked.
    // Cleared by rst_clk200 only.
    // ---------------------------------------------------------------------
    reg err_uneven_gate_r;
    reg err_endpoint_ovread_r;
    always @(posedge clk200) begin
        if (rst_clk200) begin
            err_uneven_gate_r     <= 1'b0;
            err_endpoint_ovread_r <= 1'b0;
        end else begin
            if (uv_rd_en & uv_empty)   err_uneven_gate_r     <= 1'b1;
            if (rd_en_4 & ~both_ready) err_endpoint_ovread_r <= 1'b1;
        end
    end
    assign err_uneven_gate     = err_uneven_gate_r;
    assign err_endpoint_ovread = err_endpoint_ovread_r;

endmodule

`default_nettype wire
