`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 07/16/2026
// Design Name: Qline_turnkey
// Module Name: rng_monitor
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: CDC + W1C sticky register layer for the RNG datapath error
//              flags; register-domain side interfaces to fastdac_axil_mngt.
//
// Dependencies: cdc_sync_single.v
// Revision: 0.02 - Add some comments for AI review
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
// ============================================================================
// rng_monitor.v
//
// RNG-datapath error monitor: collects the sticky error flags of the RNG
// datapath (angles_top_wrapper / rangedec_top_wrapper, docs/monitoring.md §2),
// crosses them into ONE register clock domain, and adds a W1C sticky layer
// ready to be wired to AXIL registers (fastdac_axil_mngt).
//
// Flag inputs (bit order matches the health register in monitoring.md §6):
//   err_i[0]  E1 err_ctrl_underrun     clk80   decoder ran on missing entropy
//   err_i[1]  E2 err_uneven_gate       clk200  fifo_1x2 read-while-empty (never-event)
//   err_i[2]  E3 err_endpoint_ovread   clk200  rd_en_4 on a not-ready tick
//   err_i[3]  decoy-path E1            clk80   de_err_ctrl_underrun from decoy_rng_fifos
//             (was E4 err_ent_stall; watchdog removed 2026-07-17)
//
// CDC: each input is a 1-bit STICKY flag, latched in its native domain and
// cleared only by that domain's reset -- quasi-static, so an independent
// 2-FF synchronizer per bit is sufficient (no gray coding, no handshake).
// The bits are NOT mutually coherent for the 1-2 cycles around a latch event;
// each bit is an independent observation, which is all a status register needs.
//
// Two views are exposed, both in the clk_i domain:
//   err_raw_o    -- synchronized upstream level. Set = "has fired since the
//                   datapath domain reset". Clears ONLY when the datapath
//                   domain is reset (the upstream latch releases).
//   err_sticky_o -- W1C layer: set on the RISING EDGE of err_raw_o, cleared
//                   per-bit by err_clr_i. Set = "has fired since last clear".
//                   Set dominates clear, so an event coinciding with a clear
//                   is never lost. After a clear it re-arms only on a new
//                   upstream latch (i.e. after a datapath reset + new event);
//                   read err_raw_o to see the upstream latch state itself.
//
// AXIL hookup (later, in fastdac_axil_mngt): map err_sticky_o (and optionally
// err_raw_o) into a read register; drive err_clr_i from the write strobe of
// the same address ANDed with wdata (classic W1C). Both sides are then in
// s_axil_aclk -- no further CDC in the register block.
//
// rst_i vs. the datapath resets -- NOT the same signal (checked against
// clk_rst_mngt.v / jesd_transport.v 2026-08-18): rst_i = ~s_axil_aresetn,
// sourced from sys_reset_n and asserted only at boot. The datapath-domain
// resets that actually clear err_i upstream (rng_rst_clk80/200/250) come
// from a separate, software-writable register bit (rng_rst) and can pulse
// at any time thereafter, independent of rst_i.
// INVARIANT this relies on: rst_i must not re-assert while the datapath is
// live. err_raw_o has no reset (by design, line ~44 above) and err_raw_d is
// zeroed unconditionally by rst_i below; if rst_i ever pulsed again after an
// err_i bit had already latched (err_raw_o=1), the edge detector would see
// a false 0->1 transition on err_raw_d catching up and spuriously re-set
// err_sticky_o for an event that isn't new. Safe today only because rst_i is
// boot-only, i.e. always fires before any err_i could possibly be set.
// If that ever changes (e.g. a driver-level "soft reset without power
// cycle"), revisit: either reset err_raw_d to err_raw_o's value instead of
// 0, or gate err_set for one cycle after rst_i deasserts.
// ============================================================================

`default_nettype none

module rng_monitor #(
    parameter integer N_ERR  = 4,       // number of independent error flags
    parameter integer STAGES = 2        // synchronizer depth (>= 2)
)(
    // register clock domain (e.g. s_axil_aclk)
    input  wire             clk_i,
    input  wire             rst_i,          // active-high, synchronous to clk_i

    // sticky error flags from the datapath, each in its own native domain
    input  wire [N_ERR-1:0] err_i,

    // AXIL register-side interface (clk_i domain)
    input  wire [N_ERR-1:0] err_clr_i,      // W1C: 1-cycle strobe per bit
    output wire [N_ERR-1:0] err_raw_o,      // synced upstream level (see header)
    output reg  [N_ERR-1:0] err_sticky_o    // W1C sticky since last clear
);

    // ---- per-bit 2-FF synchronizers (independent quasi-static bits) ----
    genvar g;
    generate
        for (g = 0; g < N_ERR; g = g + 1) begin : g_sync
            cdc_sync_single #(.STAGES(STAGES)) u_sync (
                .clk_i (clk_i),
                .d_i   (err_i[g]),
                .q_o   (err_raw_o[g])
            );
        end
    endgenerate

    // ---- W1C sticky layer, set on rising edge of the synced level ----
    reg  [N_ERR-1:0] err_raw_d;
    wire [N_ERR-1:0] err_set = err_raw_o & ~err_raw_d;   // new upstream latch

    always @(posedge clk_i) begin
        if (rst_i) begin
            // relies on rst_i being boot-only (see header) -- zeroing
            // err_raw_d here while err_raw_o is un-reset is only safe
            // because nothing upstream can have latched yet.
            err_raw_d    <= {N_ERR{1'b0}};
            err_sticky_o <= {N_ERR{1'b0}};
        end else begin
            err_raw_d    <= err_raw_o;
            // set dominates clear: an event coinciding with W1C is not lost
            err_sticky_o <= (err_sticky_o & ~err_clr_i) | err_set;
        end
    end

endmodule

`default_nettype wire
