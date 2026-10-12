`timescale 1ns/1ps
// System-level model of the DDR path around the real ddr_data and
// ddr_axi_reset_seq RTL:
//   ddr_data.m_axis -> packet FIFO (axis_burst) -> vfifo model -> AXI clock
//   converter model (5 channel FIFOs, emptied when S or M side is in reset)
//   -> MIG AXI shim model (one W beat may be held without a command; W beats
//   are matched to AW commands by count, WLAST ignored, as ddr4_v2_2_axi_w_channel)
//   -> DDR array (never reset).
//
// TOPO 0: reset topology of bit_sep17 (MIG AXI shim never reset by software)
// TOPO 1: ddr_axi_reset_seq (MIG AXI shim reset together with the S side)
// CUT  0: Ddr.init lands while the MIG holds W beat 0 of a burst whose AW it
//         has not taken yet (orphan beat)
// CUT  1: Ddr.init lands while the MIG has 15 of 16 beats of a burst (owes 1)
// QUIESCE 1: the host lowers start_write and waits for 0x34[11] before Ddr.init
//
// Session A runs, clicks are looked up, then Ddr.init; session B runs and its
// lookups are scored against the bytes ddr_data packed in session B.
module tb_sys;
  parameter integer TOPO = 1;
  parameter integer CUT = 0;
  parameter integer QUIESCE = 0;
  parameter integer FD = 1994;
  parameter integer DE = 1989;
  parameter integer LAT_AW = 6;       // AW reaches the MIG after W beat 0
  parameter integer CAP = 2048;       // vfifo DDR ring, words

  reg clk = 0;   always #2.5  clk = ~clk;     // clk200
  reg clk_ui = 0; always #1.667 clk_ui = ~clk_ui;  // MIG ui_clk
  integer cyc = 0; always @(posedge clk) cyc <= cyc + 1;

  // ---------------- resets -------------------------------------------------
  reg req_rstn = 0;                 // 0x12000 offset 0x10 (ddr_data_rst)
  reg [2:0] req_r = 0;
  always @(posedge clk) req_r <= {req_r[1:0], req_rstn};
  wire s_rstn_seq, m_rstn_seq;
  ddr_axi_reset_seq seq (.clk200_i(clk), .req_rstn_200(req_r[1]), .clk_ui_i(clk_ui),
                         .rst_ui_i(1'b0), .s_rstn_200_o(s_rstn_seq), .m_rstn_ui_o(m_rstn_seq));
  wire s_rstn_in = (TOPO == 1) ? s_rstn_seq : req_r[1];
  wire S_rstn;
  reset_register #(.RST_ACTIVE_LEVEL("LOW")) s_rr (.clk_i(clk), .rstn_i(s_rstn_in), .rst_i(1'b0),
                                                  .clk_o(), .rstn_o(S_rstn), .rst_o());
  wire M_rstn = (TOPO == 1) ? m_rstn_seq : 1'b1;

  // ---------------- ddr_data -----------------------------------------------
  reg pps = 0, rd_en_4 = 0;
  reg [3:0] rng = 0; reg [1:0] rnga = 0;
  reg start_w = 0, reg_en = 0;
  reg [63:0] gc_din = 0; reg gc_wr = 0;
  wire [255:0] m_tdata; wire m_tvalid, m_tlast;
  reg m_tready_r = 0;
  wire s_tready;
  reg s_tvalid_r = 0; reg [255:0] s_tdata_r = 0;
  wire [20:0] ext_status; wire [31:0] ext_counts;
  reg axi_quiet = 0; reg [31:0] wbeats = 0;

  ddr_data #(.STOP_FILTER_LOG2(6)) dut(
    .clk200_i(clk), .pps200_i(pps), .ddr_data_rstn(S_rstn),
    .rd_en_4(rd_en_4), .rng_data(rng), .rng_a_data(rnga),
    .tvalid200(1'b0), .tdata200(32'd0), .tdata200_mod(16'd0),
    .gate_pos0(32'd0), .gate_pos1(32'd0), .gate_pos2(32'd0), .gate_pos3(32'd0),
    .sr_start_write_ddr_i(start_w), .sr_command_i(3'd3), .sr_command_gc_i(1'b0),
    .sr_command_enable(1'b0), .sr_command_alpha_enable(1'b1),
    .sr_command_gc_enable(1'b1), .sr_reg_enable_i(reg_en),
    .sr_dq_gc_start_i(48'd0), .sr_threshold_i(32'd20),
    .sr_fiber_delay_i(16'(FD)), .sr_pair_delay_i(1'b0),
    .sr_de_fiber_delay_i(16'(DE)), .sr_de_pair_delay_i(1'b0), .sr_ab_fiber_delay_i(16'd100),
    .sr_current_dq_gc(), .sr_current_dq_gc_valid(),
    .m_axis_tdata(m_tdata), .m_axis_tready(m_tready_r), .m_axis_tvalid(m_tvalid), .m_axis_clk(clk), .m_axis_tlast(m_tlast),
    .s_axis_tdata(s_tdata_r), .s_axis_tready(s_tready), .s_axis_tvalid(s_tvalid_r), .s_axis_clk(clk),
    .m_axis_gc_clk(clk), .m_axis_tdata_gc(), .m_axis_tready_gc(1'b1), .m_axis_tvalid_gc(), .fifo_gc_rst(),
    .s_axis_gc_clk(clk), .s_axis_tdata_gc(gc_din), .s_axis_tready_gc(), .s_axis_tvalid_gc(gc_wr),
    .m_axis_alpha_clk(clk), .m_axis_tdata_alpha(), .m_axis_tready_alpha(1'b1), .m_axis_tvalid_alpha(), .fifo_alpha_rst(),
    .axi_quiet_i(axi_quiet), .axi_wbeats_i(wbeats), .ext_status_o(ext_status), .ext_counts_o(ext_counts)
  );

  integer c5 = 0; reg [15:0] lfsr = 16'hACE1;
  always @(posedge clk) begin
    c5 <= (c5 == 4) ? 0 : c5 + 1;
    rd_en_4 <= (c5 == 0);
    if (c5 == 1) begin
      lfsr <= {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
      rng <= lfsr[3:0]; rnga <= lfsr[9:8];
    end
  end

  // ground truth of the session in progress
  reg [7:0] tick_byte [0:400000]; integer ntick = 0; reg [2:0] st_prev = 0;
  always @(posedge clk) begin
    if (dut.state == 3 && st_prev != 3) ntick = 0;
    if (dut.state == 3 && dut.rd_en_4_r[1]) begin tick_byte[ntick] = {2'b00, rnga, rng}; ntick = ntick + 1; end
    st_prev = dut.state;
  end

  // ---------------- fabric model ------------------------------------------
  // packet FIFO (axis_burst), reset with S
  reg [255:0] pk_d [0:255]; reg pk_l [0:255]; integer pk_h = 0, pk_t = 0, pk_pkts = 0;
  // vfifo
  integer wptr = 0, fptr = 0, committed = 0, ar_ptr = 0;
  integer lenq [0:63]; integer lq_h = 0, lq_t = 0;   // lens of AWs waiting for B
  integer rd_out = 0;  // beats still expected for outstanding ARs
  reg [255:0] ob [0:63]; integer ob_h = 0, ob_t = 0;
  // converter queues: entries carry the cycle they become visible
  integer awq_a [0:255], awq_n [0:255], awq_r [0:255]; integer aw_h = 0, aw_t = 0;
  reg [255:0] wq_d [0:1023]; integer wq_r [0:1023]; integer w_h = 0, w_t = 0;
  integer bq_r [0:255]; integer b_h = 0, b_t = 0;
  integer arq_a [0:255], arq_n [0:255], arq_r [0:255]; integer ar_h = 0, ar_t = 0;
  reg [255:0] rq_d [0:1023]; reg rq_l [0:1023]; integer rq_r [0:1023]; integer r_h = 0, r_t = 0;
  // MIG AXI shim
  reg aw_act = 0; integer aw_addr = 0, aw_len = 0, got = 0;
  reg hold_v = 0; reg [255:0] hold_d = 0;
  reg r_act = 0; integer r_addr = 0, r_len = 0, r_i = 0;
  reg [255:0] ddr [0:CAP-1];
  integer quiet_cnt = 0;
  integer i, n;
  reg busy;

  always @(posedge clk) begin
    // ---- packet FIFO + vfifo (S side)
    if (!S_rstn) begin
      pk_h = 0; pk_t = 0; pk_pkts = 0; wbeats <= 0;
      wptr = 0; fptr = 0; committed = 0; ar_ptr = 0; lq_h = 0; lq_t = 0; rd_out = 0; ob_h = 0; ob_t = 0;
    end else begin
      if (m_tvalid && m_tready_r) begin
        pk_d[pk_t % 256] = m_tdata; pk_l[pk_t % 256] = m_tlast; pk_t = pk_t + 1;
        if (m_tlast) pk_pkts = pk_pkts + 1;
      end
      if (s_tvalid_r && s_tready) begin ob_h = ob_h + 1; fptr = fptr + 1; end
      // s2mm: one packet per AW, beats one cycle apart
      if (pk_pkts > 0 && (wptr - fptr) <= CAP - 16 && (lq_t - lq_h) < 8) begin
        n = 0;
        while (n < 16 && pk_h != pk_t) begin
          wq_d[w_t % 1024] = pk_d[pk_h % 256]; wq_r[w_t % 1024] = cyc + 1 + n; w_t = w_t + 1;
          wbeats <= wbeats + n + 1;   // W beats sent on m_axi (counted when queued)
          n = n + 1;
          if (pk_l[pk_h % 256]) begin pk_h = pk_h + 1; pk_pkts = pk_pkts - 1; n = n + 100; end
          else pk_h = pk_h + 1;
        end
        if (n >= 100) n = n - 100;
        awq_a[aw_t % 256] = wptr % CAP; awq_n[aw_t % 256] = n; awq_r[aw_t % 256] = cyc + LAT_AW; aw_t = aw_t + 1;
        lenq[lq_t % 64] = n; lq_t = lq_t + 1;
        wptr = wptr + n;
      end
      // B
      if (b_h != b_t && bq_r[b_h % 256] <= cyc) begin
        b_h = b_h + 1;
        if (lq_h != lq_t) begin committed = committed + lenq[lq_h % 64]; lq_h = lq_h + 1; end
      end
      // mm2s
      if (rd_out == 0 && committed - ar_ptr >= 16 && (ob_t - ob_h) <= 64 - 16) begin
        arq_a[ar_t % 256] = ar_ptr % CAP; arq_n[ar_t % 256] = 16; arq_r[ar_t % 256] = cyc + 2; ar_t = ar_t + 1;
        ar_ptr = ar_ptr + 16; rd_out = 16;
      end
      if (rd_out > 0 && r_h != r_t && rq_r[r_h % 1024] <= cyc) begin
        ob[ob_t % 64] = rq_d[r_h % 1024]; ob_t = ob_t + 1; r_h = r_h + 1; rd_out = rd_out - 1;
      end
    end
    // ---- converter: emptied when either side is in reset
    if (!S_rstn || !M_rstn) begin
      aw_h = aw_t; w_h = w_t; b_h = b_t; ar_h = ar_t; r_h = r_t;
    end
    // ---- MIG AXI shim (M side); the DDR array keeps its contents
    if (!M_rstn) begin
      aw_act = 0; got = 0; hold_v = 0; r_act = 0;
    end else begin
      if (!aw_act && aw_h != aw_t && awq_r[aw_h % 256] <= cyc) begin
        aw_act = 1; aw_addr = awq_a[aw_h % 256]; aw_len = awq_n[aw_h % 256]; got = 0; aw_h = aw_h + 1;
      end
      if (aw_act && hold_v) begin
        ddr[(aw_addr + got) % CAP] = hold_d; got = got + 1; hold_v = 0;
      end else if (w_h != w_t && wq_r[w_h % 1024] <= cyc) begin
        if (aw_act) begin ddr[(aw_addr + got) % CAP] = wq_d[w_h % 1024]; got = got + 1; w_h = w_h + 1; end
        else if (!hold_v) begin hold_d = wq_d[w_h % 1024]; hold_v = 1; w_h = w_h + 1; end
      end
      if (aw_act && got == aw_len) begin
        if (S_rstn) begin bq_r[b_t % 256] = cyc + 3; b_t = b_t + 1; end
        aw_act = 0;
      end
      if (!r_act && ar_h != ar_t && arq_r[ar_h % 256] <= cyc) begin
        r_act = 1; r_addr = arq_a[ar_h % 256]; r_len = arq_n[ar_h % 256]; r_i = 0; ar_h = ar_h + 1;
      end
      if (r_act) begin
        if (S_rstn) begin
          rq_d[r_t % 1024] = ddr[(r_addr + r_i) % CAP]; rq_l[r_t % 1024] = (r_i == r_len - 1);
          rq_r[r_t % 1024] = cyc + 4; r_t = r_t + 1;
        end
        r_i = r_i + 1; if (r_i == r_len) r_act = 0;
      end
    end
    // ---- m_axi idle (axi_virtual_controller_wrapper axi_quiet_o)
    busy = (aw_h != aw_t) || (w_h != w_t) || (b_h != b_t) || (ar_h != ar_t) || (r_h != r_t) ||
           aw_act || r_act || (lq_h != lq_t) || (rd_out != 0);
    if (!S_rstn || busy) quiet_cnt = 0; else if (quiet_cnt < 1023) quiet_cnt = quiet_cnt + 1;
    // ---- outputs towards ddr_data, seen at the next edge
    m_tready_r <= S_rstn && (pk_t - pk_h) < 255;
    s_tvalid_r <= S_rstn && (ob_t != ob_h);
    s_tdata_r  <= ob[ob_h % 64];
    axi_quiet  <= S_rstn && !busy && quiet_cnt >= 1023;
  end

  // ---------------- lookups ------------------------------------------------
  integer gcs [0:63]; integer nproc = 0, hits [-2:2], k, gv; reg score = 0;
  reg [7:0] b;
  always @(posedge clk) if (dut.state_alpha == 5) begin
    if (score) for (k = -2; k <= 2; k = k + 1) begin
      gv = gcs[nproc] - FD + k*32; b = tick_byte[gv];
      if (b[1:0] == dut.alpha_q) hits[k] = hits[k] + 1;
    end
    nproc = nproc + 1;
  end

  task session_start;
    begin
      start_w <= 0; repeat (20) @(posedge clk);
      start_w <= 1; repeat (50) @(posedge clk);
      pps <= 1; repeat (100) @(posedge clk); pps <= 0;
      wait (dut.state == 3);
    end
  endtask
  task clicks(input integer base);
    integer j;
    begin
      wait (ntick > 32*700);
      nproc = 0;
      for (j = 0; j < 48; j = j + 1) begin
        gcs[j] = base + j*301 + (j*7)%32;
        @(posedge clk); gc_din <= {15'd0, 1'b0, 16'd0, gcs[j][31:0]}; gc_wr <= 1;
        @(posedge clk); gc_wr <= 0;
        repeat (3) @(posedge clk);
      end
      wait (nproc == 48);
    end
  endtask

  integer t0;
  initial begin
    for (k = -2; k <= 2; k = k + 1) hits[k] = 0;
    repeat (20) @(posedge clk); req_rstn = 1;
    wait (S_rstn);
    repeat (10) @(posedge clk); reg_en <= 1; repeat (10) @(posedge clk); reg_en <= 0;
    // ---- session A
    session_start;
    clicks(4000);
    $display("session A: %0d lookups, slip %0d, err_passed %0d", nproc, ext_status[5], ext_status[3]);
    // ---- end of session A, Ddr.init
    if (QUIESCE) begin
      start_w <= 0; t0 = cyc;
      wait (ext_status[0] == 1);
      $display("quiesced %0d cycles after start_write fell (writer stopped %0d, axi quiet %0d)",
               cyc - t0, ext_status[1], ext_status[2]);
    end else begin
      if (CUT == 0) wait (hold_v && !aw_act);
      else          wait (aw_act && got == 13);   // two more beats land before the reset reaches the converter
      start_w <= 0;
    end
    $display("Ddr.init at cycle %0d: MIG hold_v %0d aw_act %0d got %0d", cyc, hold_v, aw_act, got);
    req_rstn = 0; repeat (40) @(posedge clk); req_rstn = 1;
    wait (S_rstn);
    repeat (5) @(posedge clk);
    $display("after Ddr.init: MIG hold_v %0d aw_act %0d got %0d", hold_v, aw_act, got);
    // ---- session B
    session_start;
    score = 1;
    clicks(4000);
    $display("TOPO=%0d CUT=%0d QUIESCE=%0d session B:", TOPO, CUT, QUIESCE);
    for (k = -2; k <= 2; k = k + 1)
      $display("  alpha matches truth at %+0d words (%+0d periods): %0d/48", k, 64*k, hits[k]);
    $display("  0x34[16] slip %0d, slip_delta %0d, err_passed %0d, drops %0d",
             ext_status[5], $signed(ext_status[20:13]), ext_status[3], ext_counts[15:0]);
    $finish;
  end
  initial begin #20000000; $display("TIMEOUT"); $finish; end
endmodule
