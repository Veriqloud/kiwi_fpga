`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Design Name: Qline_turnkey
// Module Name: pps_timebase_tb
// Project Name: kiwiKD
// Description: pps_timebase with a scaled second (1600 clk10 cycles) and a
//   behavioural LTC6951 in RAO = SN = 1 mode:
//   - refclk rising edges on the REF (clk10) grid, shifted by ph200 at the FPGA
//   - SYSREF stopped while SYNC is high; on the first REF rising edge that sees
//     SYNC low it restarts 1 N cycle + (18 + DLY3) P cycles later
//   Each run is a power cycle with a new PPS-to-10 MHz skew, a new refclk phase
//   relative to clk10 and SYSREF free-running at a new phase before the SYNC,
//   followed by the Sync_Ltc() register sequence. Checks:
//   - pps10 and pps200 rise at the same place in the second in every run
//   - SYNC width and launch edge
//   - arm_dist and lock flags, no errors in steady state
//   - pps10_err when PPS moves one clk10 cycle, sysref_err when SYSREF moves one
//     refclk cycle
//////////////////////////////////////////////////////////////////////////////////

module pps_timebase_tb;

localparam integer PER10     = 1600;          // clk10 cycles per scaled second
localparam integer T10       = 100000;        // ps
localparam integer T200      = 5000;
localparam integer TP        = 625;           // LTC6951 P cycle, VCO 4.8 GHz / P = 3
localparam integer TSYSREF   = 320000;
localparam integer DLY3      = 2;
localparam integer SYNC_HIGH = 32;
localparam integer ARM_CNT   = 16;
localparam integer PRESET    = 364;
localparam time    SEC       = PER10*T10;

reg clk10  = 1;             // rising edges at k*T10
reg clk200 = 0;
reg pps    = 0;
reg rst10  = 1;
reg ltc_sync_req = 0;

time ph200   = 1300;        // refclk phase at the FPGA relative to clk10
time pps_off = T10;         // PPS rising edge = k*SEC + pps_off

always #(T10/2) clk10 = ~clk10;

time t_now, t_next;
initial begin
    forever begin
        t_now  = $time;
        t_next = ((t_now + T200 - ph200) / T200) * T200 + ph200;
        #(t_next - t_now) clk200 = 1'b1;
        #(T200/2)         clk200 = 1'b0;
    end
end

time p_now, p_next;
initial begin
    forever begin
        p_now  = $time;
        p_next = ((p_now + SEC - pps_off) / SEC) * SEC + pps_off;
        #(p_next - p_now) pps = 1'b1;
        #(SEC/10)         pps = 1'b0;
    end
end

wire pps10, sync_ltc, locked10, pps10_err, ltc_synced, arm;
wire pps200, locked200, sysref_err;
wire [7:0] arm_dist;

//LTC6951 SYSREF (OUT3) as seen at the FPGA pin
reg  sysref_stopped = 0;
time sysref_t0 = 0;
always @(posedge clk10) begin
    if (sync_ltc)
        sysref_stopped <= 1'b1;
    else if (sysref_stopped) begin
        sysref_stopped <= 1'b0;
        sysref_t0      = $time + T10 + (18+DLY3)*TP + ph200;
    end
end
function sysref_level(input time t);
    if (sysref_stopped || t < sysref_t0) sysref_level = 1'b0;
    else sysref_level = ((t - sysref_t0) % TSYSREF) < TSYSREF/2;
endfunction

//capture flop, as in clk_rst_mngt
reg sysref_q = 0;
always @(posedge clk200) sysref_q <= sysref_level($time);

pps_timebase #(
    .CLK10_PER_SEC(PER10), .PPS10_HIGH(PER10/10), .SYNC_HIGH(SYNC_HIGH),
    .CLK200_PER_SEC(PER10*20), .PPS200_HIGH(PER10*2), .SYSREF_DIV(64)
) dut (
    .clk10(clk10), .rst10(rst10), .pps_i(pps), .ltc_sync_req_i(ltc_sync_req),
    .arm_cnt_i(ARM_CNT[7:0]),
    .pps10_o(pps10), .sync_ltc_o(sync_ltc), .locked10_o(locked10), .pps10_err_o(pps10_err),
    .ltc_synced_o(ltc_synced), .arm_o(arm),
    .clk200(clk200), .sysref_i(sysref_q), .pps200_preset_i(PRESET[15:0]),
    .pps200_o(pps200), .locked200_o(locked200), .sysref_err_o(sysref_err), .arm_dist_o(arm_dist)
);

integer errors = 0;

time last_pps10_rise, last_pps200_rise, sync_rise, sync_fall;
reg  saw_ltc_synced = 0;
always @(posedge ltc_synced) saw_ltc_synced = 1'b1;
always @(posedge pps10)    last_pps10_rise  = $time;
always @(posedge pps200)   last_pps200_rise = $time;
always @(posedge sync_ltc) sync_rise = $time;
always @(negedge sync_ltc) sync_fall = $time;

time ref_pos10, ref_pos200;
integer ref_arm_dist;
reg  have_ref = 0;

task wait_sec(input real n);
    #(n*SEC);
endtask

//Sync_Ltc(): reset sync counter, 0.1 s, sync trigger, 1.2 s, clear
task power_cycle(input integer skew_ps, input time phase, input time sysref_phase);
    time pos10, pos200;
begin
    rst10 = 1'b1;
    ltc_sync_req = 1'b0;
    saw_ltc_synced = 1'b0;
    pps_off = T10 + skew_ps;
    ph200 = phase;
    sysref_stopped = 1'b0;
    sysref_t0 = sysref_phase;
    wait_sec(1.3);
    @(posedge clk10); rst10 = 1'b0;
    wait_sec(0.1);
    @(posedge clk10); ltc_sync_req = 1'b1;
    wait_sec(1.2);
    @(posedge clk10); ltc_sync_req = 1'b0;
    wait_sec(2.05);

    pos10  = last_pps10_rise % SEC;
    pos200 = (last_pps200_rise - ph200) % SEC;
    $display("run skew %0d ps, refclk phase %0d ps: pps10 at %0d ps, pps200 at %0d ps + phase, arm_dist %0d, sync %0d ps wide",
             skew_ps, phase, pos10, pos200, arm_dist, sync_fall - sync_rise);

    if (!locked10 || !locked200 || !saw_ltc_synced || ltc_synced || pps10_err || sysref_err) begin
        $display("  *** FAIL: locked10 %b locked200 %b ltc_synced seen %b now %b pps10_err %b sysref_err %b",
                 locked10, locked200, saw_ltc_synced, ltc_synced, pps10_err, sysref_err);
        errors = errors + 1;
    end
    if (sync_fall - sync_rise != SYNC_HIGH*T10 || (sync_rise % T10) != T10/2) begin
        $display("  *** FAIL: SYNC rise %0d ps into the clk10 cycle, %0d ps wide", sync_rise % T10, sync_fall - sync_rise);
        errors = errors + 1;
    end
    if (last_pps200_rise + SEC < $time || last_pps10_rise + SEC < $time) begin
        $display("  *** FAIL: pps10 or pps200 not running");
        errors = errors + 1;
    end
    if (!have_ref) begin
        ref_pos10 = pos10; ref_pos200 = pos200; ref_arm_dist = arm_dist; have_ref = 1'b1;
    end else if (pos10 != ref_pos10 || pos200 != ref_pos200 || arm_dist != ref_arm_dist) begin
        $display("  *** FAIL: differs from the first run (pps10 %0d, pps200 %0d, arm_dist %0d)",
                 ref_pos10, ref_pos200, ref_arm_dist);
        errors = errors + 1;
    end
end
endtask

initial begin
    power_cycle(     0, 1300,  17000);
    power_cycle(-40000, 4700, 211000);
    power_cycle( 40000,  100,  95000);
    power_cycle(-12000, 2500,  33000);
    power_cycle( 25000, 3900, 301000);

    $display("pps200 - pps10 = %0d ps (+ refclk phase)", ref_pos200 - ref_pos10);
    if (ref_arm_dist < 16 || ref_arm_dist > 48) begin
        $display("  *** FAIL: arm_dist %0d leaves less than 16 cycles of margin", ref_arm_dist);
        errors = errors + 1;
    end

    //SYSREF moves by one refclk cycle without a SYNC
    sysref_t0 = sysref_t0 + T200;
    wait_sec(0.01);
    if (!sysref_err) begin
        $display("  *** FAIL: sysref_err not set after SYSREF moved");
        errors = errors + 1;
    end else $display("sysref_err set after SYSREF moved by one refclk cycle");

    //PPS moves by one clk10 cycle; the generator applies it from the rise after next
    pps_off = pps_off + T10;
    wait_sec(2.2);
    if (!pps10_err) begin
        $display("  *** FAIL: pps10_err not set after PPS moved");
        errors = errors + 1;
    end else $display("pps10_err set after PPS moved by one clk10 cycle");

    if (errors == 0) $display("=== TB PASS ===");
    else             $display("=== TB FAIL: %0d error(s) ===", errors);
    $finish;
end

endmodule
