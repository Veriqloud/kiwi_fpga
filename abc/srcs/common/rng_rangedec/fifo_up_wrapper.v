// ============================================================================
// fifo_up_wrapper.v
//
// Thin wrapper around the "fifo_128x16" FIFO Generator IP
// (see ip/fifo_128x16/fifo_128x16.xci).
//
//   Async (independent clocks) block-RAM FIFO, asymmetric / Standard FIFO:
//     write side : 128-bit din @ wr_clk, depth 4096
//     read  side :  16-bit dout @ rd_clk, depth 32768 -> drives controller.v
//
// NOTE on read semantics: this IP is configured as a *Standard* FIFO
// (Performance_Options = Standard_FIFO), NOT First-Word-Fall-Through.
// 'dout' is therefore valid one rd_clk cycle *after* rd_en is asserted on a
// non-empty FIFO, rather than being continuously presented while ~empty.
// If the consumer (controller.v) expects FWFT, either regenerate the IP with
// First_Word_Fall_Through or adapt the read handshake accordingly.
//
// 'rst' is asynchronous, active high (FIFO Generator async reset).
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: rng_test
// Module Name: fifo_up_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Thin wrapper around the fifo_128x16 FIFO Generator IP.
//              Async (independent clocks) block-RAM Standard FIFO, asymmetric
//              128-bit write / 16-bit read; bridges entropy producer to the
//              controller read domain.
//
// Dependencies: ip/fifo_128x16/fifo_128x16.xci
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module fifo_up_wrapper (
    input  wire         rst,       // async, active high

    // ---- write side (entropy producer domain) ----
    input  wire         wr_clk,
    input  wire [127:0] din,
    input  wire         wr_en,
    output wire         full,
    output wire         almost_full,

    // ---- read side (controller domain) ----
    input  wire         rd_clk,
    input  wire         rd_en,
    output wire [15:0]  dout,
    output wire         empty,

    // ---- status ----
    output wire         wr_rst_busy,
    output wire         rd_rst_busy
);

    fifo_128x16 u_fifo_128x16 (
        .rst           (rst),
        .wr_clk        (wr_clk),
        .rd_clk        (rd_clk),
        .din           (din),
        .wr_en         (wr_en),
        .rd_en         (rd_en),
        .dout          (dout),
        .full          (full),
        .almost_full   (almost_full),
        .empty         (empty),
        .wr_rst_busy   (wr_rst_busy),
        .rd_rst_busy   (rd_rst_busy)
    );

endmodule

`default_nettype wire
