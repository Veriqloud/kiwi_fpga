`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 02:56:19 PM
// Design Name: Qline_turnkey
// Module Name: decoy_rng_fifos
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
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
    input  wire [127:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,

    input           clk200,
    input           tx_core_rst,
    input           rng_reset,
    input           rd_en_16_de,
    input           rd_en_4,
    output [1:0]    de_rng_dout2,
    output [1:0]    de_rng_flags,
    output          valid
);

wire [15:0] dout16;
wire de_almost_full_16;
wire de_empty;
wire [1:0] de_rng_flags;
assign de_rng_flags = {de_almost_full_16,de_empty};
assign s_axis_tready = tready_flag;
reg tready_flag;
initial begin
    tready_flag <= 1;
end
always @(posedge s_axis_clk) begin
    if (de_almost_full_16) begin
        tready_flag <= 0;
    end else begin
        tready_flag <= 1;
    end

end
fifo_decoy_rng_128x16 fifo_decoy_rng_16_inst (
    .rst(rng_reset),                  // input wire rst
    .wr_clk(s_axis_clk),            // input wire wr_clk
    .rd_clk(clk200),            // input wire rd_clk
    .din(s_axis_tdata),                  // input wire [127 : 0] din
    .wr_en(s_axis_tvalid && s_axis_tready),              // input wire wr_en
    .rd_en(rd_en_16_de),              // input wire rd_en
    .dout(dout16),                // output wire [15 : 0] dout
    .full(),                // output wire full
    .almost_full(de_almost_full_16),       // output wire almost_full
    .empty(de_empty),              // output wire empty
    .wr_rst_busy(),  // output wire wr_rst_busy
    .rd_rst_busy()  // output wire rd_rst_busy
);

// fifo in independant clock domains
wire wr_ack;
wire valid;
// fifo_decoy_rng_16x4 fifo_decoy_rng_4_inst (
// //   .rst(tx_core_rst),                  // input wire rst
//   .rst(rng_reset),                  // input wire rst
//   .wr_clk(clk200),            // input wire wr_clk
//   .rd_clk(clk200),            // input wire rd_clk
//   .din(dout16),                  // input wire [15 : 0] din
//   .wr_en(rd_en_16),              // input wire wr_en
//   .rd_en(rd_en_4),              // input wire rd_en
//   .dout(de_rng_dout4),                // output wire [1 : 0] dout
//   .wr_ack(wr_ack),          // output wire [3 : 0] wr_ack
//   .valid(valid),            // output wire valid
//   .full(),                // output wire full
//   .empty(),              // output wire empty
//   .wr_rst_busy(),  // output wire wr_rst_busy
//   .rd_rst_busy()  // output wire rd_rst_busy
// );

fifo_decoy_rng_16x2 fifo_decoy_rng_2_inst (
  .rst(rng_reset),                  // input wire rst
  .wr_clk(clk200),            // input wire wr_clk
  .rd_clk(clk200),            // input wire rd_clk
  .din(dout16),                  // input wire [15 : 0] din
  .wr_en(rd_en_16_de),              // input wire wr_en
  .rd_en(rd_en_4),              // input wire rd_en
  .dout(de_rng_dout2),                // output wire [1 : 0] dout
  .full(),                // output wire full
  .wr_ack(wr_ack),            // output wire wr_ack
  .empty(),              // output wire empty
  .valid(valid),              // output wire valid
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);
endmodule
