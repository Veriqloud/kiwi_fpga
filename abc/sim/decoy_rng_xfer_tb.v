`timescale 1ps / 1fs
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Design Name: Qline_turnkey
// Module Name: decoy_rng_xfer_tb
// Project Name: kiwiKD
// Description: rng_a crossing from clk200 to clk240 in decoy.v, with a scaled
//   second of 1600 symbols.
//   - pps10 is clk240-synchronous (launched from clk10 in the design), pps200 is
//     clk200-synchronous; +PH200=<ps> sets the refclk phase and +OFF200=<cycles>
//     moves pps200 earlier by that many clk200 cycles.
//   - rd_en_4 ticks start at the first pps200 edge, as in jesd_transport; the
//     rng value for each tick is a new pseudo-random 2-bit word.
//   - Symbols are numbered from the first PPS edge of each tree, independently
//     of the DUT's counters. Every rng_a_r update for clk240 symbol n must carry
//     the value of clk200 symbol n - 8.
//////////////////////////////////////////////////////////////////////////////////

module decoy_rng_xfer_tb;

localparam integer SYM_PER_SEC = 1600;
localparam integer PER240 = SYM_PER_SEC*6;
localparam integer PER200 = SYM_PER_SEC*5;
localparam real    T240   = 25000.0/6.0;
localparam real    T200   = 5000.0;
localparam integer LAG    = 8;

integer ph200  = 1300;
integer off200 = 0;

reg clk240 = 0, clk200 = 0, clk80 = 0;
reg decoy_rst = 1;
reg pps10 = 0, pps200 = 0;
reg rd_en_4 = 0;
reg [1:0] rng_value = 0;

initial begin
    if (!$value$plusargs("PH200=%d", ph200)) ph200 = 1300;
    if (!$value$plusargs("OFF200=%d", off200)) off200 = 0;
end

initial forever #(T240/2) clk240 = ~clk240;
initial forever #(T240*3) clk80  = ~clk80;
initial begin
    #1;
    #(ph200 - 1);
    forever #(T200/2) clk200 = ~clk200;
end

decoy #(.SIMULATION(1)) uut (
    .s_axil_awaddr(12'b0), .s_axil_awprot(3'b0), .s_axil_awvalid(1'b0), .s_axil_awready(),
    .s_axil_wdata(32'b0), .s_axil_wstrb(4'b0), .s_axil_wvalid(1'b0), .s_axil_wready(),
    .s_axil_bresp(), .s_axil_bvalid(), .s_axil_bready(1'b1),
    .s_axil_araddr(12'b0), .s_axil_arprot(3'b0), .s_axil_arvalid(1'b0), .s_axil_arready(),
    .s_axil_rdata(), .s_axil_rresp(), .s_axil_rvalid(), .s_axil_rready(1'b1),
    .s_axil_aclk(clk80), .s_axil_aresetn(1'b0),
    .clk240(clk240), .clk80(clk80), .clk200(clk200),
    .pps10_i(pps10), .pps200_i(pps200), .decoy_rst(decoy_rst),
    .rng_value(rng_value), .rd_en_4(rd_en_4),
    .decoy_signal_p(), .decoy_signal_n(), .rdec_p0_r()
);

//rng_a = rng_value (decoy_rng_mode = 1)
initial force uut.decoy_rng_mode_r = 1'b1;

//PPS for both trees
integer cnt240 = 0, cnt200 = 0;
always @(posedge clk240) begin
    cnt240 <= cnt240 + 1;
    pps10  <= (cnt240 % PER240) < PER240/10;
end
always @(posedge clk200) begin
    cnt200 <= cnt200 + 1;
    pps200 <= ((cnt200 + off200) % PER200) < PER200/10;
end

//rd_en_4 and rng_value, as jesd_transport and decoy_rng_fifos drive them
reg pps200_q = 1, started200 = 0;
integer tick_ph = 0;
integer sym200 = -1;
reg [1:0] hist [0:9999];
reg [15:0] lfsr = 16'hACE1;
always @(posedge clk200) begin
    pps200_q <= pps200;
    if (!decoy_rst && pps200 && !pps200_q) started200 <= 1;
    if (started200) begin
        tick_ph <= (tick_ph == 4) ? 0 : tick_ph + 1;
        rd_en_4 <= (tick_ph == 0);
    end
    if (rd_en_4) begin
        lfsr = {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
        rng_value <= lfsr[1:0];
    end
end
//clk200 symbol k: the k-th rng_a write strobe at or after the first pps200 edge
//the DUT sees; the value recorded is what rng_a holds at that strobe
reg pps200_d2 = 1, seen200 = 0;
always @(posedge clk200) begin
    pps200_d2 <= pps200;
    if (!decoy_rst && pps200 && !pps200_d2) seen200 = 1'b1;
    if (uut.rd_en_4_d[2] && seen200) begin
        sym200 = sym200 + 1;
        hist[sym200] = rng_value;
    end
end

//clk240 symbol n: the n-th rng_a_r update after the first pps10 edge the DUT sees
integer sym240 = -1;
integer errors = 0, checks = 0;
reg pps10_d2 = 1, seen10 = 0;
always @(posedge clk240) begin
    pps10_d2 <= pps10;
    if (!decoy_rst && pps10 && !pps10_d2) seen10 = 1'b1;
    if (uut.xfer_update && seen10) begin
        sym240 = sym240 + 1;
        if (sym240 >= LAG && sym240 - LAG <= sym200) begin
            checks = checks + 1;
            if (uut.rng_a_r !== hist[sym240 - LAG]) begin
                if (errors < 5)
                    $display("  *** FAIL: clk240 symbol %0d got %b, clk200 symbol %0d was %b",
                             sym240, uut.rng_a_r, sym240 - LAG, hist[sym240 - LAG]);
                errors = errors + 1;
            end
        end
    end
end

initial begin
    #(T240*PER240/2);
    decoy_rst = 0;
end
initial begin
    #(T240*PER240*3.5);
    $display("PH200 %0d ps, OFF200 %0d cycles: %0d checks, %0d errors", ph200, off200, checks, errors);
    if (errors == 0 && checks > 2*SYM_PER_SEC) $display("=== TB PASS ===");
    else                                      $display("=== TB FAIL ===");
    $finish;
end

endmodule
