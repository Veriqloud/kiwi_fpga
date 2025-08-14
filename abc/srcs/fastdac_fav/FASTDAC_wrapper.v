//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Wed Jul 26 14:26:43 2023
//Host        : hop-MS-7D67 running 64-bit Ubuntu 22.04.2 LTS
//Command     : generate_target FASTDAC_wrapper.bd
//Design      : FASTDAC_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module FASTDAC_wrapper
   (//fasdac_gt_powergood,
    fastdac_axis_tclk,
    fastdac_axis_tdata,
    fastdac_axis_tdest,
    fastdac_axis_tid,
    fastdac_axis_tkeep,
    fastdac_axis_tlast,
    fastdac_axis_tready,
    fastdac_axis_tresetn,
    fastdac_axis_tstrb,
    fastdac_axis_tvalid,
    fastdac_cpll_refclk,
    fastdac_drpclk,
    fastdac_irq,
    fastdac_tx_core_clk,
    fastdac_tx_core_reset,
    fastdac_tx_sync,
    fastdac_tx_sysref,
    fastdac_txn_out,
    fastdac_txp_out,
    m_axi_to_ddr_araddr,
    m_axi_to_ddr_arburst,
    m_axi_to_ddr_arcache,
    m_axi_to_ddr_arid,
    m_axi_to_ddr_arlen,
    m_axi_to_ddr_arlock,
    m_axi_to_ddr_arprot,
    m_axi_to_ddr_arqos,
    m_axi_to_ddr_arready,
    m_axi_to_ddr_arregion,
    m_axi_to_ddr_arsize,
    m_axi_to_ddr_aruser,
    m_axi_to_ddr_arvalid,
    m_axi_to_ddr_awaddr,
    m_axi_to_ddr_awburst,
    m_axi_to_ddr_awcache,
    m_axi_to_ddr_awid,
    m_axi_to_ddr_awlen,
    m_axi_to_ddr_awlock,
    m_axi_to_ddr_awprot,
    m_axi_to_ddr_awqos,
    m_axi_to_ddr_awready,
    m_axi_to_ddr_awregion,
    m_axi_to_ddr_awsize,
    m_axi_to_ddr_awuser,
    m_axi_to_ddr_awvalid,
    m_axi_to_ddr_bid,
    m_axi_to_ddr_bready,
    m_axi_to_ddr_bresp,
    m_axi_to_ddr_buser,
    m_axi_to_ddr_bvalid,
    m_axi_to_ddr_rdata,
    m_axi_to_ddr_rid,
    m_axi_to_ddr_rlast,
    m_axi_to_ddr_rready,
    m_axi_to_ddr_rresp,
    m_axi_to_ddr_ruser,
    m_axi_to_ddr_rvalid,
    m_axi_to_ddr_wdata,
    m_axi_to_ddr_wlast,
    m_axi_to_ddr_wready,
    m_axi_to_ddr_wstrb,
    m_axi_to_ddr_wuser,
    m_axi_to_ddr_wvalid,
    s_axil_aclk,
    s_axil_araddr,
    s_axil_aresetn,
    s_axil_arprot,
    s_axil_arready,
    s_axil_arvalid,
    s_axil_awaddr,
    s_axil_awprot,
    s_axil_awready,
    s_axil_awvalid,
    s_axil_bready,
    s_axil_bresp,
    s_axil_bvalid,
    s_axil_rdata,
    s_axil_rready,
    s_axil_rresp,
    s_axil_rvalid,
    s_axil_wdata,
    s_axil_wready,
    s_axil_wstrb,
    s_axil_wvalid);
//  output fasdac_gt_powergood;
 // input fastdac_en_jesd;
  input fastdac_axis_tclk;
  input [127:0]fastdac_axis_tdata;
  input [0:0]fastdac_axis_tdest;
  input [0:0]fastdac_axis_tid;
  input [15:0]fastdac_axis_tkeep;
  input fastdac_axis_tlast;
  output fastdac_axis_tready;
  input fastdac_axis_tresetn;
  input [15:0]fastdac_axis_tstrb;
  input fastdac_axis_tvalid;
  input fastdac_cpll_refclk;
  input fastdac_drpclk;
  output fastdac_irq;
  input fastdac_tx_core_clk;
  input fastdac_tx_core_reset;
  input fastdac_tx_sync;
  input fastdac_tx_sysref;
  output [3:0]fastdac_txn_out;
  output [3:0]fastdac_txp_out;
