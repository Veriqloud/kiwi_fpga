`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 02:56:19 PM
// Design Name: 
// Module Name: decoy_rng_fifos
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decoy_rng_fifos(
    input               s_axis_clk,
    input               s_axis_tresetn,
    input wire [127:0]  s_axis_tdata,
    input wire          s_axis_tvalid,
    output wire          s_axis_tready,

    input clk200,
    input tx_core_rst,
    input rd_en_16,
    input rd_en_4,
    output [3:0] de_rng_dout4

    );

    assign s_axis_tready = 1'b1;
    wire [15:0] dout16;

    fifo_decoy_rng_128x16 fifo_decoy_rng_16_inst (
        .rst(!s_axis_tresetn),                  // input wire rst
        .wr_clk(s_axis_clk),            // input wire wr_clk
        .rd_clk(clk200),            // input wire rd_clk
        .din(s_axis_tdata),                  // input wire [127 : 0] din
        .wr_en(s_axis_tvalid),              // input wire wr_en
        .rd_en(rd_en_16),              // input wire rd_en
        .dout(dout16),                // output wire [15 : 0] dout
        .full(),                // output wire full
        .empty(),              // output wire empty
        .wr_rst_busy(),  // output wire wr_rst_busy
        .rd_rst_busy()  // output wire rd_rst_busy
    );
    fifo_decoy_rng_16x4 fifo_decoy_rng_4_inst (
        .clk(clk200),                  // input wire clk
        .srst(tx_core_rst),                // input wire srst
        .din(dout16),                  // input wire [15 : 0] din
        .wr_en(rd_en_16),              // input wire wr_en
        .rd_en(rd_en_4),              // input wire rd_en
        .dout(de_rng_dout4),                // output wire [1 : 0] dout
        .full(),                // output wire full
        .empty(),              // output wire empty
        .wr_rst_busy(),  // output wire wr_rst_busy
        .rd_rst_busy()  // output wire rd_rst_busy
    );
endmodule
