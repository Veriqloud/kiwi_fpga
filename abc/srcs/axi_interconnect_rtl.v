`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2024 05:29:05 PM
// Design Name: 
// Module Name: axi_interconnect_rtl
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


module axi_interconnect_rtl(
    input wire INTERCONNECT_ACLK,
    input wire INTERCONNECT_ARESETN,
    output wire S00_AXI_ARESET_OUT_N,
    input wire S00_AXI_ACLK,
    input wire [0 : 0] S00_AXI_AWID,
    input wire [31 : 0] S00_AXI_AWADDR,
    input wire [7 : 0] S00_AXI_AWLEN,
    input wire [2 : 0] S00_AXI_AWSIZE,
    input wire [1 : 0] S00_AXI_AWBURST,
    input wire S00_AXI_AWLOCK,
    input wire [3 : 0] S00_AXI_AWCACHE,
    input wire [2 : 0] S00_AXI_AWPROT,
    input wire [3 : 0] S00_AXI_AWQOS,
    input wire S00_AXI_AWVALID,
    output wire S00_AXI_AWREADY,
    input wire [31 : 0] S00_AXI_WDATA,
    input wire [3 : 0] S00_AXI_WSTRB,
    input wire S00_AXI_WLAST,
    input wire S00_AXI_WVALID,
    output wire S00_AXI_WREADY,
    output wire [0 : 0] S00_AXI_BID,
    output wire [1 : 0] S00_AXI_BRESP,
    output wire S00_AXI_BVALID,
    input wire S00_AXI_BREADY,
    input wire [0 : 0] S00_AXI_ARID,
    input wire [31 : 0] S00_AXI_ARADDR,
    input wire [7 : 0] S00_AXI_ARLEN,
    input wire [2 : 0] S00_AXI_ARSIZE,
    input wire [1 : 0] S00_AXI_ARBURST,
    input wire S00_AXI_ARLOCK,
    input wire [3 : 0] S00_AXI_ARCACHE,
    input wire [2 : 0] S00_AXI_ARPROT,
    input wire [3 : 0] S00_AXI_ARQOS,
    input wire S00_AXI_ARVALID,
    output wire S00_AXI_ARREADY,
    output wire [0 : 0] S00_AXI_RID,
    output wire [31 : 0] S00_AXI_RDATA,
    output wire [1 : 0] S00_AXI_RRESP,
    output wire S00_AXI_RLAST,
    output wire S00_AXI_RVALID,
    input wire S00_AXI_RREADY,
    output wire M00_AXI_ARESET_OUT_N,
    input wire M00_AXI_ACLK,
    output wire [3 : 0] M00_AXI_AWID,
    output wire [31 : 0] M00_AXI_AWADDR,
    output wire [7 : 0] M00_AXI_AWLEN,
    output wire [2 : 0] M00_AXI_AWSIZE,
    output wire [1 : 0] M00_AXI_AWBURST,
    output wire M00_AXI_AWLOCK,
    output wire [3 : 0] M00_AXI_AWCACHE,
    output wire [2 : 0] M00_AXI_AWPROT,
    output wire [3 : 0] M00_AXI_AWQOS,
    output wire M00_AXI_AWVALID,
    input wire M00_AXI_AWREADY,
    output wire [31 : 0] M00_AXI_WDATA,
    output wire [3 : 0] M00_AXI_WSTRB,
    output wire M00_AXI_WLAST,
    output wire M00_AXI_WVALID,
    input wire M00_AXI_WREADY,
    input wire [3 : 0] M00_AXI_BID,
    input wire [1 : 0] M00_AXI_BRESP,
    input wire M00_AXI_BVALID,
    output wire M00_AXI_BREADY,
    output wire [3 : 0] M00_AXI_ARID,
    output wire [31 : 0] M00_AXI_ARADDR,
    output wire [7 : 0] M00_AXI_ARLEN,
    output wire [2 : 0] M00_AXI_ARSIZE,
    output wire [1 : 0] M00_AXI_ARBURST,
    output wire M00_AXI_ARLOCK,
    output wire [3 : 0] M00_AXI_ARCACHE,
    output wire [2 : 0] M00_AXI_ARPROT,
    output wire [3 : 0] M00_AXI_ARQOS,
    output wire M00_AXI_ARVALID,
    input wire M00_AXI_ARREADY,
    input wire [3 : 0] M00_AXI_RID,
    input wire [31 : 0] M00_AXI_RDATA,
    input wire [1 : 0] M00_AXI_RRESP,
    input wire M00_AXI_RLAST,
    input wire M00_AXI_RVALID,
    output wire M00_AXI_RREADY

    );

axi_interconnect_ddr axi_interconnect_ddr_inst (
  .INTERCONNECT_ACLK(INTERCONNECT_ACLK),        // input wire INTERCONNECT_ACLK
  .INTERCONNECT_ARESETN(INTERCONNECT_ARESETN),  // input wire INTERCONNECT_ARESETN
  .S00_AXI_ARESET_OUT_N(S00_AXI_ARESET_OUT_N),  // output wire S00_AXI_ARESET_OUT_N
  .S00_AXI_ACLK(S00_AXI_ACLK),                  // input wire S00_AXI_ACLK
  .S00_AXI_AWID(S00_AXI_AWID),                  // input wire [0 : 0] S00_AXI_AWID
  .S00_AXI_AWADDR(S00_AXI_AWADDR),              // input wire [31 : 0] S00_AXI_AWADDR
  .S00_AXI_AWLEN(S00_AXI_AWLEN),                // input wire [7 : 0] S00_AXI_AWLEN
  .S00_AXI_AWSIZE(S00_AXI_AWSIZE),              // input wire [2 : 0] S00_AXI_AWSIZE
  .S00_AXI_AWBURST(S00_AXI_AWBURST),            // input wire [1 : 0] S00_AXI_AWBURST
  .S00_AXI_AWLOCK(S00_AXI_AWLOCK),              // input wire S00_AXI_AWLOCK
  .S00_AXI_AWCACHE(S00_AXI_AWCACHE),            // input wire [3 : 0] S00_AXI_AWCACHE
  .S00_AXI_AWPROT(S00_AXI_AWPROT),              // input wire [2 : 0] S00_AXI_AWPROT
  .S00_AXI_AWQOS(S00_AXI_AWQOS),                // input wire [3 : 0] S00_AXI_AWQOS
  .S00_AXI_AWVALID(S00_AXI_AWVALID),            // input wire S00_AXI_AWVALID
  .S00_AXI_AWREADY(S00_AXI_AWREADY),            // output wire S00_AXI_AWREADY
  .S00_AXI_WDATA(S00_AXI_WDATA),                // input wire [31 : 0] S00_AXI_WDATA
  .S00_AXI_WSTRB(S00_AXI_WSTRB),                // input wire [3 : 0] S00_AXI_WSTRB
  .S00_AXI_WLAST(S00_AXI_WLAST),                // input wire S00_AXI_WLAST
  .S00_AXI_WVALID(S00_AXI_WVALID),              // input wire S00_AXI_WVALID
  .S00_AXI_WREADY(S00_AXI_WREADY),              // output wire S00_AXI_WREADY
  .S00_AXI_BID(S00_AXI_BID),                    // output wire [0 : 0] S00_AXI_BID
  .S00_AXI_BRESP(S00_AXI_BRESP),                // output wire [1 : 0] S00_AXI_BRESP
  .S00_AXI_BVALID(S00_AXI_BVALID),              // output wire S00_AXI_BVALID
  .S00_AXI_BREADY(S00_AXI_BREADY),              // input wire S00_AXI_BREADY
  .S00_AXI_ARID(S00_AXI_ARID),                  // input wire [0 : 0] S00_AXI_ARID
  .S00_AXI_ARADDR(S00_AXI_ARADDR),              // input wire [31 : 0] S00_AXI_ARADDR
  .S00_AXI_ARLEN(S00_AXI_ARLEN),                // input wire [7 : 0] S00_AXI_ARLEN
  .S00_AXI_ARSIZE(S00_AXI_ARSIZE),              // input wire [2 : 0] S00_AXI_ARSIZE
  .S00_AXI_ARBURST(S00_AXI_ARBURST),            // input wire [1 : 0] S00_AXI_ARBURST
  .S00_AXI_ARLOCK(S00_AXI_ARLOCK),              // input wire S00_AXI_ARLOCK
  .S00_AXI_ARCACHE(S00_AXI_ARCACHE),            // input wire [3 : 0] S00_AXI_ARCACHE
  .S00_AXI_ARPROT(S00_AXI_ARPROT),              // input wire [2 : 0] S00_AXI_ARPROT
  .S00_AXI_ARQOS(S00_AXI_ARQOS),                // input wire [3 : 0] S00_AXI_ARQOS
  .S00_AXI_ARVALID(S00_AXI_ARVALID),            // input wire S00_AXI_ARVALID
  .S00_AXI_ARREADY(S00_AXI_ARREADY),            // output wire S00_AXI_ARREADY
  .S00_AXI_RID(S00_AXI_RID),                    // output wire [0 : 0] S00_AXI_RID
  .S00_AXI_RDATA(S00_AXI_RDATA),                // output wire [31 : 0] S00_AXI_RDATA
  .S00_AXI_RRESP(S00_AXI_RRESP),                // output wire [1 : 0] S00_AXI_RRESP
  .S00_AXI_RLAST(S00_AXI_RLAST),                // output wire S00_AXI_RLAST
  .S00_AXI_RVALID(S00_AXI_RVALID),              // output wire S00_AXI_RVALID
  .S00_AXI_RREADY(S00_AXI_RREADY),              // input wire S00_AXI_RREADY
  .M00_AXI_ARESET_OUT_N(M00_AXI_ARESET_OUT_N),  // output wire M00_AXI_ARESET_OUT_N
  .M00_AXI_ACLK(M00_AXI_ACLK),                  // input wire M00_AXI_ACLK
  .M00_AXI_AWID(M00_AXI_AWID),                  // output wire [3 : 0] M00_AXI_AWID
  .M00_AXI_AWADDR(M00_AXI_AWADDR),              // output wire [31 : 0] M00_AXI_AWADDR
  .M00_AXI_AWLEN(M00_AXI_AWLEN),                // output wire [7 : 0] M00_AXI_AWLEN
  .M00_AXI_AWSIZE(M00_AXI_AWSIZE),              // output wire [2 : 0] M00_AXI_AWSIZE
  .M00_AXI_AWBURST(M00_AXI_AWBURST),            // output wire [1 : 0] M00_AXI_AWBURST
  .M00_AXI_AWLOCK(M00_AXI_AWLOCK),              // output wire M00_AXI_AWLOCK
  .M00_AXI_AWCACHE(M00_AXI_AWCACHE),            // output wire [3 : 0] M00_AXI_AWCACHE
  .M00_AXI_AWPROT(M00_AXI_AWPROT),              // output wire [2 : 0] M00_AXI_AWPROT
  .M00_AXI_AWQOS(M00_AXI_AWQOS),                // output wire [3 : 0] M00_AXI_AWQOS
  .M00_AXI_AWVALID(M00_AXI_AWVALID),            // output wire M00_AXI_AWVALID
  .M00_AXI_AWREADY(M00_AXI_AWREADY),            // input wire M00_AXI_AWREADY
  .M00_AXI_WDATA(M00_AXI_WDATA),                // output wire [31 : 0] M00_AXI_WDATA
  .M00_AXI_WSTRB(M00_AXI_WSTRB),                // output wire [3 : 0] M00_AXI_WSTRB
  .M00_AXI_WLAST(M00_AXI_WLAST),                // output wire M00_AXI_WLAST
  .M00_AXI_WVALID(M00_AXI_WVALID),              // output wire M00_AXI_WVALID
  .M00_AXI_WREADY(M00_AXI_WREADY),              // input wire M00_AXI_WREADY
  .M00_AXI_BID(M00_AXI_BID),                    // input wire [3 : 0] M00_AXI_BID
  .M00_AXI_BRESP(M00_AXI_BRESP),                // input wire [1 : 0] M00_AXI_BRESP
  .M00_AXI_BVALID(M00_AXI_BVALID),              // input wire M00_AXI_BVALID
  .M00_AXI_BREADY(M00_AXI_BREADY),              // output wire M00_AXI_BREADY
  .M00_AXI_ARID(M00_AXI_ARID),                  // output wire [3 : 0] M00_AXI_ARID
  .M00_AXI_ARADDR(M00_AXI_ARADDR),              // output wire [31 : 0] M00_AXI_ARADDR
  .M00_AXI_ARLEN(M00_AXI_ARLEN),                // output wire [7 : 0] M00_AXI_ARLEN
  .M00_AXI_ARSIZE(M00_AXI_ARSIZE),              // output wire [2 : 0] M00_AXI_ARSIZE
  .M00_AXI_ARBURST(M00_AXI_ARBURST),            // output wire [1 : 0] M00_AXI_ARBURST
  .M00_AXI_ARLOCK(M00_AXI_ARLOCK),              // output wire M00_AXI_ARLOCK
  .M00_AXI_ARCACHE(M00_AXI_ARCACHE),            // output wire [3 : 0] M00_AXI_ARCACHE
  .M00_AXI_ARPROT(M00_AXI_ARPROT),              // output wire [2 : 0] M00_AXI_ARPROT
  .M00_AXI_ARQOS(M00_AXI_ARQOS),                // output wire [3 : 0] M00_AXI_ARQOS
  .M00_AXI_ARVALID(M00_AXI_ARVALID),            // output wire M00_AXI_ARVALID
  .M00_AXI_ARREADY(M00_AXI_ARREADY),            // input wire M00_AXI_ARREADY
  .M00_AXI_RID(M00_AXI_RID),                    // input wire [3 : 0] M00_AXI_RID
  .M00_AXI_RDATA(M00_AXI_RDATA),                // input wire [31 : 0] M00_AXI_RDATA
  .M00_AXI_RRESP(M00_AXI_RRESP),                // input wire [1 : 0] M00_AXI_RRESP
  .M00_AXI_RLAST(M00_AXI_RLAST),                // input wire M00_AXI_RLAST
  .M00_AXI_RVALID(M00_AXI_RVALID),              // input wire M00_AXI_RVALID
  .M00_AXI_RREADY(M00_AXI_RREADY)              // output wire M00_AXI_RREADY
);

endmodule
