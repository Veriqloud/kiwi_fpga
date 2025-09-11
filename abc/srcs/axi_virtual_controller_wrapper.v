`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 08/22/2024 04:20:03 PM
// Design Name: Qline_turnkey
// Module Name: axi_virtual_controller_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Instantiate axi virtual fifo controller
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_virtual_controller_wrapper(
    input   wire            aclk,
    input   wire            aresetn,
    //AXIStream,
    input   wire            s_axis_tvalid,
    output  wire            s_axis_tready,
    input   wire [255 : 0]  s_axis_tdata,
    input   wire [31 : 0]   s_axis_tstrb,
    input   wire [31 : 0]   s_axis_tkeep,
    input   wire            s_axis_tlast,
    input   wire [0 : 0]    s_axis_tid,
    input   wire [0 : 0]    s_axis_tdest,
    output  wire            m_axis_tvalid,
    input   wire            m_axis_tready,
    output  wire [255 : 0]  m_axis_tdata,
    output  wire [31 : 0]   m_axis_tstrb,
    output  wire [31 : 0]   m_axis_tkeep,
    output  wire            m_axis_tlast,
    output  wire [0 : 0]    m_axis_tid,
    output  wire [0 : 0]    m_axis_tdest,
    //M_AXI,
    output  wire [0 : 0]    m_axi_awid,
    output  wire [31 : 0]   m_axi_awaddr,
    output  wire [7 : 0]    m_axi_awlen,
    output  wire [2 : 0]    m_axi_awsize,
    output  wire [1 : 0]    m_axi_awburst,
    output  wire [0 : 0]    m_axi_awlock,
    output  wire [3 : 0]    m_axi_awcache,
    output  wire [2 : 0]    m_axi_awprot,
    output  wire [3 : 0]    m_axi_awqos,
    output  wire [3 : 0]    m_axi_awregion,
    output  wire [0 : 0]    m_axi_awuser,
    output  wire            m_axi_awvalid,
    input   wire            m_axi_awready,
    output  wire [255 : 0]  m_axi_wdata,
    output  wire [31 : 0]   m_axi_wstrb,
    output  wire            m_axi_wlast,
    output  wire [0 : 0]    m_axi_wuser,
    output  wire            m_axi_wvalid,
    input   wire            m_axi_wready,
    input   wire [0 : 0]    m_axi_bid,
    input   wire [1 : 0]    m_axi_bresp,
    input   wire [0 : 0]    m_axi_buser,
    input   wire            m_axi_bvalid,
    output  wire            m_axi_bready,
    output  wire [0 : 0]    m_axi_arid,
    output  wire [31 : 0]   m_axi_araddr,
    output  wire [7 : 0]    m_axi_arlen,
    output  wire [2 : 0]    m_axi_arsize,
    output  wire [1 : 0]    m_axi_arburst,
    output  wire [0 : 0]    m_axi_arlock,
    output  wire [3 : 0]    m_axi_arcache,
    output  wire [2 : 0]    m_axi_arprot,
    output  wire [3 : 0]    m_axi_arqos,
    output  wire [3 : 0]    m_axi_arregion,
    output  wire [0 : 0]    m_axi_aruser,
    output  wire            m_axi_arvalid,
    input   wire            m_axi_arready,
    input   wire [0 : 0]    m_axi_rid,
    input   wire [255 : 0]  m_axi_rdata,
    input   wire [1 : 0]    m_axi_rresp,
    input   wire            m_axi_rlast,
    input   wire [0 : 0]    m_axi_ruser,
    input   wire            m_axi_rvalid,
    output  wire            m_axi_rready,
    input   wire [1 : 0]    vfifo_mm2s_channel_full,
    output  wire [1 : 0]    vfifo_s2mm_channel_full,
    output  wire [1 : 0]    vfifo_mm2s_channel_empty,
    output  wire [1 : 0]    vfifo_idle,

    //Monitoring custom ports
    output [47:0] counter_read,
    output [47:0] counter_write,
    output [47:0] delta_count

);

reg [47:0] counter_read;
reg [47:0] counter_write;
wire [47:0] delta_count;
assign delta_count = counter_write - counter_read;

always @(posedge aclk) begin
    if (!aresetn) begin
        counter_read <= 0;
        counter_write <= 0;
    end else begin
        if ((m_axi_rready == 1'b1) && (m_axi_rvalid == 1'b1)) begin
            counter_read <= counter_read + 1;
        end else counter_read <= counter_read;
        if ((m_axi_wvalid == 1'b1) && (m_axi_wready == 1'b1)) begin
            counter_write <= counter_write + 1;
        end else counter_write <= counter_write;
    end
end

axi_vfifo_ctrl_0 axi_virtual_controller_ddr4_inst (
    .aclk(aclk),                                          // input wire aclk
    .aresetn(aresetn),                                    // input wire aresetn
    .s_axis_tvalid(s_axis_tvalid),                        // input wire s_axis_tvalid
    .s_axis_tready(s_axis_tready),                        // output wire s_axis_tready
    .s_axis_tdata(s_axis_tdata),                          // input wire [255 : 0] s_axis_tdata
    .s_axis_tstrb(s_axis_tstrb),                          // input wire [31 : 0] s_axis_tstrb
    .s_axis_tkeep(s_axis_tkeep),                          // input wire [31 : 0] s_axis_tkeep
    .s_axis_tlast(s_axis_tlast),                          // input wire s_axis_tlast
    .s_axis_tid(s_axis_tid),                              // input wire [0 : 0] s_axis_tid
    .s_axis_tdest(s_axis_tdest),                          // input wire [0 : 0] s_axis_tdest
    .m_axis_tvalid(m_axis_tvalid),                        // output wire m_axis_tvalid
    .m_axis_tready(m_axis_tready),                        // input wire m_axis_tready
    .m_axis_tdata(m_axis_tdata),                          // output wire [255 : 0] m_axis_tdata
    .m_axis_tstrb(m_axis_tstrb),                          // output wire [31 : 0] m_axis_tstrb
    .m_axis_tkeep(m_axis_tkeep),                          // output wire [31 : 0] m_axis_tkeep
    .m_axis_tlast(m_axis_tlast),                          // output wire m_axis_tlast
    .m_axis_tid(m_axis_tid),                              // output wire [0 : 0] m_axis_tid
    .m_axis_tdest(m_axis_tdest),                          // output wire [0 : 0] m_axis_tdest
    .m_axi_awid(m_axi_awid),                              // output wire [0 : 0] m_axi_awid
    .m_axi_awaddr(m_axi_awaddr),                          // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m_axi_awlen),                            // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m_axi_awsize),                          // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m_axi_awburst),                        // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m_axi_awlock),                          // output wire [0 : 0] m_axi_awlock
    .m_axi_awcache(m_axi_awcache),                        // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m_axi_awprot),                          // output wire [2 : 0] m_axi_awprot
    .m_axi_awqos(m_axi_awqos),                            // output wire [3 : 0] m_axi_awqos
    .m_axi_awregion(m_axi_awregion),                      // output wire [3 : 0] m_axi_awregion
    .m_axi_awuser(m_axi_awuser),                          // output wire [0 : 0] m_axi_awuser
    .m_axi_awvalid(m_axi_awvalid),                        // output wire m_axi_awvalid
    .m_axi_awready(m_axi_awready),                        // input wire m_axi_awready
    .m_axi_wdata(m_axi_wdata),                            // output wire [255 : 0] m_axi_wdata
    .m_axi_wstrb(m_axi_wstrb),                            // output wire [31 : 0] m_axi_wstrb
    .m_axi_wlast(m_axi_wlast),                            // output wire m_axi_wlast
    .m_axi_wuser(m_axi_wuser),                            // output wire [0 : 0] m_axi_wuser
    .m_axi_wvalid(m_axi_wvalid),                          // output wire m_axi_wvalid
    .m_axi_wready(m_axi_wready),                          // input wire m_axi_wready
    .m_axi_bid(m_axi_bid),                                // input wire [0 : 0] m_axi_bid
    .m_axi_bresp(m_axi_bresp),                            // input wire [1 : 0] m_axi_bresp
    .m_axi_buser(m_axi_buser),                            // input wire [0 : 0] m_axi_buser
    .m_axi_bvalid(m_axi_bvalid),                          // input wire m_axi_bvalid
    .m_axi_bready(m_axi_bready),                          // output wire m_axi_bready
    .m_axi_arid(m_axi_arid),                              // output wire [0 : 0] m_axi_arid
    .m_axi_araddr(m_axi_araddr),                          // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m_axi_arlen),                            // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m_axi_arsize),                          // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m_axi_arburst),                        // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m_axi_arlock),                          // output wire [0 : 0] m_axi_arlock
    .m_axi_arcache(m_axi_arcache),                        // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m_axi_arprot),                          // output wire [2 : 0] m_axi_arprot
    .m_axi_arqos(m_axi_arqos),                            // output wire [3 : 0] m_axi_arqos
    .m_axi_arregion(m_axi_arregion),                      // output wire [3 : 0] m_axi_arregion
    .m_axi_aruser(m_axi_aruser),                          // output wire [0 : 0] m_axi_aruser
    .m_axi_arvalid(m_axi_arvalid),                        // output wire m_axi_arvalid
    .m_axi_arready(m_axi_arready),                        // input wire m_axi_arready
    .m_axi_rid(m_axi_rid),                                // input wire [0 : 0] m_axi_rid
    .m_axi_rdata(m_axi_rdata),                            // input wire [255 : 0] m_axi_rdata
    .m_axi_rresp(m_axi_rresp),                            // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m_axi_rlast),                            // input wire m_axi_rlast
    .m_axi_ruser(m_axi_ruser),                            // input wire [0 : 0] m_axi_ruser
    .m_axi_rvalid(m_axi_rvalid),                          // input wire m_axi_rvalid
    .m_axi_rready(m_axi_rready),                          // output wire m_axi_rready
    .vfifo_mm2s_channel_full(vfifo_mm2s_channel_full),    // input wire [1 : 0] vfifo_mm2s_channel_full
    .vfifo_s2mm_channel_full(vfifo_s2mm_channel_full),    // output wire [1 : 0] vfifo_s2mm_channel_full
    .vfifo_mm2s_channel_empty(vfifo_mm2s_channel_empty),  // output wire [1 : 0] vfifo_mm2s_channel_empty
    .vfifo_idle(vfifo_idle)                              // output wire [1 : 0] vfifo_idle
);

endmodule