//  output [0:0]fastdac_txn_out;
//  output [0:0]fastdac_txp_out;
  output [31:0]m_axi_to_ddr_araddr;
  output [1:0]m_axi_to_ddr_arburst;
  output [3:0]m_axi_to_ddr_arcache;
  output [0:0]m_axi_to_ddr_arid;
  output [7:0]m_axi_to_ddr_arlen;
  output [0:0]m_axi_to_ddr_arlock;
  output [2:0]m_axi_to_ddr_arprot;
  output [3:0]m_axi_to_ddr_arqos;
  input m_axi_to_ddr_arready;
  output [3:0]m_axi_to_ddr_arregion;
  output [2:0]m_axi_to_ddr_arsize;
  output [0:0]m_axi_to_ddr_aruser;
  output m_axi_to_ddr_arvalid;
  output [31:0]m_axi_to_ddr_awaddr;
  output [1:0]m_axi_to_ddr_awburst;
  output [3:0]m_axi_to_ddr_awcache;
  output [0:0]m_axi_to_ddr_awid;
  output [7:0]m_axi_to_ddr_awlen;
  output [0:0]m_axi_to_ddr_awlock;
  output [2:0]m_axi_to_ddr_awprot;
  output [3:0]m_axi_to_ddr_awqos;
  input m_axi_to_ddr_awready;
  output [3:0]m_axi_to_ddr_awregion;
  output [2:0]m_axi_to_ddr_awsize;
  output [0:0]m_axi_to_ddr_awuser;
  output m_axi_to_ddr_awvalid;
  input [0:0]m_axi_to_ddr_bid;
  output m_axi_to_ddr_bready;
  input [1:0]m_axi_to_ddr_bresp;
  input [0:0]m_axi_to_ddr_buser;
  input m_axi_to_ddr_bvalid;
  input [127:0]m_axi_to_ddr_rdata;
  input [0:0]m_axi_to_ddr_rid;
  input m_axi_to_ddr_rlast;
  output m_axi_to_ddr_rready;
  input [1:0]m_axi_to_ddr_rresp;
  input [0:0]m_axi_to_ddr_ruser;
  input m_axi_to_ddr_rvalid;
  output [127:0]m_axi_to_ddr_wdata;
  output m_axi_to_ddr_wlast;
  input m_axi_to_ddr_wready;
  output [15:0]m_axi_to_ddr_wstrb;
  output [0:0]m_axi_to_ddr_wuser;
  output m_axi_to_ddr_wvalid;
  input s_axil_aclk;
  input [12:0]s_axil_araddr;
  input s_axil_aresetn;
  input [2:0]s_axil_arprot;
  output [0:0]s_axil_arready;
  input [0:0]s_axil_arvalid;
  input [12:0]s_axil_awaddr;
  input [2:0]s_axil_awprot;
  output [0:0]s_axil_awready;
  input [0:0]s_axil_awvalid;
  input [0:0]s_axil_bready;
  output [1:0]s_axil_bresp;
  output [0:0]s_axil_bvalid;
  output [31:0]s_axil_rdata;
  input [0:0]s_axil_rready;
  output [1:0]s_axil_rresp;
  output [0:0]s_axil_rvalid;
  input [31:0]s_axil_wdata;
  output [0:0]s_axil_wready;
  input [3:0]s_axil_wstrb;
  input [0:0]s_axil_wvalid;
//  wire fasdac_gt_powergood;
//  wire fastdac_en_jesd;
  wire fastdac_axis_tclk;
  wire [127:0]fastdac_axis_tdata;
  wire [0:0]fastdac_axis_tdest;
  wire [0:0]fastdac_axis_tid;
  wire [15:0]fastdac_axis_tkeep;
  wire fastdac_axis_tlast;
  wire fastdac_axis_tready;
  wire fastdac_axis_tresetn;
  wire [15:0]fastdac_axis_tstrb;
  wire fastdac_axis_tvalid;
  wire fastdac_cpll_refclk;
  wire fastdac_drpclk;
  wire fastdac_irq;
  wire fastdac_tx_core_clk;
  wire fastdac_tx_core_reset;
  wire fastdac_tx_sync;
  wire fastdac_tx_sysref;
  wire [3:0]fastdac_txn_out;
  wire [3:0]fastdac_txp_out;
