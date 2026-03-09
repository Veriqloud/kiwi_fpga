`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2026 12:33:29 PM
// Design Name: 
// Module Name: axis_burst
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


module axis_burst(
   input wire s_aclk,
   input wire s_aresetn,
   input wire s_axis_tvalid,
   output wire s_axis_tready,
   input wire [255 : 0] s_axis_tdata,
   input wire s_axis_tlast,
   input wire [3 : 0] s_axis_tuser,
   output wire m_axis_tvalid,
   input wire m_axis_tready,
   output wire [255 : 0] m_axis_tdata,
   output wire m_axis_tlast,
   output wire [3 : 0] m_axis_tuser,
   output wire axis_prog_full,
   output wire axis_prog_empty

);



fifo_burst_formation your_instance_name (
  .s_aclk(s_aclk),                    // input wire s_aclk
  .s_aresetn(s_aresetn),              // input wire s_aresetn
  .s_axis_tvalid(s_axis_tvalid),      // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready),      // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata),        // input wire [255 : 0] s_axis_tdata
  .s_axis_tlast(s_axis_tlast),        // input wire s_axis_tlast
  .s_axis_tuser(s_axis_tuser),        // input wire [3 : 0] s_axis_tuser
  .m_axis_tvalid(m_axis_tvalid),      // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),      // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),        // output wire [255 : 0] m_axis_tdata
  .m_axis_tlast(m_axis_tlast),        // output wire m_axis_tlast
  .m_axis_tuser(m_axis_tuser),        // output wire [3 : 0] m_axis_tuser
  .axis_prog_full(axis_prog_full),    // output wire axis_prog_full
  .axis_prog_empty(axis_prog_empty)  // output wire axis_prog_empty
);

endmodule
