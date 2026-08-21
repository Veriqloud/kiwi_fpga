`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
//
// Create Date: 03/06/2026 12:33:29 PM
// Design Name: Qline_turnkey
// Module Name: axis_burst
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Buffer the 256-bit AXI-Stream coming from ddr_data and release it
//   to the AXI virtual FIFO controller in bursts, so the controller can issue
//   full-length AXI bursts to DDR instead of short scattered ones.
//   Common clock (clk200), depth 256 beats.
//
// Dependencies:
// - ip/fifo_burst_formation/fifo_burst_formation.xci
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Header completed
// Additional Comments:
// - prog_full threshold is 20 beats, chosen against the vfifo burst size of
//   512 bytes = 16 beats of 32 bytes. Move it if C_AXI_BURST_SIZE changes.
// - Known and accepted: tuser is unconnected at both ends, and axis_prog_full /
//   axis_prog_empty have no consumer in the block design.
//////////////////////////////////////////////////////////////////////////////////


module axis_burst(
   input wire aclk,
   input wire aresetn,
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
  .s_aclk(aclk),                    // input wire s_aclk
  .s_aresetn(aresetn),              // input wire s_aresetn
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
