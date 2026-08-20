`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: Qline_turnkey
// Module Name: rangedec_top_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Top-level biased-RNG datapath. Chains the entropy FIFO
//              (fifo_up_wrapper) -> controller -> basis_rangedec -> uneven FIFO
//              (fifo_uneven_1x2_wrapper) across the wr_clk / clk80 / clk200
//              domains.
//
// Dependencies: fifo_up_wrapper.v, controller.v, basis_rangedec.v,
//               fifo_uneven_1x2_wrapper.v, reset_register.v
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - No change
// Revision 0.03 - Exposed entropy FIFO's wr_rst_busy as ent_wr_rst_busy so
//                 the AXI-Stream slave upstream can gate tready on it
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
// ============================================================================
// rangedec_top_wrapper.v
//
// Top-level integration of the biased-RNG datapath. Chains:
//
//   entropy(128b @ wr_clk)
//        -> fifo_up_wrapper          (async 128->16, drains in clk80 domain)
//        -> controller               (16b prefetch -> 8b rnd_in, clk80)
//        <-> basis_rangedec          (rnd_in/take handshake, clk80)
//        -> basis_bit (1b @ clk80)
//        -> fifo_uneven_1x2_wrapper  (async 1->2, drains in clk200 domain)
//        -> uneven_dout (2 biased bits @ clk200)  -> downstream consumer
//
// Clock domains:
//   wr_clk : entropy producer domain (any frequency)
//   clk80  : processing domain -- controller, basis_rangedec, fifo_up READ
//            side and uneven FIFO WRITE side ALL run here (one shared clock).
//   clk200 : uneven/biased consumer domain -- uneven FIFO READ side.
//
// Resets arrive PRE-SYNCHRONIZED per domain (one synchronizer per domain in
// clk_rst_mngt): rst_clk80 drives the clk80 logic (controller, basis_rangedec,
// rng_ready) and the uneven FIFO's rst pin (write side = clk80); rst_clk250 is
// synchronous to wr_clk and drives the entropy FIFO's rst pin (write side).
// Do NOT re-synchronize them locally -- that recreates the CDC-11 fan-out.
//
// See the in-line NOTEs for the two open design points discussed separately:
//   (1) startup priming of basis_rangedec before the controller buffer fills,
//   (2) write/read rate balance on the uneven FIFO (over-produce + drop on full
//       so it never underflows).
// ============================================================================

`default_nettype none

