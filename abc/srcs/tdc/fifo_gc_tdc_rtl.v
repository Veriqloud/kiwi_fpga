`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date:
// Design Name: Qline_turnkey
// Module Name: fifo_gc_tdc_rtl
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: RTL wrapper around the fifo_gc_tdc AXI4-Stream FIFO IP.
//   The wrapper exists so the block design
//   instantiates the FIFO as a module reference, which stops the tool from
//   resetting the ACLK domain when the project is rebuilt from tcl.
//
// Dependencies: fifo_gc_tdc (AXI4-Stream Data FIFO IP,
//   ip/fifo_gc_tdc/fifo_gc_tdc.xci)
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Add some comments for AI review. No functional change.
// Additional Comments:
//   Stream - 128-bit TDATA plus 4-bit TUSER, depth 1024. TKEEP, TLAST and
//   TSTRB are all disabled in the IP, so the link carries fixed-size beats
//   with no packet framing.
//
//   Clocks - this is an asynchronous FIFO, the two sides run on unrelated
//   clocks:
//     s_aclk <- clk200, the tdc_core capture domain
//     m_aclk <- m_axi_tclk, the DMA/DDR side
//
//   s_aresetn is driven by tdc_core's fifo_calib_rst. Despite the _rst name
//   that signal is ACTIVE LOW as used here: tdc_core holds it at 0 while the
//   TDC is idle, which keeps this FIFO flushed, and drives it to 1 only once
//   a capture command is active. Do not "fix" the polarity, the wiring is
//   deliberate and the name is the misleading part.
//
//////////////////////////////////////////////////////////////////////////////////

module fifo_gc_tdc_rtl(
    input wire m_aclk,
    input wire s_aclk,
    input wire s_aresetn,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [127 : 0] s_axis_tdata,
    input wire [3 : 0] s_axis_tuser,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [127 : 0] m_axis_tdata,
    output wire [3 : 0] m_axis_tuser
    );
fifo_gc_tdc fifo_gc_tdc_inst (
  .m_aclk(m_aclk),                // input wire m_aclk
  .s_aclk(s_aclk),                // input wire s_aclk
  .s_aresetn(s_aresetn),          // input wire s_aresetn
  .s_axis_tvalid(s_axis_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata),    // input wire [127 : 0] s_axis_tdata
  .s_axis_tuser(s_axis_tuser),    // input wire [3 : 0] s_axis_tuser
  .m_axis_tvalid(m_axis_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),    // output wire [127 : 0] m_axis_tdata
  .m_axis_tuser(m_axis_tuser)    // output wire [3 : 0] m_axis_tuser
);

endmodule
