//Description :
//- Instantiate AXIS FIFO to prevent the tool reset ACLK domain when building project from tcl
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