module rangedec_top_wrapper #(
    parameter        PREC = 15
)(
    // input  wire         rst,                  // async active-high (to FIFOs)
    input  wire         rst_clk80,            // synchronous to clk80
    input  wire         rst_clk250,           // synchronous to clk250

    // ---- entropy write interface (producer domain) ----
    input  wire         wr_clk,
    input  wire [127:0] ent_din,
    input  wire         ent_wr_en,
    output wire         ent_full,
    output wire         ent_almost_full,
    output wire         ent_wr_rst_busy,      // gates s_axis_tready upstream during FIFO reset recovery
    output wire         up_empty,

    // ---- processing clock (80 MHz domain) ----
    input  wire         clk80,
    input  wire [15:0]  rdec_p0_i,            // P(bit==0) in Q(PREC); MUST be clk80-synchronous
                                             //   (latched upstream via the reg_enable handshake)

    // ---- uneven (biased) read interface (consumer / 200 MHz domain) ----
    input  wire         clk200,
    input  wire         uneven_rd_en,
    output wire [1:0]    uneven_dout,          // 2 biased bits @clk200
    output wire         uneven_empty,         // uneven FIFO empty     (read-side, clk200)
    output wire         uneven_almost_full,   // uneven FIFO almost_full (write-side, clk80)

    // ---- sticky error flag (docs/monitoring.md §2.1) ----
    output wire         err_ctrl_underrun     // E1: decoder consumed bits the controller
                                              //     did not hold; sticky, clk80 domain.
                                              //     Quasi-static: 2-FF sync at the consumer.
);

    // ---------------------------------------------------------------------
    // P0 (Bernoulli threshold)
    // ---------------------------------------------------------------------
    // upstream FIFO (128b entropy -> 16b words) read in the clk80 domain
    // ---------------------------------------------------------------------
    wire [15:0] up_dout;
    // NOTE: up_empty is declared as an output port above (exposed as an
    // upstream-FIFO status flag); it is also consumed here by the controller.
    wire        ctrl_fifo_rd_en;

    fifo_up_wrapper u_fifo_up (
        .rst           (rst_clk250),
        // write side: entropy producer domain
        .wr_clk        (wr_clk),
        .din           (ent_din),
        .wr_en         (ent_wr_en),
        .full          (ent_full),
        .almost_full   (ent_almost_full),
        // read side: clk80
        .rd_clk        (clk80),
        .rd_en         (ctrl_fifo_rd_en),
        .dout          (up_dout),
        .empty         (up_empty),
        // status
        .wr_rst_busy   (ent_wr_rst_busy),
        .rd_rst_busy   (/* unused */)
    );

    // ---------------------------------------------------------------------
    // controller <-> basis_rangedec (rnd_in / take handshake), clk80 domain
    // ---------------------------------------------------------------------
    // NOTE(1) fix: basis_rangedec self-primes on a fixed 4-cycle counter and
    // has no rnd_in-valid input, so left ungated it would prime/run on the
    // controller's zero-fill before any real entropy arrives. We therefore:
    //   - hold the decoder in reset until the controller has prefetched a full
    //     prime's worth of REAL bits (bits_level >= PRIME_BITS), and
    //   - force its 'take' to 0 while held, so the controller FILLS without
    //     draining (its default take is 8, which would otherwise empty the buf).
    // 'rng_ready' is sticky: once primed-enough it stays asserted until reset,
    // so a momentary dip in level can never yank the decoder back into reset.
    localparam [6:0] PRIME_BITS = 7'd32;   // 4 x 8-bit prime chunks

    wire [7:0] ctrl_rnd_in;
    wire [3:0] rdec_take;          // raw 'take' out of the decoder
    wire [6:0] ctrl_level;         // controller buffer fill level

    reg  rng_ready;
    always @(posedge clk80) begin
        if (rst_clk80)                     rng_ready <= 1'b0;
        else if (ctrl_level >= PRIME_BITS) rng_ready <= 1'b1;
    end

    wire        rdec_rst     = rst_clk80 | ~rng_ready;
    wire [3:0]  take_to_ctrl = rng_ready ? rdec_take : 4'd0;

    controller u_ctrl (
        .clk           (clk80),
        .rst           (rst_clk80),
        // upstream FIFO read side (Standard FIFO, 1-cycle latency)
        .fifo_rd_data  (up_dout),
        .fifo_rd_empty (up_empty),
        .fifo_rd_en    (ctrl_fifo_rd_en),
        // range-decoder handshake (take gated until primed-enough)
        .take          (take_to_ctrl),
        .rnd_in        (ctrl_rnd_in),
        .bits_level    (ctrl_level)
    );

    wire rdec_bit;
    wire rdec_valid;

    basis_rangedec #(
        .PREC (PREC)
    ) u_rdec (
        .clk         (clk80),
        .rst         (rdec_rst),       // held until controller buffer is primed
        .p0_i        (rdec_p0_i),      // runtime Bernoulli threshold (clk80-synced upstream)
        .rnd_in      (ctrl_rnd_in),
        .take        (rdec_take),
        .basis_bit   (rdec_bit),
        .basis_valid (rdec_valid)
    );

    // ---------------------------------------------------------------------
    // downstream FIFO (1b basis_bit @ clk80 -> 2b uneven bits @ clk200)
    // ---------------------------------------------------------------------
    wire uneven_full;
    wire uneven_wr_rst_busy;

    // Only push real symbols, never while (almost) full or during reset recovery.
    // NOTE(2): producer (80 Mb/s) and consumer (2b @ rd_en) are nominally rate-
    // matched; rely on over-production + this ~almost_full mask to drop surplus
    // bits early so the read side never underflows (stale output). 'full' is kept
    // as a hard backstop. See parked discussion.
    wire uneven_wr_en = rdec_valid & ~uneven_almost_full & ~uneven_full & ~uneven_wr_rst_busy;

    fifo_uneven_1x2_wrapper u_fifo_uneven (
        .rst         (rst_clk80),
        // write side: clk80
        .wr_clk      (clk80),
        .din         (rdec_bit),
        .wr_en       (uneven_wr_en),
        .full        (uneven_full),
        .almost_full (uneven_almost_full),
        // read side: clk200 (uneven/biased consumer domain)
        .rd_clk      (clk200),
        .rd_en       (uneven_rd_en),
        .dout        (uneven_dout),
        .empty       (uneven_empty),
        // status
        .wr_rst_busy (uneven_wr_rst_busy),
        .rd_rst_busy (/* unused */)
    );

    // NOTE(1) [resolved above]: the rng_ready gate holds basis_rangedec in reset
    // (and zeroes the controller's 'take') until the controller has prefetched
    // PRIME_BITS real bits, so the decoder never primes on power-on zero-fill.

    // ---------------------------------------------------------------------
    // E1 -- sticky controller-underrun flag (docs/monitoring.md §2.1).
    // The exact corruption event is the controller's take-clamp: the decoder
    // consumed 'take' bits when only ctrl_level were valid (controller.v:88).
    // Strictly stronger than (ctrl_level == 0): a same-cycle refill word can
    // step bits_level from <take straight to 16, hiding the zero, while the
    // decode still ran on zero-fill. rng_ready is sticky, so nothing upstream
    // stops the decoder -- this flag is the only record that the biased
    // output turned statistically wrong. Cleared by rst_clk80 only (for a
    // W1C register bit, OR a clk80-synchronized clear into the reset term).
    // ---------------------------------------------------------------------
    reg err_ctrl_underrun_r;
    always @(posedge clk80) begin
        if (rst_clk80)
            err_ctrl_underrun_r <= 1'b0;
        else if (rng_ready && ({3'b000, take_to_ctrl} > ctrl_level))
            err_ctrl_underrun_r <= 1'b1;
    end
    assign err_ctrl_underrun = err_ctrl_underrun_r;

    // ---------------------------------------------------------------------
    // debug: ILA on the clk80 datapath (ila_rdec)
    // ---------------------------------------------------------------------
    // Clocked by clk80 -- captures the upstream-FIFO read side, the range-
    // decoder handshake, and the downstream (uneven) output. NOTE: uneven_dout
    // and uneven_empty live in the clk200 read domain; they are sampled here
    // asynchronously (debug-only), so treat those two probes as CDC-unsafe.
    // ila_rdec u_ila_rdec (
    //     .clk    (clk80),
    //     .probe0 (ctrl_fifo_rd_en), // 1b  upstream FIFO read enable
    //     .probe1 (up_dout),         // 16b upstream FIFO data
    //     .probe2 (ctrl_rnd_in),        // 1b  upstream FIFO empty
    //     .probe3 (rdec_take),       // 4b  range-decoder 'take'
    //     .probe4 (rdec_bit),        // 1b  decoded basis bit
    //     .probe5 (rdec_valid),      // 1b  basis bit valid
    //     .probe6 (uneven_dout),     // 2b  uneven output (clk200, async sample)
    //     .probe7 (uneven_wr_en)     // 1b  uneven FIFO empty (clk200, async sample)
    // );

endmodule

`default_nettype wire
