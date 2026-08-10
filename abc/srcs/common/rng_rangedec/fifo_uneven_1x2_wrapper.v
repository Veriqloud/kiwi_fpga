// ============================================================================
// fifo_uneven_1x2_wrapper.v
//
// Thin wrapper around the "fifo_1x2" FIFO Generator IP
// (see ip/fifo_1x2/fifo_1x2.xci).
//
//   Async (independent clocks) block-RAM FIFO, asymmetric / Standard FIFO:
//     write side : 1-bit din @ wr_clk (e.g. basis_bit @ 80 MHz), depth 1024
//     read  side : 2-bit dout @ rd_clk (uneven/biased bits @ 200 MHz domain),
//                  depth 512
//
// Read semantics: this IP is a *Standard* FIFO (NOT First-Word-Fall-Through).
// 'dout' becomes valid one rd_clk cycle *after* rd_en is asserted on a
// non-empty FIFO.
//
// Usage notes for the entropy -> uneven-bit bridge:
//   - Gate writes: wr_en should be (basis_valid & ~almost_full); basis_bit is
//     only meaningful while basis_valid is high. Gating on almost_full (rather
//     than full) leaves write headroom so surplus bits are dropped early and the
//     FIFO never reaches full. 'full' remains available as a hard backstop.
//   - Gate reads:  only assert rd_en while ~empty; reading empty returns stale
//     data (repeated bits), which is bad for the RNG.
//
// 'rst' is asynchronous, active high (FIFO Generator async reset).
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: Qline_turnkey
// Module Name: fifo_uneven_1x2_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Thin wrapper around the fifo_1x2 FIFO Generator IP. Async
//              (independent clocks) block-RAM Standard FIFO, asymmetric 1-bit
//              write / 2-bit read; bridges basis_bit (80 MHz) to the uneven
//              (biased) bit stream (200 MHz domain).
//
// Dependencies: ip/fifo_1x2/fifo_1x2.xci
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module fifo_uneven_1x2_wrapper (
    input  wire        rst,       // async, active high

    // ---- write side (entropy / basis_rangedec domain) ----
    input  wire        wr_clk,
    input  wire        din,       // 1-bit (e.g. basis_bit)
    input  wire        wr_en,
    output wire        full,
    output wire        almost_full,

    // ---- read side (uneven/biased consumer domain) ----
    input  wire        rd_clk,
    input  wire        rd_en,
    output wire [1:0]  dout,      // 2-bit (2 biased bits/read)
    output wire        empty,

    // ---- status ----
    output wire        wr_rst_busy,
    output wire        rd_rst_busy
);

    fifo_1x2 u_fifo_1x2 (
        .rst         (rst),
        .wr_clk      (wr_clk),
        .rd_clk      (rd_clk),
        .din         (din),
        .wr_en       (wr_en),
        .full        (full),
        .almost_full (almost_full),
        .rd_en       (rd_en),
        .dout        (dout),
        .empty       (empty),
        .wr_rst_busy (wr_rst_busy),
        .rd_rst_busy (rd_rst_busy)
    );

endmodule

`default_nettype wire
