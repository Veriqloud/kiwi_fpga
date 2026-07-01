`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/29/2026
// Design Name: rng_test
// Module Name: tb_rangedec_top_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Testbench for rangedec_top_wrapper. Drives the three clock domains
//              (wr_clk entropy / clk80 processing / clk200 uneven), pushes LFSR
//              "entropy" into the upstream FIFO, reads the 2-bit uneven output at
//              a 40 MHz cadence, and checks the output bias (~P0/2^PREC zeros).
//
//              NOTE: instantiates Xilinx FIFO IP (fifo_128x16, fifo_1x2).
//              Run under Vivado xsim with the IPs added so their sim models are
//              generated from the .xci files. (fifo_128x16 must be generated;
//              only its .xci is checked in.)
//
// Dependencies: rangedec_top_wrapper.v and its submodules + FIFO IP
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module rangedec_top_wrapper_tb;

    // ----- test configuration -----
    localparam integer PREC      = 15;
    localparam [15:0]  P0        = 16'd3277;   // P(bit==0) ~= 0.1
    localparam integer N_READS   = 3000;       // 2-bit words to collect before finishing
    localparam integer RD_PERIOD = 5;          // clk200 cycles per uneven read (200/5 = 40 MHz)
    localparam integer WR_START  = 16;         // wr_clk cycles to wait before writing
    localparam integer RD_START  = 64;         // clk200 cycles to wait before reading (prime)

    // expected fraction of zero bits, for the pass/fail window
    real exp_p0;

    // ----- clocks -----
    reg wr_clk = 1'b0;   // 100 MHz entropy producer (period 10 ns)
    reg clk80  = 1'b0;   //  80 MHz processing       (period 12.5 ns)
    reg clk200 = 1'b0;   // 200 MHz uneven consumer  (period 5 ns)

    always #5.0   wr_clk = ~wr_clk;
    always #6.25  clk80  = ~clk80;
    always #2.5   clk200 = ~clk200;

    // ----- DUT I/O -----
    reg          rst;
    reg  [127:0] ent_din;
    reg          ent_wr_en;
    wire         ent_full;
    wire        ent_almost_full;
    wire        up_empty;
    wire         uneven_rd_en;
    wire [1:0]   uneven_dout;
    wire         uneven_empty;

    rangedec_top_wrapper #(
        .PREC (PREC),
        .P0   (P0)
    ) dut (
        .rst         (rst),
        .wr_clk      (wr_clk),
        .ent_din     (ent_din),
        .ent_wr_en   (ent_wr_en),
        .ent_full    (ent_full),
        .ent_almost_full (ent_almost_full),
        .up_empty    (up_empty),
        .clk80       (clk80),
        .clk200      (clk200),
        .uneven_rd_en (uneven_rd_en),
        .uneven_dout  (uneven_dout),
        .uneven_empty (uneven_empty)
    );

    // ----- reset (released on a clk80 edge) -----
    initial begin
        rst = 1'b1;
        repeat (20) @(posedge clk80);
        @(negedge clk80);
        rst = 1'b0;
    end

    // =====================================================================
    // entropy producer (wr_clk domain): stream LFSR-filled 128-bit words
    // =====================================================================
    reg  [31:0] lfsr;
    reg  [7:0]  wstart;
    wire        fb = lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0];

    always @(posedge wr_clk) begin
        if (rst) begin
            lfsr      <= 32'hACE1_2345;
            ent_din   <= 128'd0;
            ent_wr_en <= 1'b0;
            wstart    <= 8'd0;
        end else begin
            lfsr    <= {lfsr[30:0], fb};
            ent_din <= { lfsr,
                         ~lfsr,
                         {lfsr[15:0], lfsr[31:16]},
                         lfsr ^ 32'hDEAD_BEEF };
            if (wstart < WR_START) wstart <= wstart + 8'd1;
            // hold writes until past reset-busy, then push whenever not full
            ent_wr_en <= (wstart >= WR_START) & ~ent_full;
        end
    end

    // =====================================================================
    // uneven consumer (clk200 domain): read 2 bits at 40 MHz, tally stats
    // =====================================================================
    integer rdcnt;
    integer rstart;
    reg     rd_en_d;            // 1-cycle-delayed rd_en (Standard FIFO latency)
    wire    rd_pulse = (rdcnt == 0) && (rstart >= RD_START);

    // only read when data is present; otherwise log an underflow attempt
    assign uneven_rd_en = rd_pulse & ~uneven_empty;

    integer nread;
    integer ones;              // number of '1' bits seen
    integer underflow_att;     // wanted to read but FIFO was empty
    integer hist [0:3];        // distribution of 2-bit words

    integer k;
    always @(posedge clk200) begin
        if (rst) begin
            rdcnt         <= 0;
            rstart        <= 0;
            rd_en_d       <= 1'b0;
            nread         <= 0;
            ones          <= 0;
            underflow_att <= 0;
            for (k = 0; k < 4; k = k + 1) hist[k] <= 0;
        end else begin
            // 40 MHz read cadence
            if (rdcnt == RD_PERIOD-1) rdcnt <= 0; else rdcnt <= rdcnt + 1;
            if (rstart < RD_START)    rstart <= rstart + 1;

            // count missed reads (the parked underflow concern)
            if (rd_pulse & uneven_empty) underflow_att <= underflow_att + 1;

            // Standard FIFO: dout valid the cycle AFTER rd_en
            rd_en_d <= uneven_rd_en;
            if (rd_en_d) begin
                hist[uneven_dout] <= hist[uneven_dout] + 1;
                ones             <= ones + uneven_dout[1] + uneven_dout[0];
                nread            <= nread + 1;
            end
        end
    end

    // =====================================================================
    // finish + report
    // =====================================================================
    integer total_bits;
    real    meas_p0;

    task report_and_finish;
        begin
            total_bits = 2*nread;
            meas_p0    = (total_bits == 0) ? 0.0 :
                         (total_bits - ones) * 1.0 / total_bits;
            exp_p0     = P0 * 1.0 / (1 << PREC);

            $display("==========================================================");
            $display(" rangedec_top_wrapper_tb results");
            $display("   words read        : %0d", nread);
            $display("   total output bits : %0d", total_bits);
            $display("   ones / zeros      : %0d / %0d", ones, total_bits - ones);
            $display("   hist 00/01/10/11  : %0d / %0d / %0d / %0d",
                     hist[0], hist[1], hist[2], hist[3]);
            $display("   P(bit=0) measured : %0f  (expected ~%0f)", meas_p0, exp_p0);
            $display("   underflow attempts: %0d", underflow_att);
            // allow a wide tolerance: this is a functional/bias sanity check
            if (meas_p0 > exp_p0*0.6 && meas_p0 < exp_p0*1.4)
                $display("   RESULT: PASS (bias within tolerance)");
            else
                $display("   RESULT: CHECK (bias outside +/-40%% window)");
            $display("==========================================================");
            $finish;
        end
    endtask

    initial begin
        // collect until enough words read, then report
        wait (rst == 1'b0);
        @(posedge clk200);
        while (nread < N_READS) @(posedge clk200);
        report_and_finish;
    end

    // global watchdog
    initial begin
        #2_000_000;   // 2 ms
        $display("ERROR: timeout before collecting %0d reads (got %0d)", N_READS, nread);
        report_and_finish;
    end

    // waveform dump (xsim/iverilog compatible)
    initial begin
        $dumpfile("rangedec_top_wrapper_tb.vcd");
        $dumpvars(0, rangedec_top_wrapper_tb);
    end

endmodule
