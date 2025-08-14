`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2024 05:16:08 PM
// Design Name: 
// Module Name: axis_data_fifo_time
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


module axis_data_fifo_time(
    input s_axis_aclk,
    input s_axis_aresetn,

    input [127:0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready,
    // input s_axis_tlast,

    input m_axis_aclk,
    output [127:0] m_axis_tdata,
    output m_axis_tvalid,
    input m_axis_tready
    // output m_axis_tlast

    );

axis_data_fifo_0 fifo_tdc_time (
  .s_axis_aresetn(s_axis_aresetn),  // input wire s_axis_aresetn
  .s_axis_aclk(s_axis_aclk),        // input wire s_axis_aclk
  .s_axis_tvalid(s_axis_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready),    // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata),      // input wire [127 : 0] s_axis_tdata
  // .s_axis_tlast(s_axis_tlast),      // input wire s_axis_tlast
  .m_axis_aclk(m_axis_aclk),        // input wire m_axis_aclk
  .m_axis_tvalid(m_axis_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),    // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata)      // output wire [127 : 0] m_axis_tdata
  // .m_axis_tlast(m_axis_tlast)      // output wire m_axis_tlast
);
endmodule
