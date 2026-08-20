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
// Revision 0.02 - No change
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module fifo_uneven_1x2_wrapper (
    // ---- async, active high ----
    input  wire        rst,       

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
