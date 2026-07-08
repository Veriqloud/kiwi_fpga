`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/30/2026
// Design Name: rng_test
// Module Name: angles_top_wrapper_tb
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Testbench for angles_top_wrapper. Drives the AXI4-Stream entropy
//              producer (s_axis_aclk = 250 MHz) plus the clk80 / clk200 domains,
//              reads dout[3:0] at 40 MHz, and checks the per-lane distribution:
//              even lanes dout[3],dout[1] ~= 50/50; uneven lanes dout[2],dout[0]
//              ~= biased (P0/2^PREC zeros). The lane separation also verifies the
//              {E,U,E,U} ordering of the recombine.
//
//              NOTE: instantiates Xilinx FIFO IP (fifo_128x16,
//              fifo_decoy_rng_128x16, fifo_decoy_1x2). Run under Vivado xsim
//              with those IPs added so their sim models are generated from the
//              .xci files. (fifo_4x4 removed: the recombine now captures a
//              nibble directly on rd_en_4 with no output FIFO.)
//
// Dependencies: angles_top_wrapper.v and its submodules + FIFO IP
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module angles_top_wrapper_tb;

    // ----- test configuration -----
    localparam integer PREC      = 15;
    localparam [15:0]  P0        = 16'd3277;   // P(uneven bit == 0) ~= 0.1
    localparam integer N_READS   = 4000;       // nibbles to collect before finishing
    localparam integer RD_PERIOD = 5;          // clk200 cycles per read (200/5 = 40 MHz)
    localparam integer WR_START  = 16;         // s_axis_aclk cycles before streaming

    real exp_p0;                               // expected uneven P(0)

    // ----- clocks -----
    reg s_axis_aclk = 1'b0;   // 250 MHz entropy producer (period 4 ns)
    reg clk80       = 1'b0;   //  80 MHz processing       (period 12.5 ns)
    reg clk200      = 1'b0;   // 200 MHz output domain    (period 5 ns)

    always #2.0   s_axis_aclk = ~s_axis_aclk;
    always #6.25  clk80       = ~clk80;
    always #2.5   clk200      = ~clk200;

    // ----- DUT I/O (names match module ports) -----
    reg          rst;
    wire [127:0] s_axis_tdata;
    reg          s_axis_tvalid;
    wire         s_axis_tready;
    wire [15:0]  s_axis_tkeep;
    wire         s_axis_tlast;
    reg          rd_en_4;
    wire [3:0]   dout;
    wire         dout_empty;

    angles_top_wrapper #(
        .PREC (PREC)
    ) dut (
        .rst           (rst),
        .s_axis_aclk   (s_axis_aclk),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tkeep  (s_axis_tkeep),
        .s_axis_tlast  (s_axis_tlast),
        .clk80         (clk80),
        .rdec_p0_i     (P0),            // runtime P(bit==0); held constant in this tb
        .clk200        (clk200),
        .rd_en_4       (rd_en_4),
        .dout          (dout),
        .dout_empty    (dout_empty)
    );

    // ----- reset (released on a clk80 edge) -----
    initial begin
        rst = 1'b1;
        repeat (20) @(posedge clk80);
        @(negedge clk80);
        rst = 1'b0;
    end

    // =====================================================================
    // AXI4-Stream entropy producer (s_axis_aclk): LFSR-filled 128-bit beats.
    // tdata is held stable while valid & ~ready; the LFSR only advances on an
    // accepted beat (tvalid & tready), per AXIS rules.
    // =====================================================================
    reg  [31:0] lfsr;
    reg  [7:0]  wstart;
    wire        fb = lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0];

    assign s_axis_tdata = { lfsr,
                            ~lfsr,
                            {lfsr[15:0], lfsr[31:16]},
                            lfsr ^ 32'hDEAD_BEEF };
    assign s_axis_tkeep = 16'hFFFF;   // full beats (ignored by DUT)
    assign s_axis_tlast = 1'b0;       // continuous stream (ignored by DUT)

    always @(posedge s_axis_aclk) begin
        if (rst) begin
            lfsr          <= 32'hACE1_2345;
            wstart        <= 8'd0;
            s_axis_tvalid <= 1'b0;
        end else begin
            if (wstart < WR_START) wstart <= wstart + 8'd1;
            s_axis_tvalid <= (wstart >= WR_START);
            // advance entropy only when the beat is consumed
            if (s_axis_tvalid & s_axis_tready) lfsr <= {lfsr[30:0], fb};
        end
    end

    // =====================================================================
    // output consumer (clk200): pulse rd_en_4 at 40 MHz gated by ~dout_empty
    // (dout_empty now = "both branches not ready this tick"). dout is registered
    // in the DUT on rd_en_4, so it is valid the cycle AFTER rd_en_4 (same latency
    // as the old Standard FIFO) and holds stable until the next tick.
    // Tally even lanes (dout[3],dout[1]) and uneven lanes (dout[2],dout[0]).
    // =====================================================================
    integer rdcnt;
    reg     rd_en_d;
    wire    rd_pulse = (rdcnt == RD_PERIOD-1);

    integer nread;
    integer even_ones,   even_total;
    integer uneven_ones, uneven_total;
    integer underflow_att;       // wanted to read but a branch was not ready

    always @(posedge clk200) begin
        if (rst) begin
            rdcnt         <= 0;
            rd_en_4       <= 1'b0;
            rd_en_d       <= 1'b0;
            nread         <= 0;
            even_ones     <= 0;
            even_total    <= 0;
            uneven_ones   <= 0;
            uneven_total  <= 0;
            underflow_att <= 0;
        end else begin
            // 40 MHz read cadence
            rdcnt   <= rd_pulse ? 0 : rdcnt + 1;
            rd_en_4 <= rd_pulse & ~dout_empty;

            if (rd_pulse & dout_empty) underflow_att <= underflow_att + 1;

            // capture the nibble one cycle after the read
            rd_en_d <= rd_en_4;
            if (rd_en_d) begin
                even_ones    <= even_ones   + dout[3] + dout[1];
                even_total   <= even_total  + 2;
                uneven_ones  <= uneven_ones + dout[2] + dout[0];
                uneven_total <= uneven_total + 2;
                nread        <= nread + 1;
            end
        end
    end

    // =====================================================================
    // finish + self-check
    // =====================================================================
    real even_p1;     // measured P(even lane == 1), expect ~0.5
    real uneven_p0;   // measured P(uneven lane == 0), expect ~exp_p0

    task report_and_finish;
        begin
            even_p1   = (even_total   == 0) ? 0.0 : even_ones * 1.0 / even_total;
            uneven_p0 = (uneven_total == 0) ? 0.0 :
                        (uneven_total - uneven_ones) * 1.0 / uneven_total;
            exp_p0    = P0 * 1.0 / (1 << PREC);

            $display("==========================================================");
            $display(" angles_top_wrapper_tb results");
            $display("   nibbles read        : %0d", nread);
            $display("   even  P(1) measured : %0f  (expected ~0.5)", even_p1);
            $display("   uneven P(0) measured: %0f  (expected ~%0f)", uneven_p0, exp_p0);
            $display("   underflow attempts  : %0d", underflow_att);
            // even lanes ~50/50, uneven lanes biased to exp_p0 (wide windows)
            if (even_p1 > 0.45 && even_p1 < 0.55 &&
                uneven_p0 > exp_p0*0.6 && uneven_p0 < exp_p0*1.4)
                $display("   RESULT: PASS");
            else
                $display("   RESULT: CHECK (a lane is outside its window)");
            $display("==========================================================");
            $finish;
        end
    endtask

    initial begin
        wait (rst == 1'b0);
        @(posedge clk200);
        while (nread < N_READS) @(posedge clk200);
        report_and_finish;
    end

    // global watchdog
    initial begin
        #5_000_000;   // 5 ms
        $display("ERROR: timeout before collecting %0d reads (got %0d)", N_READS, nread);
        report_and_finish;
    end

    // waveform dump (xsim/iverilog compatible)
    initial begin
        $dumpfile("angles_top_wrapper_tb.vcd");
        $dumpvars(0, angles_top_wrapper_tb);
    end

endmodule
