//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Tue Sep  9 16:55:03 2025
//Host        : hop-MS-7D67 running 64-bit Ubuntu 24.04.2 LTS
//Command     : generate_target Qline_turnkey_top_wrapper.bd
//Design      : Qline_turnkey_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module Qline_turnkey_top_wrapper
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
    com_ext_spi_dl_miso_io,
    com_ext_spi_dl_mosi_io,
    com_ext_spi_dl_sck_io,
    com_ext_spi_dl_ss_io,
    com_ext_spi_tdc_miso_io,
    com_ext_spi_tdc_mosi_io,
    com_ext_spi_tdc_sck_io,
    com_ext_spi_tdc_ss_io,
    cr_ext_cr_ext_clk100_n,
    cr_ext_cr_ext_clk100_p,
    cr_ext_cr_ext_clk10_n,
    cr_ext_cr_ext_clk10_p,
    cr_ext_cr_fastdac_refclki_n,
    cr_ext_cr_fastdac_refclki_p,
    cr_ext_cr_fastdac_syncout_n,
    cr_ext_cr_fastdac_syncout_p,
    cr_ext_cr_fastdac_sysref_n,
    cr_ext_cr_fastdac_sysref_p,
    ddr_sys_clk_n,
    ddr_sys_clk_p,
    decoy_signal,
    decoy_signal_n,
    decoy_signal_p,
    ext_clk200_o,
    ext_fastdac_txn_out,
    ext_fastdac_txp_out,
    ext_pps,
    ext_stopa_sim,
    ext_sync_ltc,
    ext_sysref,
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
    rd_en_fifo_gc,
    rd_gc_valid,
    read_done,
    rst_jic,
    sys_clk_n,
    sys_clk_p,
    sys_rst_n,
    tdc_ext_clkrst_tdc_lclki_n,
    tdc_ext_clkrst_tdc_lclki_p,
    tdc_ext_clkrst_tdc_refclk_n,
    tdc_ext_clkrst_tdc_refclk_p,
    tdc_ext_clkrst_tdc_rstidx_n,
    tdc_ext_clkrst_tdc_rstidx_p,
    tdc_ext_in_framea_n,
    tdc_ext_in_framea_p,
    tdc_ext_in_frameb_n,
    tdc_ext_in_frameb_p,
    tdc_ext_in_lclk_n,
    tdc_ext_in_lclk_p,
    tdc_ext_in_sdia_n,
    tdc_ext_in_sdia_p,
    tdc_ext_in_sdib_n,
    tdc_ext_in_sdib_p);
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
  inout com_ext_spi_dl_miso_io;
  inout com_ext_spi_dl_mosi_io;
  inout com_ext_spi_dl_sck_io;
  inout [2:0]com_ext_spi_dl_ss_io;
  inout com_ext_spi_tdc_miso_io;
  inout com_ext_spi_tdc_mosi_io;
  inout com_ext_spi_tdc_sck_io;
  inout [1:0]com_ext_spi_tdc_ss_io;
  input cr_ext_cr_ext_clk100_n;
  input cr_ext_cr_ext_clk100_p;
  input cr_ext_cr_ext_clk10_n;
  input cr_ext_cr_ext_clk10_p;
  input cr_ext_cr_fastdac_refclki_n;
  input cr_ext_cr_fastdac_refclki_p;
  input cr_ext_cr_fastdac_syncout_n;
  input cr_ext_cr_fastdac_syncout_p;
  input cr_ext_cr_fastdac_sysref_n;
  input cr_ext_cr_fastdac_sysref_p;
  input ddr_sys_clk_n;
  input ddr_sys_clk_p;
  output decoy_signal;
  output decoy_signal_n;
  output decoy_signal_p;
  output ext_clk200_o;
  output [3:0]ext_fastdac_txn_out;
  output [3:0]ext_fastdac_txp_out;
  input ext_pps;
  output ext_stopa_sim;
  output ext_sync_ltc;
  output ext_sysref;
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
  output rd_en_fifo_gc;
  output rd_gc_valid;
  output read_done;
  output rst_jic;
  input sys_clk_n;
  input sys_clk_p;
  input sys_rst_n;
  output tdc_ext_clkrst_tdc_lclki_n;
  output tdc_ext_clkrst_tdc_lclki_p;
  output tdc_ext_clkrst_tdc_refclk_n;
  output tdc_ext_clkrst_tdc_refclk_p;
  output tdc_ext_clkrst_tdc_rstidx_n;
  output tdc_ext_clkrst_tdc_rstidx_p;
  input tdc_ext_in_framea_n;
  input tdc_ext_in_framea_p;
  input tdc_ext_in_frameb_n;
  input tdc_ext_in_frameb_p;
  input tdc_ext_in_lclk_n;
  input tdc_ext_in_lclk_p;
  input tdc_ext_in_sdia_n;
  input tdc_ext_in_sdia_p;
  input tdc_ext_in_sdib_n;
  input tdc_ext_in_sdib_p;

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
  wire com_ext_spi_dl_miso_io;
  wire com_ext_spi_dl_mosi_io;
  wire com_ext_spi_dl_sck_io;
  wire [2:0]com_ext_spi_dl_ss_io;
  wire com_ext_spi_tdc_miso_io;
  wire com_ext_spi_tdc_mosi_io;
  wire com_ext_spi_tdc_sck_io;
  wire [1:0]com_ext_spi_tdc_ss_io;
  wire cr_ext_cr_ext_clk100_n;
  wire cr_ext_cr_ext_clk100_p;
  wire cr_ext_cr_ext_clk10_n;
  wire cr_ext_cr_ext_clk10_p;
  wire cr_ext_cr_fastdac_refclki_n;
  wire cr_ext_cr_fastdac_refclki_p;
  wire cr_ext_cr_fastdac_syncout_n;
  wire cr_ext_cr_fastdac_syncout_p;
  wire cr_ext_cr_fastdac_sysref_n;
  wire cr_ext_cr_fastdac_sysref_p;
  wire ddr_sys_clk_n;
  wire ddr_sys_clk_p;
  wire decoy_signal;
  wire decoy_signal_n;
  wire decoy_signal_p;
  wire ext_clk200_o;
  wire [3:0]ext_fastdac_txn_out;
  wire [3:0]ext_fastdac_txp_out;
  wire ext_pps;
  wire ext_stopa_sim;
  wire ext_sync_ltc;
  wire ext_sysref;
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
  wire rd_en_fifo_gc;
  wire rd_gc_valid;
  wire read_done;
  wire rst_jic;
  wire sys_clk_n;
  wire sys_clk_p;
  wire sys_rst_n;
  wire tdc_ext_clkrst_tdc_lclki_n;
  wire tdc_ext_clkrst_tdc_lclki_p;
  wire tdc_ext_clkrst_tdc_refclk_n;
  wire tdc_ext_clkrst_tdc_refclk_p;
  wire tdc_ext_clkrst_tdc_rstidx_n;
  wire tdc_ext_clkrst_tdc_rstidx_p;
  wire tdc_ext_in_framea_n;
  wire tdc_ext_in_framea_p;
  wire tdc_ext_in_frameb_n;
  wire tdc_ext_in_frameb_p;
  wire tdc_ext_in_lclk_n;
  wire tdc_ext_in_lclk_p;
  wire tdc_ext_in_sdia_n;
  wire tdc_ext_in_sdia_p;
  wire tdc_ext_in_sdib_n;
  wire tdc_ext_in_sdib_p;

  Qline_turnkey_top Qline_turnkey_top_i
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
        .com_ext_spi_dl_miso_io(com_ext_spi_dl_miso_io),
        .com_ext_spi_dl_mosi_io(com_ext_spi_dl_mosi_io),
        .com_ext_spi_dl_sck_io(com_ext_spi_dl_sck_io),
        .com_ext_spi_dl_ss_io(com_ext_spi_dl_ss_io),
        .com_ext_spi_tdc_miso_io(com_ext_spi_tdc_miso_io),
        .com_ext_spi_tdc_mosi_io(com_ext_spi_tdc_mosi_io),
        .com_ext_spi_tdc_sck_io(com_ext_spi_tdc_sck_io),
        .com_ext_spi_tdc_ss_io(com_ext_spi_tdc_ss_io),
        .cr_ext_cr_ext_clk100_n(cr_ext_cr_ext_clk100_n),
        .cr_ext_cr_ext_clk100_p(cr_ext_cr_ext_clk100_p),
        .cr_ext_cr_ext_clk10_n(cr_ext_cr_ext_clk10_n),
        .cr_ext_cr_ext_clk10_p(cr_ext_cr_ext_clk10_p),
        .cr_ext_cr_fastdac_refclki_n(cr_ext_cr_fastdac_refclki_n),
        .cr_ext_cr_fastdac_refclki_p(cr_ext_cr_fastdac_refclki_p),
        .cr_ext_cr_fastdac_syncout_n(cr_ext_cr_fastdac_syncout_n),
        .cr_ext_cr_fastdac_syncout_p(cr_ext_cr_fastdac_syncout_p),
        .cr_ext_cr_fastdac_sysref_n(cr_ext_cr_fastdac_sysref_n),
        .cr_ext_cr_fastdac_sysref_p(cr_ext_cr_fastdac_sysref_p),
        .ddr_sys_clk_n(ddr_sys_clk_n),
        .ddr_sys_clk_p(ddr_sys_clk_p),
        .decoy_signal(decoy_signal),
        .decoy_signal_n(decoy_signal_n),
        .decoy_signal_p(decoy_signal_p),
        .ext_clk200_o(ext_clk200_o),
        .ext_fastdac_txn_out(ext_fastdac_txn_out),
        .ext_fastdac_txp_out(ext_fastdac_txp_out),
        .ext_pps(ext_pps),
        .ext_stopa_sim(ext_stopa_sim),
        .ext_sync_ltc(ext_sync_ltc),
        .ext_sysref(ext_sysref),
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
        .rd_en_fifo_gc(rd_en_fifo_gc),
        .rd_gc_valid(rd_gc_valid),
        .read_done(read_done),
        .rst_jic(rst_jic),
        .sys_clk_n(sys_clk_n),
        .sys_clk_p(sys_clk_p),
        .sys_rst_n(sys_rst_n),
        .tdc_ext_clkrst_tdc_lclki_n(tdc_ext_clkrst_tdc_lclki_n),
        .tdc_ext_clkrst_tdc_lclki_p(tdc_ext_clkrst_tdc_lclki_p),
        .tdc_ext_clkrst_tdc_refclk_n(tdc_ext_clkrst_tdc_refclk_n),
        .tdc_ext_clkrst_tdc_refclk_p(tdc_ext_clkrst_tdc_refclk_p),
        .tdc_ext_clkrst_tdc_rstidx_n(tdc_ext_clkrst_tdc_rstidx_n),
        .tdc_ext_clkrst_tdc_rstidx_p(tdc_ext_clkrst_tdc_rstidx_p),
        .tdc_ext_in_framea_n(tdc_ext_in_framea_n),
        .tdc_ext_in_framea_p(tdc_ext_in_framea_p),
        .tdc_ext_in_frameb_n(tdc_ext_in_frameb_n),
        .tdc_ext_in_frameb_p(tdc_ext_in_frameb_p),
        .tdc_ext_in_lclk_n(tdc_ext_in_lclk_n),
        .tdc_ext_in_lclk_p(tdc_ext_in_lclk_p),
        .tdc_ext_in_sdia_n(tdc_ext_in_sdia_n),
        .tdc_ext_in_sdia_p(tdc_ext_in_sdia_p),
        .tdc_ext_in_sdib_n(tdc_ext_in_sdib_n),
        .tdc_ext_in_sdib_p(tdc_ext_in_sdib_p));
endmodule
