`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/30/2026
// Design Name: rng_test
// Module Name: fifo_4x4_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description:
//
// Dependencies: ips/fifo_4x4/fifo_4x4.xci
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module fifo_4x4_wrapper (
    input  wire       clk,
    input  wire       srst,
    input  wire [3:0] din,
    input  wire       wr_en,
    input  wire       rd_en,
    output wire [3:0] dout,
    output wire       full,
    output wire       empty,
    output wire       wr_rst_busy,
    output wire       rd_rst_busy
);

    fifo_4x4 u_fifo_4x4 (
        .clk         (clk),
        .srst        (srst),
        .din         (din),
        .wr_en       (wr_en),
        .rd_en       (rd_en),
        .dout        (dout),
        .full        (full),
        .empty       (empty),
        .wr_rst_busy (wr_rst_busy),
        .rd_rst_busy (rd_rst_busy)
    );

endmodule

`default_nettype wire
