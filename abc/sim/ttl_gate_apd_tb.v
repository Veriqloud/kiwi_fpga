`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Design Name: Qline_turnkey
// Module Name: ttl_gate_apd_tb
// Project Name: kiwiKD
// Description: Check that the 12-bit gate pattern written to slv_reg6 comes out
//              of the OSERDESE3 on a 1.0417 ns grid, low bit first, repeating
//              every 12.5 ns. The gate is measured at the serializer output; the
//              ODELAY cascade downstream only adds tap delay and needs an
//              IDELAYCTRL to model.
//////////////////////////////////////////////////////////////////////////////////

module ttl_gate_apd_tb;

localparam T240 = 4167;   // ps, 240 MHz

reg clk240 = 0;
reg clk480 = 0;
reg axil_clk = 0;
reg axil_rstn = 0;
reg ttl_rst = 1;
reg pps_i = 0;

// clk480 and clk240 rise together at the start of every 240 MHz period
initial forever begin
    clk480 = 1; #(T240/4);
    clk480 = 0; #(T240/4);
end
initial forever begin
    clk240 = 1; #(T240/2);
    clk240 = 0; #(T240/2);
end
initial forever #(33333) axil_clk = ~axil_clk;   // 15 MHz

reg  [7:0]  awaddr = 0;
reg         awvalid = 0;
reg  [31:0] wdata = 0;
reg         wvalid = 0;
reg         bready = 1;
wire        awready, wready, bvalid;

ttl_gate_apd dut (
    .s_axil_awaddr(awaddr), .s_axil_awprot(3'b0), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
    .s_axil_wdata(wdata), .s_axil_wstrb(4'hF), .s_axil_wvalid(wvalid), .s_axil_wready(wready),
    .s_axil_bresp(), .s_axil_bvalid(bvalid), .s_axil_bready(bready),
    .s_axil_araddr(8'b0), .s_axil_arprot(3'b0), .s_axil_arvalid(1'b0), .s_axil_arready(),
    .s_axil_rdata(), .s_axil_rresp(), .s_axil_rvalid(), .s_axil_rready(1'b0),
    .s_axil_aclk(axil_clk), .s_axil_aresetn(axil_rstn),
    .clk240(clk240), .clk480(clk480), .ttl_rst(ttl_rst), .pps_i(pps_i),
    .pulse_p(), .pulse_n(), .pulse_rep_p(), .pulse_rep_n()
);

task axil_write(input [7:0] addr, input [31:0] data);
begin
    @(posedge axil_clk);
    awaddr <= addr; wdata <= data; awvalid <= 1'b1; wvalid <= 1'b1;
    @(posedge axil_clk);
    while (!(awready && wready)) @(posedge axil_clk);
    awvalid <= 1'b0; wvalid <= 1'b0;
    @(posedge axil_clk);
    while (!bvalid) @(posedge axil_clk);
    @(posedge axil_clk);
end
endtask

real    rise_t, fall_t, width_ns;
integer errors = 0;

task check_pattern(input [11:0] pat, input real exp_width_ns);
begin
    axil_write(8'h18, {20'b0, pat});    // slv_reg6: gate pattern
    axil_write(8'h08, 32'h0);           // slv_reg2: params_en low
    axil_write(8'h08, 32'h1);           // rising edge latches the pattern into clk240
    repeat (20) @(posedge clk240);

    @(posedge dut.pulse_delay_tune); rise_t = $realtime;
    @(negedge dut.pulse_delay_tune); fall_t = $realtime;
    width_ns = (fall_t - rise_t)/1000.0;

    $display("pattern %012b -> width %0.3f ns (expected %0.3f ns)", pat, width_ns, exp_width_ns);
    if (width_ns < exp_width_ns - 0.15 || width_ns > exp_width_ns + 0.15) begin
        $display("  *** FAIL: width %0.3f ns, expected %0.3f ns", width_ns, exp_width_ns);
        errors = errors + 1;
    end
end
endtask

// PPS-to-gate latency: the serializer pipeline sets the gate's absolute
// position relative to the PPS edge, so this is the offset the tune delay has
// to work from.
real pps_t, first_edge_t;
task check_latency(input [11:0] pat);
begin
    axil_write(8'h18, {20'b0, pat});
    axil_write(8'h08, 32'h0);
    axil_write(8'h08, 32'h1);
    repeat (20) @(posedge clk240);
    @(posedge clk240);
    pps_i = 1'b1; pps_t = $realtime;      // sticky trigger, starts the pattern
    @(posedge dut.pulse_delay_tune); first_edge_t = $realtime;
    $display("pps -> first gate edge: %0.3f ns (pattern %012b)",
             (first_edge_t - pps_t)/1000.0, pat);
end
endtask

real p1, p2;
task check_period;
begin
    @(posedge dut.pulse_delay_tune); p1 = $realtime;
    @(posedge dut.pulse_delay_tune); p2 = $realtime;
    $display("gate period %0.3f ns (expected 12.500 ns)", (p2-p1)/1000.0);
    if ((p2-p1) < 12350 || (p2-p1) > 12650) begin
        $display("  *** FAIL: period %0.3f ns", (p2-p1)/1000.0);
        errors = errors + 1;
    end
end
endtask

initial begin
    #200000;
    axil_rstn = 1;
    #100000;
    ttl_rst = 0;
    #100000;

    // absolute offset of the gate from the PPS edge
    check_latency(12'b000000000010);

    // one bit set -> 1.0417 ns gate: the resolution this change is for
    check_pattern(12'b000000000010, 1.0417);
    // two adjacent bits -> 2.0833 ns
    check_pattern(12'b000000000110, 2.0833);
    // three bits -> 3.125 ns, three quarters of one 240 MHz cycle
    check_pattern(12'b000000001110, 3.1250);
    // five bits -> 5.2083 ns, a width the counter could not express
    check_pattern(12'b000000111110, 5.2083);
    // four bits = one full 240 MHz cycle
    check_pattern(12'b000000001111, 4.1667);
    // same run shifted by two bits: 2.0833 ns of tune delay, same width
    check_pattern(12'b000000111100, 4.1667);
    check_period;

    if (errors == 0) $display("=== TB PASS ===");
    else             $display("=== TB FAIL: %0d error(s) ===", errors);
    $finish;
end

initial begin
    #20000000;
    $display("=== TB TIMEOUT ===");
    $finish;
end

endmodule
