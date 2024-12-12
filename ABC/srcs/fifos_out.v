`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2024 04:00:08 PM
// Design Name: 
// Module Name: fifos_out
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


module fifos_out(
    //Fifo_gc_out
    input wire m_gco_aclk,
    input wire s_gco_aclk,
    input wire s_gco_aresetn,
    input wire s_axis_tvalid_gco,
    output wire s_axis_tready_gco,
    input wire [63 : 0] s_axis_tdata_gco,
    input wire [3 : 0] s_axis_tuser_gco,
    output wire m_axis_tvalid_gco,
    input wire m_axis_tready_gco,
    output wire [63 : 0] m_axis_tdata_gco,
    output wire [3 : 0] m_axis_tuser_gco,
    output wire axis_prog_full_gco,
    output wire axis_prog_empty_gco,

    //Fifo_alpha_out
    input wire m_alpha_aclk,
    input wire s_alpha_aclk,
    input wire s_alpha_aresetn,
    input wire s_axis_tvalid_alpha,
    output wire s_axis_tready_alpha,
    input wire [127 : 0] s_axis_tdata_alpha,
    input wire [3 : 0] s_axis_tuser_alpha,
    output wire m_axis_tvalid_alpha,
    input wire m_axis_tready_alpha,
    output wire [127 : 0] m_axis_tdata_alpha,
    output wire [3 : 0] m_axis_tuser_alpha,
    output wire axis_prog_full_alpha,
    output wire axis_prog_empty_alpha

    );

fifo_alpha_out fifo_alpha_out_inst (
  .m_aclk(m_alpha_aclk),                    // input wire m_aclk
  .s_aclk(s_alpha_aclk),                    // input wire s_aclk
  .s_aresetn(s_alpha_aresetn),              // input wire s_aresetn
  .s_axis_tvalid(s_axis_tvalid_alpha),      // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready_alpha),      // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata_alpha),        // input wire [127 : 0] s_axis_tdata
  .s_axis_tuser(s_axis_tuser_alpha),        // input wire [3 : 0] s_axis_tuser
  .m_axis_tvalid(m_axis_tvalid_alpha),      // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready_alpha),      // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata_alpha),        // output wire [127 : 0] m_axis_tdata
  .m_axis_tuser(m_axis_tuser_alpha),        // output wire [3 : 0] m_axis_tuser
  .axis_prog_full(axis_prog_full_alpha),    // output wire axis_prog_full
  .axis_prog_empty(axis_prog_empty_alpha)  // output wire axis_prog_empty
);

fifo_gc_out fifo_gc_out_inst (
  .m_aclk(m_gco_aclk),                    // input wire m_aclk
  .s_aclk(s_gco_aclk),                    // input wire s_aclk
  .s_aresetn(s_gco_aresetn),              // input wire s_aresetn
  .s_axis_tvalid(s_axis_tvalid_gco),      // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready_gco),      // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata_gco),        // input wire [63 : 0] s_axis_tdata
  .s_axis_tuser(s_axis_tuser_gco),        // input wire [3 : 0] s_axis_tuser
  .m_axis_tvalid(m_axis_tvalid_gco),      // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready_gco),      // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata_gco),        // output wire [63 : 0] m_axis_tdata
  .m_axis_tuser(m_axis_tuser_gco),        // output wire [3 : 0] m_axis_tuser
  .axis_prog_full(axis_prog_full_gco),    // output wire axis_prog_full
  .axis_prog_empty(axis_prog_empty_gco)  // output wire axis_prog_empty
);
endmodule
