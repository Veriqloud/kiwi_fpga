`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/12/2023 05:40:08 PM
// Design Name: 
// Module Name: pm_data
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


module pm_data(
    input wire                                    s_axis_tclk,
    input wire                                    s_axis_tresetn,
    input wire [127 : 0]                          s_axis_tdata,
    input wire                                    s_axis_tvalid,
//      input wire s_axis_tlast,
    output wire                                   s_axis_tready,

    input clk_10,
    // output wire [13:0] rd_data_count,
    // output wire [11:0] wr_data_count,
    output wire [15:0]       rng_dout

    // output wire prog_empty,
    // output wire prog_full,
    // output wire full,
    // output wire empty

    );
assign s_axis_tready = 1'b1;

// fifo_128x16 rng_fifo (
//   .rst(!s_axis_tresetn),                              // input wire rst
//   .wr_clk(s_axis_tclk),                        // input wire wr_clk
//   .rd_clk(clk_10),                        // input wire rd_clk
//   .din(s_axis_tdata),                              // input wire [127 : 0] din
//   .wr_en(1'b1),                          // input wire wr_en
//   .rd_en(1'b1),                          // input wire rd_en
//   .dout(rng_dout),                            // output wire [15 : 0] dout
//   .full(),                            // output wire full
//   .almost_full(),              // output wire almost_full
//   .empty(),                          // output wire empty
//   .almost_empty(),            // output wire almost_empty
//   .rd_data_count(),          // output wire [13 : 0] rd_data_count
//   .wr_data_count(),          // output wire [10 : 0] wr_data_count
//   .wr_rst_busy(),              // output wire wr_rst_busy
//   .rd_rst_busy()              // output wire rd_rst_busy
// );
endmodule
