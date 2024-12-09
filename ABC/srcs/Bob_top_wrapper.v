//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Thu Nov  7 12:11:17 2024
//Host        : hop-MS-7D67 running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target Bob_top_wrapper.bd
//Design      : Bob_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module Bob_top_wrapper
   (c0_ddr4_act_n,
    c0_ddr4_adr,
    c0_ddr4_ba,
    c0_ddr4_bg,
    c0_ddr4_ck_c,
    c0_ddr4_ck_t,
    c0_ddr4_cke,
    c0_ddr4_cs_n,
    c0_ddr4_dm_n,
    c0_ddr4_dq,
    c0_ddr4_dqs_c,
    c0_ddr4_dqs_t,
    c0_ddr4_odt,
    c0_ddr4_reset_n,
    ddr_sys_clk_n,
    ddr_sys_clk_p,
    ext_clk100_n,
    ext_clk100_p,
    ext_clk10_n,
    ext_clk10_p,
    ext_clk200_o,
    ext_dac_ltc_miso,
    ext_dac_ltc_mosi,
    ext_dac_ltc_sck,
    ext_dac_ltc_ss,
    ext_fastdac_refclk_n,
    ext_fastdac_refclk_p,
    ext_fastdac_sync_n,
    ext_fastdac_sync_p,
    ext_fastdac_sysref_n,
    ext_fastdac_sysref_p,
    ext_fastdac_txn_out,
    ext_fastdac_txp_out,
    ext_pps,
    ext_rst_jic,
    ext_stopa_sim,
    ext_sync_ltc,
    ext_tdc_frame_A_n,
    ext_tdc_frame_A_p,
    ext_tdc_frame_B_n,
    ext_tdc_frame_B_p,
    ext_tdc_lclki_n,
    ext_tdc_lclki_p,
    ext_tdc_lclko_n,
    ext_tdc_lclko_p,
    ext_tdc_miso,
    ext_tdc_mosi,
    ext_tdc_refclk_n,
    ext_tdc_refclk_p,
    ext_tdc_rstidxp_n,
    ext_tdc_rstidxp_p,
    ext_tdc_sck,
    ext_tdc_sdi_A_n,
    ext_tdc_sdi_A_p,
    ext_tdc_sdi_B_n,
    ext_tdc_sdi_B_p,
    ext_tdc_ss,
    fifo_gc_out_rst,
    led,
    linterrupt_i,
    locked_pll,
    pcie_7x_mgt_rtl_rxn,
    pcie_7x_mgt_rtl_rxp,
    pcie_7x_mgt_rtl_txn,
    pcie_7x_mgt_rtl_txp,
    pps_trigger,
    probe_tdc_refclk,
    probe_tdc_rstidx,
    pulse_n,
    pulse_p,
    pulse_rep_n,
    pulse_rep_p,
    rd_en_fifo_gc,
    rd_gc_valid,
    read_done,
    sys_clk_n,
    sys_clk_p,
    sys_rst_n);
  output c0_ddr4_act_n;
  output [16:0]c0_ddr4_adr;
  output [1:0]c0_ddr4_ba;
  output c0_ddr4_bg;
  output c0_ddr4_ck_c;
  output c0_ddr4_ck_t;
  output c0_ddr4_cke;
  output c0_ddr4_cs_n;
  inout [3:0]c0_ddr4_dm_n;
  inout [31:0]c0_ddr4_dq;
  inout [3:0]c0_ddr4_dqs_c;
  inout [3:0]c0_ddr4_dqs_t;
  output c0_ddr4_odt;
  output c0_ddr4_reset_n;
  input ddr_sys_clk_n;
  input ddr_sys_clk_p;
  input ext_clk100_n;
  input ext_clk100_p;
  input ext_clk10_n;
  input ext_clk10_p;
  output ext_clk200_o;
  inout ext_dac_ltc_miso;
  inout ext_dac_ltc_mosi;
  inout ext_dac_ltc_sck;
  inout [2:0]ext_dac_ltc_ss;
  input ext_fastdac_refclk_n;
  input ext_fastdac_refclk_p;
  input ext_fastdac_sync_n;
  input ext_fastdac_sync_p;
  input ext_fastdac_sysref_n;
  input ext_fastdac_sysref_p;
  output [3:0]ext_fastdac_txn_out;
  output [3:0]ext_fastdac_txp_out;
  input ext_pps;
  output ext_rst_jic;
  output ext_stopa_sim;
  output ext_sync_ltc;
  input ext_tdc_frame_A_n;
  input ext_tdc_frame_A_p;
  input ext_tdc_frame_B_n;
  input ext_tdc_frame_B_p;
  output ext_tdc_lclki_n;
  output ext_tdc_lclki_p;
  input ext_tdc_lclko_n;
  input ext_tdc_lclko_p;
  inout ext_tdc_miso;
  inout ext_tdc_mosi;
  output ext_tdc_refclk_n;
  output ext_tdc_refclk_p;
  output ext_tdc_rstidxp_n;
  output ext_tdc_rstidxp_p;
  inout ext_tdc_sck;
  input ext_tdc_sdi_A_n;
  input ext_tdc_sdi_A_p;
  input ext_tdc_sdi_B_n;
  input ext_tdc_sdi_B_p;
  inout [1:0]ext_tdc_ss;
  output fifo_gc_out_rst;
  output [0:0]led;
  input linterrupt_i;
  output locked_pll;
  input [3:0]pcie_7x_mgt_rtl_rxn;
  input [3:0]pcie_7x_mgt_rtl_rxp;
  output [3:0]pcie_7x_mgt_rtl_txn;
  output [3:0]pcie_7x_mgt_rtl_txp;
  output pps_trigger;
  output probe_tdc_refclk;
  output probe_tdc_rstidx;
  output [0:0]pulse_n;
  output [0:0]pulse_p;
  output [0:0]pulse_rep_n;
  output [0:0]pulse_rep_p;
  output rd_en_fifo_gc;
  output rd_gc_valid;
  output read_done;
  input sys_clk_n;
  input sys_clk_p;
  input sys_rst_n;

  wire c0_ddr4_act_n;
  wire [16:0]c0_ddr4_adr;
  wire [1:0]c0_ddr4_ba;
  wire c0_ddr4_bg;
  wire c0_ddr4_ck_c;
  wire c0_ddr4_ck_t;
  wire c0_ddr4_cke;
  wire c0_ddr4_cs_n;
  wire [3:0]c0_ddr4_dm_n;
  wire [31:0]c0_ddr4_dq;
  wire [3:0]c0_ddr4_dqs_c;
  wire [3:0]c0_ddr4_dqs_t;
  wire c0_ddr4_odt;
  wire c0_ddr4_reset_n;
  wire ddr_sys_clk_n;
  wire ddr_sys_clk_p;
  wire ext_clk100_n;
  wire ext_clk100_p;
  wire ext_clk10_n;
  wire ext_clk10_p;
  wire ext_clk200_o;
  wire ext_dac_ltc_miso;
  wire ext_dac_ltc_mosi;
  wire ext_dac_ltc_sck;
  wire [2:0]ext_dac_ltc_ss;
  wire ext_fastdac_refclk_n;
  wire ext_fastdac_refclk_p;
  wire ext_fastdac_sync_n;
  wire ext_fastdac_sync_p;
  wire ext_fastdac_sysref_n;
  wire ext_fastdac_sysref_p;
  wire [3:0]ext_fastdac_txn_out;
  wire [3:0]ext_fastdac_txp_out;
  wire ext_pps;
  wire ext_rst_jic;
  wire ext_stopa_sim;
  wire ext_sync_ltc;
  wire ext_tdc_frame_A_n;
  wire ext_tdc_frame_A_p;
  wire ext_tdc_frame_B_n;
  wire ext_tdc_frame_B_p;
  wire ext_tdc_lclki_n;
  wire ext_tdc_lclki_p;
  wire ext_tdc_lclko_n;
  wire ext_tdc_lclko_p;
  wire ext_tdc_miso;
  wire ext_tdc_mosi;
  wire ext_tdc_refclk_n;
  wire ext_tdc_refclk_p;
  wire ext_tdc_rstidxp_n;
  wire ext_tdc_rstidxp_p;
  wire ext_tdc_sck;
  wire ext_tdc_sdi_A_n;
  wire ext_tdc_sdi_A_p;
  wire ext_tdc_sdi_B_n;
  wire ext_tdc_sdi_B_p;
  wire [1:0]ext_tdc_ss;
  wire fifo_gc_out_rst;
  wire [0:0]led;
  wire linterrupt_i;
  wire locked_pll;
  wire [3:0]pcie_7x_mgt_rtl_rxn;
  wire [3:0]pcie_7x_mgt_rtl_rxp;
  wire [3:0]pcie_7x_mgt_rtl_txn;
  wire [3:0]pcie_7x_mgt_rtl_txp;
  wire pps_trigger;
  wire probe_tdc_refclk;
  wire probe_tdc_rstidx;
  wire [0:0]pulse_n;
  wire [0:0]pulse_p;
  wire [0:0]pulse_rep_n;
  wire [0:0]pulse_rep_p;
  wire rd_en_fifo_gc;
  wire rd_gc_valid;
  wire read_done;
  wire sys_clk_n;
  wire sys_clk_p;
  wire sys_rst_n;

  Bob_top Bob_top_i
       (.c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_adr(c0_ddr4_adr),
        .c0_ddr4_ba(c0_ddr4_ba),
        .c0_ddr4_bg(c0_ddr4_bg),
        .c0_ddr4_ck_c(c0_ddr4_ck_c),
        .c0_ddr4_ck_t(c0_ddr4_ck_t),
        .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_cs_n(c0_ddr4_cs_n),
        .c0_ddr4_dm_n(c0_ddr4_dm_n),
        .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
        .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_reset_n(c0_ddr4_reset_n),
        .ddr_sys_clk_n(ddr_sys_clk_n),
        .ddr_sys_clk_p(ddr_sys_clk_p),
        .ext_clk100_n(ext_clk100_n),
        .ext_clk100_p(ext_clk100_p),
        .ext_clk10_n(ext_clk10_n),
        .ext_clk10_p(ext_clk10_p),
        .ext_clk200_o(ext_clk200_o),
        .ext_dac_ltc_miso(ext_dac_ltc_miso),
        .ext_dac_ltc_mosi(ext_dac_ltc_mosi),
        .ext_dac_ltc_sck(ext_dac_ltc_sck),
        .ext_dac_ltc_ss(ext_dac_ltc_ss),
        .ext_fastdac_refclk_n(ext_fastdac_refclk_n),
        .ext_fastdac_refclk_p(ext_fastdac_refclk_p),
        .ext_fastdac_sync_n(ext_fastdac_sync_n),
        .ext_fastdac_sync_p(ext_fastdac_sync_p),
        .ext_fastdac_sysref_n(ext_fastdac_sysref_n),
        .ext_fastdac_sysref_p(ext_fastdac_sysref_p),
        .ext_fastdac_txn_out(ext_fastdac_txn_out),
        .ext_fastdac_txp_out(ext_fastdac_txp_out),
        .ext_pps(ext_pps),
        .ext_rst_jic(ext_rst_jic),
        .ext_stopa_sim(ext_stopa_sim),
        .ext_sync_ltc(ext_sync_ltc),
        .ext_tdc_frame_A_n(ext_tdc_frame_A_n),
        .ext_tdc_frame_A_p(ext_tdc_frame_A_p),
        .ext_tdc_frame_B_n(ext_tdc_frame_B_n),
        .ext_tdc_frame_B_p(ext_tdc_frame_B_p),
        .ext_tdc_lclki_n(ext_tdc_lclki_n),
        .ext_tdc_lclki_p(ext_tdc_lclki_p),
        .ext_tdc_lclko_n(ext_tdc_lclko_n),
        .ext_tdc_lclko_p(ext_tdc_lclko_p),
        .ext_tdc_miso(ext_tdc_miso),
        .ext_tdc_mosi(ext_tdc_mosi),
        .ext_tdc_refclk_n(ext_tdc_refclk_n),
        .ext_tdc_refclk_p(ext_tdc_refclk_p),
        .ext_tdc_rstidxp_n(ext_tdc_rstidxp_n),
        .ext_tdc_rstidxp_p(ext_tdc_rstidxp_p),
        .ext_tdc_sck(ext_tdc_sck),
        .ext_tdc_sdi_A_n(ext_tdc_sdi_A_n),
        .ext_tdc_sdi_A_p(ext_tdc_sdi_A_p),
        .ext_tdc_sdi_B_n(ext_tdc_sdi_B_n),
        .ext_tdc_sdi_B_p(ext_tdc_sdi_B_p),
        .ext_tdc_ss(ext_tdc_ss),
        .fifo_gc_out_rst(fifo_gc_out_rst),
        .led(led),
        .linterrupt_i(linterrupt_i),
        .locked_pll(locked_pll),
        .pcie_7x_mgt_rtl_rxn(pcie_7x_mgt_rtl_rxn),
        .pcie_7x_mgt_rtl_rxp(pcie_7x_mgt_rtl_rxp),
        .pcie_7x_mgt_rtl_txn(pcie_7x_mgt_rtl_txn),
        .pcie_7x_mgt_rtl_txp(pcie_7x_mgt_rtl_txp),
        .pps_trigger(pps_trigger),
        .probe_tdc_refclk(probe_tdc_refclk),
        .probe_tdc_rstidx(probe_tdc_rstidx),
        .pulse_n(pulse_n),
        .pulse_p(pulse_p),
        .pulse_rep_n(pulse_rep_n),
        .pulse_rep_p(pulse_rep_p),
        .rd_en_fifo_gc(rd_en_fifo_gc),
        .rd_gc_valid(rd_gc_valid),
        .read_done(read_done),
        .sys_clk_n(sys_clk_n),
        .sys_clk_p(sys_clk_p),
        .sys_rst_n(sys_rst_n));
endmodule
