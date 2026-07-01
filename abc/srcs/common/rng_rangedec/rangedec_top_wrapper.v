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
// 'rst' (active-high, synchronous to clk200) feeds the FIFOs' async-reset
// inputs directly. For the clk80 logic (controller, basis_rangedec, rng_ready)
// it is re-synchronized into clk80 via reset_register (rst_clk80) so reset
// removal is atomic in that domain -- see the reset synchronization block.
//
// See the in-line NOTEs for the two open design points discussed separately:
//   (1) startup priming of basis_rangedec before the controller buffer fills,
//   (2) write/read rate balance on the uneven FIFO (over-produce + drop on full
//       so it never underflows).
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: rng_test
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
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module rangedec_top_wrapper #(
    parameter        PREC = 15,
    parameter [15:0] P0   = 16'd3277          // P(bit==0) in Q(PREC); 0.1
)(
    input  wire         rst,                  // async active-high (to FIFOs)

    // ---- entropy write interface (producer domain) ----
    input  wire         wr_clk,
    input  wire [127:0] ent_din,
    input  wire         ent_wr_en,
    output wire         ent_full,
    output wire         ent_almost_full,
    output wire         up_empty,

    // ---- processing clock (80 MHz domain) ----
    input  wire         clk80,

    // ---- uneven (biased) read interface (consumer / 200 MHz domain) ----
    input  wire         clk200,
    input  wire         uneven_rd_en,
    output wire [1:0]    uneven_dout,          // 2 biased bits @clk200
    output wire         uneven_empty
);

    // ---------------------------------------------------------------------
    // reset synchronization into the clk80 domain
    // ---------------------------------------------------------------------
    // 'rst' is synchronous to clk200 and drives the FIFOs' async-reset inputs,
    // which the IP re-synchronizes internally -- safe there. But controller and
    // basis_rangedec sample it as a *synchronous* reset in clk80, where its
    // deassertion is asynchronous -> metastability / non-atomic release. Bring
    // it cleanly into clk80: a 2-FF metastability filter feeds reset_register
    // (async assert, clk80-synchronous deassert), matching decoy.v's pattern.
    (* ASYNC_REG = "TRUE" *) reg [2:0] rst80_meta;
    always @(posedge clk80) rst80_meta <= {rst80_meta[1:0], rst};

    wire rst_clk80;   // synchronous active-high reset, clk80 domain
    reset_register #(.RST_ACTIVE_LEVEL("HIGH")) u_rst_clk80 (
        .clk_i  (clk80),
        .rst_i  (rst80_meta[1]),
        .clk_o  (/* unused */),
        .rstn_o (/* unused */),
        .rst_o  (rst_clk80)
    );

    // ---------------------------------------------------------------------
    // upstream FIFO (128b entropy -> 16b words) read in the clk80 domain
    // ---------------------------------------------------------------------
    wire [15:0] up_dout;
    wire        up_empty;
    wire        ctrl_fifo_rd_en;

    fifo_up_wrapper u_fifo_up (
        .rst           (rst),
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
        // status (unused)
        .wr_rst_busy   (/* unused */),
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
        .PREC (PREC),
        .P0   (P0)
    ) u_rdec (
        .clk         (clk80),
        .rst         (rdec_rst),       // held until controller buffer is primed
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

    // Only push real symbols, never while full or during reset recovery.
    // NOTE(2): producer (80 Mb/s) and consumer (2b @ rd_en) are nominally rate-
    // matched; rely on over-production + this ~full mask to drop surplus bits so
    // the read side never underflows (stale output). See parked discussion.
    wire uneven_wr_en = rdec_valid & ~uneven_full & ~uneven_wr_rst_busy;

    fifo_uneven_1x2_wrapper u_fifo_uneven (
        .rst         (rst),
        // write side: clk80
        .wr_clk      (clk80),
        .din         (rdec_bit),
        .wr_en       (uneven_wr_en),
        .full        (uneven_full),
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

endmodule

`default_nettype wire
