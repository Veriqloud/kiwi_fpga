// ddr_data alone, vfifo as a word queue. MODE 0 clean, 1 one stale word in front of
// the stream, 2 first word missing, 3 two clicks in the same 32-gc word,
// 4 the second of three clicks lies 3 words behind the first (escape path).
// FD_ADJ is added to fiber_delay (FPGA gc units, 1 = 2 periods). Run with run.sh.
`timescale 1ns/1ps
// ddr_data + a FIFO model of vfifo/DDR. MODE:
//   0 clean
//   1 one stale 256-bit word in front of the stream (orphan W beat left in the MIG)
//   2 first word missing from the stream (MIG owed one beat of an old burst)
//   3 same-word double click (two gc entries whose alpha word is the same)
// FD_ADJ is added to fiber_delay_r (FPGA gc units, 1 = 2 periods).
module tb;
  parameter MODE = 0;
  parameter integer FD = 1994;          // host fiber_delay 3987 -> (3987+1)/2
  parameter integer FD_ADJ = 0;
  parameter integer DE = 1989;          // host decoy_fiber_delay 3977 -> 1989
  reg clk=0; always #2.5 clk=~clk;

  reg rstn=0, pps=0, rd_en_4=0;
  reg [3:0] rng=0; reg [1:0] rnga=0;
  reg start_w=0, reg_en=0, cmd_alpha_en=0, cmd_gc_en=0;
  reg [63:0] gc_din=0; reg gc_wr=0;

  wire [255:0] m_tdata; wire m_tvalid, m_tlast;
  reg  [255:0] q [0:65535]; integer qh=0, qt=0;
  wire s_tready; wire [20:0] ext_status; wire [31:0] ext_counts;
  wire [255:0] s_tdata = q[qh];
  wire s_tvalid = (qh != qt);

  ddr_data dut(
    .clk200_i(clk), .pps200_i(pps), .ddr_data_rstn(rstn),
    .rd_en_4(rd_en_4), .rng_data(rng), .rng_a_data(rnga),
    .tvalid200(1'b0), .tdata200(32'd0), .tdata200_mod(16'd0),
    .gate_pos0(32'd0), .gate_pos1(32'd0), .gate_pos2(32'd0), .gate_pos3(32'd0),
    .sr_start_write_ddr_i(start_w), .sr_command_i(3'd3), .sr_command_gc_i(1'b0),
    .sr_command_enable(1'b0), .sr_command_alpha_enable(cmd_alpha_en),
    .sr_command_gc_enable(cmd_gc_en), .sr_reg_enable_i(reg_en),
    .sr_dq_gc_start_i(48'd0), .sr_threshold_i(32'd20),
    .sr_fiber_delay_i(16'(FD+FD_ADJ)), .sr_pair_delay_i(1'b0),
    .sr_de_fiber_delay_i(16'(DE+FD_ADJ)), .sr_de_pair_delay_i(1'b0), .sr_ab_fiber_delay_i(16'd100),
    .sr_current_dq_gc(), .sr_current_dq_gc_valid(),
    .m_axis_tdata(m_tdata), .m_axis_tready(1'b1), .m_axis_tvalid(m_tvalid), .m_axis_clk(clk), .m_axis_tlast(m_tlast),
    .s_axis_tdata(s_tdata), .s_axis_tready(s_tready), .s_axis_tvalid(s_tvalid), .s_axis_clk(clk),
    .m_axis_gc_clk(clk), .m_axis_tdata_gc(), .m_axis_tready_gc(1'b1), .m_axis_tvalid_gc(), .fifo_gc_rst(),
    .s_axis_gc_clk(clk), .s_axis_tdata_gc(gc_din), .s_axis_tready_gc(), .s_axis_tvalid_gc(gc_wr),
    .m_axis_alpha_clk(clk), .m_axis_tdata_alpha(), .m_axis_tready_alpha(1'b1), .m_axis_tvalid_alpha(), .fifo_alpha_rst(),
    .axi_quiet_i(1'b0), .axi_wbeats_i(32'd0), .ext_status_o(ext_status), .ext_counts_o(ext_counts)
  );

  // 40 MHz tick, fixed phase to the pps, rng changes one cycle after the tick
  integer c5=0; reg [15:0] lfsr=16'hACE1;
  always @(posedge clk) begin
    c5 <= (c5==4) ? 0 : c5+1;
    rd_en_4 <= (c5==0);
    if (c5==1) begin
      lfsr <= {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
      rng <= lfsr[3:0]; rnga <= lfsr[9:8];
    end
  end

  // ground truth: the byte ddr_data packs for each gc (tick) index
  reg [7:0] tick_byte [0:2000000]; integer ntick=0;
  always @(posedge clk) if (dut.state==3 && dut.rd_en_4_r[1]) begin
    tick_byte[ntick] = {2'b00, rnga, rng}; ntick = ntick+1;
  end

  // DDR / vfifo model
  integer nwritten=0; reg dropped_first=0;
  initial if (MODE==1) begin q[0] = {8{32'hDEADBEEF}}; qt = 1; end
  always @(posedge clk) begin
    if (m_tvalid) begin
      nwritten <= nwritten+1;
      if (MODE==2 && !dropped_first) dropped_first <= 1;
      else begin q[qt[15:0]] <= m_tdata; qt <= qt+1; end
    end
    if (s_tvalid && s_tready) qh <= qh+1;
  end

  // results: sample at DONE
  integer nclk=0; integer gcs [0:63]; integer nproc=0;
  integer hits [-3:3]; integer k;
  reg [7:0] b; reg [1:0] exp_a; integer gv;
  always @(posedge clk) if (dut.state_alpha==5) begin
    for (k=-3;k<=3;k=k+1) begin
      gv = gcs[nproc] - FD + k*32;          // q=0, pair_delay=0 -> q_pos=1 -> byte[1:0]
      b = tick_byte[gv]; exp_a = b[1:0];
      if (exp_a == dut.alpha_q) hits[k] = hits[k]+1;
    end
    nproc = nproc+1;
  end

  integer i, nclicks;
  initial begin
    for (k=-3;k<=3;k=k+1) hits[k]=0;
    repeat (20) @(posedge clk); rstn=1;
    repeat (10) @(posedge clk); reg_en=1; repeat(10) @(posedge clk); reg_en=0;
    cmd_alpha_en=1; cmd_gc_en=1; start_w=1;
    repeat (200) @(posedge clk); pps=1; repeat (100) @(posedge clk); pps=0;
    wait (nwritten > 600);
    nclicks = (MODE==3) ? 2 : (MODE==4) ? 3 : 48;
    for (i=0;i<nclicks;i=i+1) begin
      if (MODE==3) gcs[i] = 8000 + 3 + 2*i;  // both alpha lookups in the same 32-gc word
      else if (MODE==4) gcs[i] = (i==1) ? 8000 - 100 : 8000 + 400*i;
      else gcs[i] = 4000 + i*301 + (i*7)%32;
      @(posedge clk); gc_din <= {15'd0, 1'b0, 16'd0, gcs[i][31:0]}; gc_wr <= 1;
      @(posedge clk); gc_wr <= 0;
      repeat (3) @(posedge clk);
    end
    repeat (200000) @(posedge clk);
    $display("MODE=%0d FD_ADJ=%0d (host fiber_delay %+0d): %0d lookups done of %0d",
             MODE, FD_ADJ, 2*FD_ADJ, nproc, nclicks);
    for (k=-3;k<=3;k=k+1) $display("  alpha matches truth at gc_time_valid %+0d words (%+0d periods): %0d/%0d",
             k, 64*k, hits[k], nproc);
    $display("  lookup_bad (alpha nibble bit 3) of the last lookup %0d", dut.lookup_bad);
    $display("  read_count %0d, state_alpha %0d, vfifo words left %0d; slip %0d slip_delta %0d err_passed %0d esc %0d drops %0d", dut.read_count, dut.state_alpha, qt-qh, ext_status[5], $signed(ext_status[20:13]), ext_status[3], ext_counts[31:16], ext_counts[15:0]);
    $finish;
  end
endmodule
