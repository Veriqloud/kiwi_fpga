`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 12/12/2024 01:12:44 PM
// Design Name: 
// Module Name: axi_clock_converter_rtl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Instantiate axi clock converter, replace axi interconnect
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_clock_converter_rtl(
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    input wire [0 : 0] s_axi_awid,
    input wire [31 : 0] s_axi_awaddr,
    input wire [7 : 0] s_axi_awlen,
    input wire [2 : 0] s_axi_awsize,
    input wire [1 : 0] s_axi_awburst,
    input wire [0 : 0] s_axi_awlock,
    input wire [3 : 0] s_axi_awcache,
    input wire [2 : 0] s_axi_awprot,
    input wire [3 : 0] s_axi_awregion,
    input wire [3 : 0] s_axi_awqos,
    input wire [0 : 0] s_axi_awuser,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire [255 : 0] s_axi_wdata,
    input wire [31 : 0] s_axi_wstrb,
    input wire s_axi_wlast,
    input wire [0 : 0] s_axi_wuser,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    output wire [0 : 0] s_axi_bid,
    output wire [1 : 0] s_axi_bresp,
    output wire [0 : 0] s_axi_buser,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    input wire [0 : 0] s_axi_arid,
    input wire [31 : 0] s_axi_araddr,
    input wire [7 : 0] s_axi_arlen,
    input wire [2 : 0] s_axi_arsize,
    input wire [1 : 0] s_axi_arburst,
    input wire [0 : 0] s_axi_arlock,
    input wire [3 : 0] s_axi_arcache,
    input wire [2 : 0] s_axi_arprot,
    input wire [3 : 0] s_axi_arregion,
    input wire [3 : 0] s_axi_arqos,
    input wire [0 : 0] s_axi_aruser,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    output wire [0 : 0] s_axi_rid,
    output wire [255 : 0] s_axi_rdata,
    output wire [1 : 0] s_axi_rresp,
    output wire s_axi_rlast,
    output wire [0 : 0] s_axi_ruser,
    output wire s_axi_rvalid,
    input wire s_axi_rready,
    input wire m_axi_aclk,
    input wire m_axi_aresetn,
    output wire [0 : 0] m_axi_awid,
    output wire [31 : 0] m_axi_awaddr,
    output wire [7 : 0] m_axi_awlen,
    output wire [2 : 0] m_axi_awsize,
    output wire [1 : 0] m_axi_awburst,
    output wire [0 : 0] m_axi_awlock,
    output wire [3 : 0] m_axi_awcache,
    output wire [2 : 0] m_axi_awprot,
    output wire [3 : 0] m_axi_awregion,
    output wire [3 : 0] m_axi_awqos,
    output wire [0 : 0] m_axi_awuser,
    output wire m_axi_awvalid,
    input wire m_axi_awready,
    output wire [255 : 0] m_axi_wdata,
    output wire [31 : 0] m_axi_wstrb,
    output wire m_axi_wlast,
    output wire [0 : 0] m_axi_wuser,
    output wire m_axi_wvalid,
    input wire m_axi_wready,
    input wire [0 : 0] m_axi_bid,
    input wire [1 : 0] m_axi_bresp,
    input wire [0 : 0] m_axi_buser,
    input wire m_axi_bvalid,
    output wire m_axi_bready,
    output wire [0 : 0] m_axi_arid,
    output wire [31 : 0] m_axi_araddr,
    output wire [7 : 0] m_axi_arlen,
    output wire [2 : 0] m_axi_arsize,
    output wire [1 : 0] m_axi_arburst,
    output wire [0 : 0] m_axi_arlock,
    output wire [3 : 0] m_axi_arcache,
    output wire [2 : 0] m_axi_arprot,
    output wire [3 : 0] m_axi_arregion,
    output wire [3 : 0] m_axi_arqos,
    output wire [0 : 0] m_axi_aruser,
    output wire m_axi_arvalid,
    input wire m_axi_arready,
    input wire [0 : 0] m_axi_rid,
    input wire [255 : 0] m_axi_rdata,
    input wire [1 : 0] m_axi_rresp,
    input wire m_axi_rlast,
    input wire [0 : 0] m_axi_ruser,
    input wire m_axi_rvalid,
    output wire m_axi_rready
    );

axi_clock_converter_0 axi_clock_converter_inst (
  .s_axi_aclk(s_axi_aclk),          // input wire s_axi_aclk
  .s_axi_aresetn(s_axi_aresetn),    // input wire s_axi_aresetn
  .s_axi_awid(s_axi_awid),          // input wire [0 : 0] s_axi_awid
  .s_axi_awaddr(s_axi_awaddr),      // input wire [31 : 0] s_axi_awaddr
  .s_axi_awlen(s_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(s_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(s_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(s_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(s_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(s_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(s_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(s_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awuser(s_axi_awuser),      // input wire [0 : 0] s_axi_awuser
  .s_axi_awvalid(s_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),    // output wire s_axi_awready
  .s_axi_wdata(s_axi_wdata),        // input wire [255 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),        // input wire [31 : 0] s_axi_wstrb
  .s_axi_wlast(s_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wuser(s_axi_wuser),        // input wire [0 : 0] s_axi_wuser
  .s_axi_wvalid(s_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),      // output wire s_axi_wready
  .s_axi_bid(s_axi_bid),            // output wire [0 : 0] s_axi_bid
  .s_axi_bresp(s_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_buser(s_axi_buser),        // output wire [0 : 0] s_axi_buser
  .s_axi_bvalid(s_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),      // input wire s_axi_bready
  .s_axi_arid(s_axi_arid),          // input wire [0 : 0] s_axi_arid
  .s_axi_araddr(s_axi_araddr),      // input wire [31 : 0] s_axi_araddr
  .s_axi_arlen(s_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(s_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(s_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(s_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(s_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(s_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(s_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(s_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_aruser(s_axi_aruser),      // input wire [0 : 0] s_axi_aruser
  .s_axi_arvalid(s_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),    // output wire s_axi_arready
  .s_axi_rid(s_axi_rid),            // output wire [0 : 0] s_axi_rid
  .s_axi_rdata(s_axi_rdata),        // output wire [255 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(s_axi_rlast),        // output wire s_axi_rlast
  .s_axi_ruser(s_axi_ruser),        // output wire [0 : 0] s_axi_ruser
  .s_axi_rvalid(s_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),      // input wire s_axi_rready
  .m_axi_aclk(m_axi_aclk),          // input wire m_axi_aclk
  .m_axi_aresetn(m_axi_aresetn),    // input wire m_axi_aresetn
  .m_axi_awid(m_axi_awid),          // output wire [0 : 0] m_axi_awid
  .m_axi_awaddr(m_axi_awaddr),      // output wire [31 : 0] m_axi_awaddr
  .m_axi_awlen(m_axi_awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(m_axi_awsize),      // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(m_axi_awburst),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(m_axi_awlock),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(m_axi_awcache),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(m_axi_awprot),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(m_axi_awregion),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(m_axi_awqos),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awuser(m_axi_awuser),      // output wire [0 : 0] m_axi_awuser
  .m_axi_awvalid(m_axi_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(m_axi_awready),    // input wire m_axi_awready
  .m_axi_wdata(m_axi_wdata),        // output wire [255 : 0] m_axi_wdata
  .m_axi_wstrb(m_axi_wstrb),        // output wire [31 : 0] m_axi_wstrb
  .m_axi_wlast(m_axi_wlast),        // output wire m_axi_wlast
  .m_axi_wuser(m_axi_wuser),        // output wire [0 : 0] m_axi_wuser
  .m_axi_wvalid(m_axi_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(m_axi_wready),      // input wire m_axi_wready
  .m_axi_bid(m_axi_bid),            // input wire [0 : 0] m_axi_bid
  .m_axi_bresp(m_axi_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_buser(m_axi_buser),        // input wire [0 : 0] m_axi_buser
  .m_axi_bvalid(m_axi_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(m_axi_bready),      // output wire m_axi_bready
  .m_axi_arid(m_axi_arid),          // output wire [0 : 0] m_axi_arid
  .m_axi_araddr(m_axi_araddr),      // output wire [31 : 0] m_axi_araddr
  .m_axi_arlen(m_axi_arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(m_axi_arsize),      // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(m_axi_arburst),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(m_axi_arlock),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(m_axi_arcache),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(m_axi_arprot),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(m_axi_arregion),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(m_axi_arqos),        // output wire [3 : 0] m_axi_arqos
  .m_axi_aruser(m_axi_aruser),      // output wire [0 : 0] m_axi_aruser
  .m_axi_arvalid(m_axi_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(m_axi_arready),    // input wire m_axi_arready
  .m_axi_rid(m_axi_rid),            // input wire [0 : 0] m_axi_rid
  .m_axi_rdata(m_axi_rdata),        // input wire [255 : 0] m_axi_rdata
  .m_axi_rresp(m_axi_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(m_axi_rlast),        // input wire m_axi_rlast
  .m_axi_ruser(m_axi_ruser),        // input wire [0 : 0] m_axi_ruser
  .m_axi_rvalid(m_axi_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(m_axi_rready)      // output wire m_axi_rready
);


endmodule
