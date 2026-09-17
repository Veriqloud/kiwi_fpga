`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer:
//
// Create Date: 09/15/2026
// Design Name: Qline_turnkey
// Module Name: pps_timebase
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: The only place the WRS PPS is sampled. Produces the one-second
//   epoch for both clock trees and the LTC6951 SYNC pulse.
//   Design note: docs/deterministic_latency.md
//
//   Tree A (clk10 and the clk_wiz outputs derived from it):
//   - PPS is sampled on the clk10 falling edge. The WRS aligns the PPS rising
//     edge with a 10 MHz rising edge, so the sample point is 50 ns from it.
//   - The first PPS rising edge after rst10 zeroes cnt10. From then on cnt10
//     free-runs and PPS is only checked against cnt10 == 0 (pps10_err_o).
//   - pps10_o is high for the first PPS10_HIGH clk10 cycles of each second. It
//     is clk10-synchronous, so clk240/clk80 logic captures it on a timed path.
//
//   LTC6951 SYNC (RAO = SN = 1):
//   - On the first second boundary with ltc_sync_req_i high, sync_ltc_o is
//     high for SYNC_HIGH clk10 cycles. It is launched on the falling edge, so
//     its falling edge is 50 ns from the REF rising edge that retimes it.
//   - SYNC_HIGH is a multiple of 16. 16 clk10 cycles are 5 SYSREF periods, so
//     the SYSREF phase relative to the second is the same in every second.
//   - ltc_synced_o is set when the pulse is complete. Taking ltc_sync_req_i low
//     clears it and allows the next pulse.
//
//   Tree B (tx_core_clk = LTC6951 OUT0, 200 MHz):
//   - arm_o rises at cnt10 == arm_cnt_i, in the first second that does not
//     contain a SYNC pulse, and drops when a SYNC pulse starts. SYSREF is
//     stopped and restarted by the pulse.
//   - arm_o crosses into clk200 on a 2-FF synchronizer. The first SYSREF rising
//     edge after it is clk200 cycle pps200_preset_i of the second; cnt200
//     free-runs from there.
//   - pps200_o is high for the first PPS200_HIGH clk200 cycles of each second,
//     from the first complete second on.
//   - Every SYSREF rising edge must come SYSREF_DIV cycles after the previous
//     one (sysref_err_o).
//   - arm_dist_o holds, from the last lock, the number of clk200 cycles from
//     arm to the chosen SYSREF edge. It is the margin of that choice: values
//     near 0 or SYSREF_DIV mean arm_cnt_i sits too close to a SYSREF edge.
//
//   sysref_i must already be registered in clk200. rst10 and ltc_sync_req_i are
//   clk10-synchronous. arm_cnt_i and pps200_preset_i are static configuration.
//
// Dependencies: none
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////


module pps_timebase #(
    parameter integer CLK10_PER_SEC  = 10000000,
    parameter integer PPS10_HIGH     = 1000000,     //100 ms
    parameter integer SYNC_HIGH      = 20000,       //2 ms, multiple of 16
    parameter integer CLK200_PER_SEC = 200000000,
    parameter integer PPS200_HIGH    = 20000000,    //100 ms
    parameter integer SYSREF_DIV     = 64           //clk200 cycles per SYSREF period
)(
    //tree A
    input  wire         clk10,
    input  wire         rst10,
    input  wire         pps_i,
    input  wire         ltc_sync_req_i,
    input  wire [7:0]   arm_cnt_i,
    output reg          pps10_o      = 1'b0,
    output reg          sync_ltc_o   = 1'b0,
    output reg          locked10_o   = 1'b0,
    output reg          pps10_err_o  = 1'b0,
    output reg          ltc_synced_o = 1'b0,
    output reg          arm_o        = 1'b0,
    //tree B
    input  wire         clk200,
    input  wire         sysref_i,
    input  wire [15:0]  pps200_preset_i,
    output reg          pps200_o     = 1'b0,
    output reg          locked200_o  = 1'b0,
    output reg          sysref_err_o = 1'b0,
    output reg  [7:0]   arm_dist_o   = 8'd0
);

localparam integer W10  = $clog2(CLK10_PER_SEC);
localparam integer WSY  = $clog2(SYNC_HIGH+1);
localparam integer W200 = $clog2(CLK200_PER_SEC);
localparam integer WSR  = $clog2(SYSREF_DIV);

//---------------------------------------------------------------------
//Tree A
//PPS sample point: clk10 falling edge, then onto the rising edge. pps_p_d
//starts high so a PPS that is already high at configuration is not an edge.
reg pps_n   = 1'b0;
reg pps_p   = 1'b1;
reg pps_p_d = 1'b1;
always @(negedge clk10) begin
    pps_n <= pps_i;
end
always @(posedge clk10) begin
    pps_p   <= pps_n;
    pps_p_d <= pps_p;
end
wire pps_rise = pps_p & ~pps_p_d;

//tick10 marks clk10 cycle 0 of a second
reg [W10-1:0] cnt10 = 0;
wire tick10 = locked10_o ? (cnt10 == 0) : pps_rise;

always @(posedge clk10) begin
    if (rst10) begin
        cnt10       <= 0;
        locked10_o  <= 1'b0;
        pps10_err_o <= 1'b0;
        pps10_o     <= 1'b0;
    end else begin
        if (tick10) begin
            cnt10      <= 1;
            locked10_o <= 1'b1;
        end else if (locked10_o) begin
            cnt10 <= (cnt10 == CLK10_PER_SEC-1) ? 0 : cnt10 + 1;
        end
        if (locked10_o && pps_rise && cnt10 != 0)
            pps10_err_o <= 1'b1;
        pps10_o <= tick10 | (locked10_o && cnt10 < PPS10_HIGH);
    end
end

//LTC6951 SYNC pulse and tree B arm
reg [WSY-1:0] sync_cnt = 0;
reg sync_run = 1'b0;
reg sync_p   = 1'b0;
reg holdoff  = 1'b0;
wire sync_start = tick10 && ltc_sync_req_i && !ltc_synced_o && !sync_run;

always @(posedge clk10) begin
    if (rst10) begin
        sync_cnt     <= 0;
        sync_run     <= 1'b0;
        sync_p       <= 1'b0;
        ltc_synced_o <= 1'b0;
        holdoff      <= 1'b0;
        arm_o        <= 1'b0;
    end else if (sync_start) begin
        sync_cnt <= 1;
        sync_run <= 1'b1;
        sync_p   <= 1'b1;
        holdoff  <= 1'b1;
        arm_o    <= 1'b0;
    end else begin
        if (sync_run) begin
            if (sync_cnt == SYNC_HIGH) begin
                sync_run     <= 1'b0;
                sync_p       <= 1'b0;
                ltc_synced_o <= 1'b1;
            end else begin
                sync_cnt <= sync_cnt + 1;
            end
        end else if (!ltc_sync_req_i) begin
            ltc_synced_o <= 1'b0;
        end
        //SYSREF restarts within the second of the pulse; arm from the next one
        if (holdoff && !sync_run && tick10)
            holdoff <= 1'b0;
        if (!holdoff && locked10_o && cnt10 == arm_cnt_i)
            arm_o <= 1'b1;
    end
end

always @(negedge clk10) begin
    sync_ltc_o <= sync_p;
end

//---------------------------------------------------------------------
//Tree B
(* ASYNC_REG = "TRUE" *) reg [1:0] arm_s = 2'b00;
reg            sysref_d  = 1'b1;
reg [W200-1:0] cnt200    = 0;
reg [WSR-1:0]  sysref_ph = 0;
reg            seen_wrap = 1'b0;
reg [7:0]      dist_cnt  = 8'd0;
wire sysref_rise = sysref_i & ~sysref_d;

always @(posedge clk200) begin
    arm_s    <= {arm_s[0], arm_o};
    sysref_d <= sysref_i;
    if (!arm_s[1]) begin
        cnt200       <= 0;
        sysref_ph    <= 0;
        seen_wrap    <= 1'b0;
        dist_cnt     <= 8'd0;
        locked200_o  <= 1'b0;
        sysref_err_o <= 1'b0;
        pps200_o     <= 1'b0;
    end else if (!locked200_o) begin
        if (dist_cnt != 8'hFF)
            dist_cnt <= dist_cnt + 1;
        if (sysref_rise) begin
            cnt200      <= pps200_preset_i + 1;
            sysref_ph   <= 1;
            locked200_o <= 1'b1;
            arm_dist_o  <= dist_cnt;
        end
    end else begin
        if (cnt200 == CLK200_PER_SEC-1) begin
            cnt200    <= 0;
            seen_wrap <= 1'b1;
        end else begin
            cnt200 <= cnt200 + 1;
        end
        sysref_ph <= (sysref_ph == SYSREF_DIV-1) ? 0 : sysref_ph + 1;
        if (sysref_rise && sysref_ph != 0)
            sysref_err_o <= 1'b1;
        pps200_o <= seen_wrap && (cnt200 < PPS200_HIGH);
    end
end

endmodule