//  wire [0:0]fastdac_txn_out;
//  wire [0:0]fastdac_txp_out;
  wire [31:0]m_axi_to_ddr_araddr;
  wire [1:0]m_axi_to_ddr_arburst;
  wire [3:0]m_axi_to_ddr_arcache;
  wire [0:0]m_axi_to_ddr_arid;
  wire [7:0]m_axi_to_ddr_arlen;
  wire [0:0]m_axi_to_ddr_arlock;
  wire [2:0]m_axi_to_ddr_arprot;
  wire [3:0]m_axi_to_ddr_arqos;
  wire m_axi_to_ddr_arready;
  wire [3:0]m_axi_to_ddr_arregion;
  wire [2:0]m_axi_to_ddr_arsize;
  wire [0:0]m_axi_to_ddr_aruser;
  wire m_axi_to_ddr_arvalid;
  wire [31:0]m_axi_to_ddr_awaddr;
  wire [1:0]m_axi_to_ddr_awburst;
  wire [3:0]m_axi_to_ddr_awcache;
  wire [0:0]m_axi_to_ddr_awid;
  wire [7:0]m_axi_to_ddr_awlen;
  wire [0:0]m_axi_to_ddr_awlock;
  wire [2:0]m_axi_to_ddr_awprot;
  wire [3:0]m_axi_to_ddr_awqos;
  wire m_axi_to_ddr_awready;
  wire [3:0]m_axi_to_ddr_awregion;
  wire [2:0]m_axi_to_ddr_awsize;
  wire [0:0]m_axi_to_ddr_awuser;
  wire m_axi_to_ddr_awvalid;
  wire [0:0]m_axi_to_ddr_bid;
  wire m_axi_to_ddr_bready;
  wire [1:0]m_axi_to_ddr_bresp;
  wire [0:0]m_axi_to_ddr_buser;
  wire m_axi_to_ddr_bvalid;
  wire [127:0]m_axi_to_ddr_rdata;
  wire [0:0]m_axi_to_ddr_rid;
  wire m_axi_to_ddr_rlast;
  wire m_axi_to_ddr_rready;
  wire [1:0]m_axi_to_ddr_rresp;
  wire [0:0]m_axi_to_ddr_ruser;
  wire m_axi_to_ddr_rvalid;
  wire [127:0]m_axi_to_ddr_wdata;
  wire m_axi_to_ddr_wlast;
  wire m_axi_to_ddr_wready;
  wire [15:0]m_axi_to_ddr_wstrb;
  wire [0:0]m_axi_to_ddr_wuser;
  wire m_axi_to_ddr_wvalid;
  wire s_axil_aclk;
  wire [12:0]s_axil_araddr;
  wire s_axil_aresetn;
  wire [2:0]s_axil_arprot;
  wire [0:0]s_axil_arready;
  wire [0:0]s_axil_arvalid;
  wire [12:0]s_axil_awaddr;
  wire [2:0]s_axil_awprot;
  wire [0:0]s_axil_awready;
  wire [0:0]s_axil_awvalid;
  wire [0:0]s_axil_bready;
  wire [1:0]s_axil_bresp;
  wire [0:0]s_axil_bvalid;
  wire [31:0]s_axil_rdata;
  wire [0:0]s_axil_rready;
  wire [1:0]s_axil_rresp;
  wire [0:0]s_axil_rvalid;
  wire [31:0]s_axil_wdata;
  wire [0:0]s_axil_wready;
  wire [3:0]s_axil_wstrb;
  wire [0:0]s_axil_wvalid;

  FASTDAC FASTDAC_i
       (
//         .fasdac_gt_powergood(fasdac_gt_powergood),
//        .fastdac_en_jesd(fastdac_en_jesd),
        .fastdac_axis_tclk(fastdac_axis_tclk),
        .fastdac_axis_tdata(fastdac_axis_tdata),
        .fastdac_axis_tdest(fastdac_axis_tdest),
        .fastdac_axis_tid(fastdac_axis_tid),
        .fastdac_axis_tkeep(fastdac_axis_tkeep),
        .fastdac_axis_tlast(fastdac_axis_tlast),
        .fastdac_axis_tready(fastdac_axis_tready),
        .fastdac_axis_tresetn(fastdac_axis_tresetn),
        .fastdac_axis_tstrb(fastdac_axis_tstrb),
        .fastdac_axis_tvalid(fastdac_axis_tvalid),
        .fastdac_cpll_refclk(fastdac_cpll_refclk),
        .fastdac_drpclk(fastdac_drpclk),
        .fastdac_irq(fastdac_irq),
        .fastdac_tx_core_clk(fastdac_tx_core_clk),
        .fastdac_tx_core_reset(fastdac_tx_core_reset),
        .fastdac_tx_sync(fastdac_tx_sync),
        .fastdac_tx_sysref(fastdac_tx_sysref),
        .fastdac_txn_out(fastdac_txn_out),
        .fastdac_txp_out(fastdac_txp_out),
        .m_axi_to_ddr_araddr(m_axi_to_ddr_araddr),
        .m_axi_to_ddr_arburst(m_axi_to_ddr_arburst),
        .m_axi_to_ddr_arcache(m_axi_to_ddr_arcache),
        .m_axi_to_ddr_arid(m_axi_to_ddr_arid),
        .m_axi_to_ddr_arlen(m_axi_to_ddr_arlen),
        .m_axi_to_ddr_arlock(m_axi_to_ddr_arlock),
        .m_axi_to_ddr_arprot(m_axi_to_ddr_arprot),
        .m_axi_to_ddr_arqos(m_axi_to_ddr_arqos),
        .m_axi_to_ddr_arready(m_axi_to_ddr_arready),
        .m_axi_to_ddr_arregion(m_axi_to_ddr_arregion),
        .m_axi_to_ddr_arsize(m_axi_to_ddr_arsize),
        .m_axi_to_ddr_aruser(m_axi_to_ddr_aruser),
        .m_axi_to_ddr_arvalid(m_axi_to_ddr_arvalid),
        .m_axi_to_ddr_awaddr(m_axi_to_ddr_awaddr),
        .m_axi_to_ddr_awburst(m_axi_to_ddr_awburst),
        .m_axi_to_ddr_awcache(m_axi_to_ddr_awcache),
        .m_axi_to_ddr_awid(m_axi_to_ddr_awid),
        .m_axi_to_ddr_awlen(m_axi_to_ddr_awlen),
        .m_axi_to_ddr_awlock(m_axi_to_ddr_awlock),
        .m_axi_to_ddr_awprot(m_axi_to_ddr_awprot),
        .m_axi_to_ddr_awqos(m_axi_to_ddr_awqos),
        .m_axi_to_ddr_awready(m_axi_to_ddr_awready),
        .m_axi_to_ddr_awregion(m_axi_to_ddr_awregion),
        .m_axi_to_ddr_awsize(m_axi_to_ddr_awsize),
        .m_axi_to_ddr_awuser(m_axi_to_ddr_awuser),
        .m_axi_to_ddr_awvalid(m_axi_to_ddr_awvalid),
        .m_axi_to_ddr_bid(m_axi_to_ddr_bid),
        .m_axi_to_ddr_bready(m_axi_to_ddr_bready),
        .m_axi_to_ddr_bresp(m_axi_to_ddr_bresp),
        .m_axi_to_ddr_buser(m_axi_to_ddr_buser),
        .m_axi_to_ddr_bvalid(m_axi_to_ddr_bvalid),
        .m_axi_to_ddr_rdata(m_axi_to_ddr_rdata),
        .m_axi_to_ddr_rid(m_axi_to_ddr_rid),
        .m_axi_to_ddr_rlast(m_axi_to_ddr_rlast),
        .m_axi_to_ddr_rready(m_axi_to_ddr_rready),
        .m_axi_to_ddr_rresp(m_axi_to_ddr_rresp),
        .m_axi_to_ddr_ruser(m_axi_to_ddr_ruser),
        .m_axi_to_ddr_rvalid(m_axi_to_ddr_rvalid),
        .m_axi_to_ddr_wdata(m_axi_to_ddr_wdata),
        .m_axi_to_ddr_wlast(m_axi_to_ddr_wlast),
        .m_axi_to_ddr_wready(m_axi_to_ddr_wready),
        .m_axi_to_ddr_wstrb(m_axi_to_ddr_wstrb),
        .m_axi_to_ddr_wuser(m_axi_to_ddr_wuser),
        .m_axi_to_ddr_wvalid(m_axi_to_ddr_wvalid),
        .s_axil_aclk(s_axil_aclk),
        .s_axil_araddr(s_axil_araddr),
        .s_axil_aresetn(s_axil_aresetn),
        .s_axil_arprot(s_axil_arprot),
        .s_axil_arready(s_axil_arready),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awprot(s_axil_awprot),
        .s_axil_awready(s_axil_awready),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_bready(s_axil_bready),
        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rready(s_axil_rready),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_wdata(s_axil_wdata),
        .s_axil_wready(s_axil_wready),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid));
endmodule
