`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/30/2026
// Design Name: Qline_turnkey
// Module Name: fifo_up_true_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Thin wrapper around the fifo_128x16 FIFO Generator IP. Async
//              (independent clocks) block-RAM Standard FIFO, asymmetric 128-bit
//              write / 16-bit read. Shared "fifo1" used by both the basis-entropy
//              (fifo1_up) and even (fifo1_true) split branches; exposes full
//              flag/data-count set for the source word demux/arbiter.
//
// Dependencies: ip/fifo_128x16/fifo_128x16.xci
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module fifo_up_true_wrapper (
    input  wire         rst,           // async, active high

    // ---- write side (entropy producer domain) ----
    input  wire         wr_clk,
    input  wire [127:0] din,
    input  wire         wr_en,
    output wire         full,
    output wire         almost_full,
    output wire [11:0]  wr_data_count,

    // ---- read side (consumer domain: clk80 for _up, clk200 for _true) ----
    input  wire         rd_clk,
    input  wire         rd_en,
    output wire [15:0]  dout,
    output wire         empty,
    output wire [14:0]  rd_data_count,

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
        .wr_data_count (wr_data_count),
        .rd_data_count (rd_data_count),
        .wr_rst_busy   (wr_rst_busy),
        .rd_rst_busy   (rd_rst_busy)
    );

endmodule

`default_nettype wire
