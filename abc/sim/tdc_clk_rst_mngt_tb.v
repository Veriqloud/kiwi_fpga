`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Design Name: Qline_turnkey
// Module Name: tdc_clk_rst_mngt_tb
// Project Name: kiwiKD
// Description: tdc_clk_rst_mngt with a scaled second (PER clk200 cycles, pps200
//   high for HIGH cycles). Checks:
//   - tdc_refclk_o and tdc_rstidx_o equal, cycle by cycle, a combinational
//     decode of reference counters started on the same pps200 edge
//   - refclk: 40-cycle period, 20 cycles high; rstidx: 6 cycles high every 320,
//     3 cycles either side of a refclk rising edge
//   - tdc_rst released while pps200 is high: no output until the next rising
//     edge
//   - rstidx_phase_o: valid with phase 0 in steady state, phase 7 after the
//     pps200 edge moves 7 cycles late, 0 again after it moves back
//////////////////////////////////////////////////////////////////////////////////

module tdc_clk_rst_mngt_tb;

localparam integer PER  = 3200;     // multiple of 320
localparam integer HIGH = 320;

reg clk = 0;
always #2.5 clk = ~clk;

reg tdc_rst = 0;
initial #1 tdc_rst = 1;
reg pps = 0;
integer pcnt = 0;
integer per = PER;

always @(posedge clk) begin
    pcnt <= (pcnt >= per-1) ? 0 : pcnt + 1;
    pps  <= (pcnt < HIGH);
end

wire refclk, rstidx, trig, stopa_sim;
wire [9:0] phase;

tdc_clk_rst_mngt dut (
    .clk200_i(clk),
    .tdc_rst(tdc_rst),
    .pps200_i(pps),
    .tdc_refclk_o(refclk),
    .tdc_rstidx_o(rstidx),
    .rstidx_phase_o(phase),
    .stopa_sim_limit_i(32'd0),
    .stopa_sim_enable_i(1'b0),
    .pps_trigger(trig),
    .stopa_sim(stopa_sim)
);

//Reference: counters and combinational decode
reg m_trig = 0, m_ppsr = 1;
reg [7:0] m_ct = 0;
reg [8:0] m_cr = 0;
always @(posedge clk, posedge tdc_rst) begin
    if (tdc_rst) begin
        m_trig <= 0; m_ppsr <= 1; m_ct <= 0; m_cr <= 0;
    end else begin
        m_ppsr <= pps;
        if (!m_ppsr && pps) m_trig <= 1;
        if (m_trig) begin
            m_ct <= (m_ct >= 39) ? 0 : m_ct + 1;
            m_cr <= (m_cr >= 319) ? 0 : m_cr + 1;
        end else begin
            m_ct <= 0; m_cr <= 0;
        end
    end
end
wire m_refclk = m_trig && (m_ct <= 19);
wire m_rstidx = m_trig && ((m_cr <= 2) || (m_cr >= 317));

integer errors = 0;
integer mismatches = 0;
always @(negedge clk) begin
    if ($time > 10 && (refclk !== m_refclk || rstidx !== m_rstidx)) begin
        if (mismatches < 5)
            $display("ERROR %0t: refclk %b/%b rstidx %b/%b", $time, refclk, m_refclk, rstidx, m_rstidx);
        mismatches = mismatches + 1;
    end
end

//Waveform checks
integer cyc = 0;
//first rstidx pulse after a start is cycles 0..2 only
integer last_rise = -1, rst_rise = -1;
reg first_rstidx = 1;
reg refclk_d = 0, rstidx_d = 0;
always @(posedge clk) begin
    cyc = cyc + 1;
    if (tdc_rst) begin
        last_rise = -1;
        first_rstidx = 1;
    end
    refclk_d <= refclk;
    rstidx_d <= rstidx;
    if (refclk && !refclk_d) begin
        if (last_rise >= 0 && cyc - last_rise != 40) begin
            $display("ERROR %0t: refclk period %0d", $time, cyc - last_rise); errors = errors + 1;
        end
        last_rise = cyc;
    end
    if (!refclk && refclk_d) begin
        if (last_rise >= 0 && cyc - last_rise != 20) begin
            $display("ERROR %0t: refclk high %0d", $time, cyc - last_rise); errors = errors + 1;
        end
    end
    if (rstidx && !rstidx_d) rst_rise = cyc;
    if (!rstidx && rstidx_d) begin
        if (first_rstidx)
            first_rstidx = 0;
        else if (cyc - rst_rise != 6 || last_rise - rst_rise != 3) begin
            $display("ERROR %0t: rstidx high %0d, refclk rise at +%0d", $time, cyc - rst_rise, last_rise - rst_rise);
            errors = errors + 1;
        end
    end
end

task wait_pps_rise;
    begin
        @(posedge clk); while (!(pps === 1'b0)) @(posedge clk);
        while (!(pps === 1'b1)) @(posedge clk);
    end
endtask

task check_phase(input valid, input [8:0] value, input [8*24-1:0] what);
    begin
        if (phase[9] !== valid || (valid && phase[8:0] !== value)) begin
            $display("ERROR %0s: rstidx_phase valid %b phase %0d, expected %b %0d", what, phase[9], phase[8:0], valid, value);
            errors = errors + 1;
        end else
            $display("ok    %0s: rstidx_phase valid %b phase %0d", what, phase[9], phase[8:0]);
    end
endtask

initial begin
    //1. release while pps200 low, start on the next edge
    repeat (HIGH + 50) @(posedge clk);
    tdc_rst <= 0;
    wait_pps_rise;
    repeat (3) @(posedge clk);
    if (!trig) begin $display("ERROR: no start on pps200 edge"); errors = errors + 1; end
    check_phase(0, 0, "first edge");
    wait_pps_rise; repeat (3) @(posedge clk);
    check_phase(1, 0, "steady state");

    //2. release in the middle of the pps200 high window
    wait_pps_rise; repeat (100) @(posedge clk);
    tdc_rst <= 1; @(posedge clk); tdc_rst <= 0;
    repeat (50) @(posedge clk);
    if (trig || refclk || rstidx) begin
        $display("ERROR: started on tdc_rst release inside the pps200 high window"); errors = errors + 1;
    end else
        $display("ok    release inside high window: not started");
    wait_pps_rise; repeat (3) @(posedge clk);
    if (!trig) begin $display("ERROR: no start after release"); errors = errors + 1; end
    wait_pps_rise; repeat (3) @(posedge clk);
    check_phase(1, 0, "after re-release");

    //3. pps200 edge 7 cycles late, then back on the grid
    per = PER + 7;
    wait_pps_rise;
    per = PER;
    repeat (3) @(posedge clk);
    check_phase(1, 7, "edge 7 cycles late");
    per = PER - 7;
    wait_pps_rise;
    per = PER;
    repeat (3) @(posedge clk);
    check_phase(1, 0, "edge back on grid");

    repeat (PER) @(posedge clk);
    errors = errors + mismatches;
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d errors", errors);
    $finish;
end

endmodule
