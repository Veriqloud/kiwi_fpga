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
    input           clk80,
    input           rst_clk80,
    input           rst_clk250,
    input [15:0]    rdec_p0_i,
    input           rd_en_16_de,
    input           rd_en_4,
    output [1:0]    de_rng_dout2,
    output [3:0]    de_rng_flags
);

wire [15:0] dout16;
wire de_almost_full_16;
wire de_empty_16;
wire de_almost_full_2;
wire de_empty_2;

// ---- CDC: sync the cross-domain flags into clk200 (the consumer/tx_core_clk
// domain in which de_rng_flags is sampled). de_almost_full_16 is in s_axis_clk
// (250 MHz, FIFO write side); de_empty_16 and de_almost_full_2 are in clk80
// (80 MHz). de_empty_2 is already in clk200 and is used directly.
// (de_almost_full_16 is still used raw below in its native s_axis_clk domain.)
wire de_almost_full_16_sync;
wire de_empty_16_sync;
wire de_almost_full_2_sync;

cdc_sync_single #(.STAGES(2)) u_sync_de_af16 (
    .clk_i (clk200), .d_i (de_almost_full_16), .q_o (de_almost_full_16_sync));
cdc_sync_single #(.STAGES(2)) u_sync_de_e16 (
    .clk_i (clk200), .d_i (de_empty_16),       .q_o (de_empty_16_sync));
cdc_sync_single #(.STAGES(2)) u_sync_de_af2 (
    .clk_i (clk200), .d_i (de_almost_full_2),  .q_o (de_almost_full_2_sync));

wire [3:0] de_rng_flags;
assign de_rng_flags = {de_almost_full_16_sync, de_empty_16_sync, de_almost_full_2_sync, de_empty_2};
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
//fifo_decoy_rng_128x16 fifo_decoy_rng_16_inst (
//    .rst(rng_reset),                  // input wire rst
//    .wr_clk(s_axis_clk),            // input wire wr_clk
//    .rd_clk(clk200),            // input wire rd_clk
//    .din(s_axis_tdata),                  // input wire [127 : 0] din
//    .wr_en(s_axis_tvalid && s_axis_tready),              // input wire wr_en
//    .rd_en(rd_en_16_de),              // input wire rd_en
//    .dout(dout16),                // output wire [15 : 0] dout
//    .full(),                // output wire full
//    .almost_full(de_almost_full_16),       // output wire almost_full
//    .empty(de_empty),              // output wire empty
//    .wr_rst_busy(),  // output wire wr_rst_busy
//    .rd_rst_busy()  // output wire rd_rst_busy
//);

//wire wr_ack;
//wire valid;

//fifo_decoy_rng_16x2 fifo_decoy_rng_2_inst (
//  .rst(rng_reset),                  // input wire rst
//  .wr_clk(clk200),            // input wire wr_clk
//  .rd_clk(clk200),            // input wire rd_clk
//  .din(dout16),                  // input wire [15 : 0] din
//  .wr_en(rd_en_16_de),              // input wire wr_en
//  .rd_en(rd_en_4),              // input wire rd_en
//  .dout(de_rng_dout2),                // output wire [1 : 0] dout
//  .full(),                // output wire full
//  .wr_ack(wr_ack),            // output wire wr_ack
//  .empty(),              // output wire empty
//  .valid(valid),              // output wire valid
//  .wr_rst_busy(),  // output wire wr_rst_busy
//  .rd_rst_busy()  // output wire rd_rst_busy
//);

rangedec_top_wrapper #(
    .PREC (15)
) u_rangedec_top_wrapper (
    .rst_clk80    (rst_clk80),
    .rst_clk250   (rst_clk250),
    .wr_clk      (s_axis_clk),
    .ent_din     (s_axis_tdata),
    .ent_wr_en   (s_axis_tvalid && s_axis_tready),
    .ent_full    (),
    .ent_almost_full(de_almost_full_16),
    .up_empty    (de_empty_16),

    .clk80       (clk80),  
    .rdec_p0_i   (rdec_p0_i),   
    .clk200      (clk200),
    .uneven_rd_en(rd_en_4),
    .uneven_dout (de_rng_dout2),
    .uneven_empty(de_empty_2),
    .uneven_almost_full(de_almost_full_2)
);

endmodule
