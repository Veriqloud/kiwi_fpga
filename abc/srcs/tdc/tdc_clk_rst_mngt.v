`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 02/02/2024 03:33:49 PM
// Design Name: Qline_turnkey
// Module Name: tdc_clk_rst_mngt
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Generate reference clock, reset index, simulated stopa for tdc
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Add comments for AI review. No functional change.
// Revision 0.03 - PPS edge detect cannot fire on tdc_rst release; registered
//                 tdc_refclk_o/tdc_rstidx_o; rstidx_phase_o readback.
// Additional Comments:
//   pps200_i is synchronous to clk200_i (pps_timebase), so the edge detect needs
//   one flop. pps_r resets to 1: a reset released while pps200_i is high waits
//   for the next rising edge.
//
//   tdc_refclk_o and tdc_rstidx_o come straight from flops, decoded from the
//   next counter state, so they are glitch-free and have the same clk200 cycle
//   timing as a decode of the current counter state.
//
//   rstidx_phase_o = {valid, phase}. On every pps200_i rising edge after the
//   counters started, phase latches the counter_rstidx value of the next cycle:
//   the number of clk200 cycles since the counters started, mod 320. It reads 0
//   when they started on a pps200_i edge. valid clears on tdc_rst.
//
//////////////////////////////////////////////////////////////////////////////////


module tdc_clk_rst_mngt #(
    parameter N_TDC_REFCLK = 8,
    parameter TDC_DIV_HALF = 20, //Fix for 5MHz tdc_refclk from 200MHz clk200_i
    parameter N_COUNTER_APD = 800
)
(
    input           clk200_i,
    input           tdc_rst,
    input           pps200_i,
    output reg      tdc_refclk_o,
    output reg      tdc_rstidx_o,
    output [9:0]    rstidx_phase_o,
    input [31:0]    stopa_sim_limit_i,
    input           stopa_sim_enable_i,
    //Debug ports
    output          pps_trigger,
    output          stopa_sim
);

localparam integer N_REFCLK_CYCLE = TDC_DIV_HALF*2;
localparam integer N_RSTIDX_CYCLE = N_REFCLK_CYCLE*N_TDC_REFCLK;

// Generate pps_trigger signal
reg pps_trigger;
reg pps_r;
wire pps_rise = !pps_r && pps200_i;
wire pps_trigger_nxt = pps_trigger | pps_rise;

always @(posedge clk200_i, posedge tdc_rst) begin
    if (tdc_rst) begin
        pps_trigger <= 1'b0;
        pps_r <= 1'b1;
    end else begin
        pps_r <= pps200_i;
        pps_trigger <= pps_trigger_nxt;
    end
end

//counter to get 5MHz tdc_refclk from 200MHz, aligned to pps by using pps_trigger
reg [7:0] counter_tdc;
reg [$clog2(N_RSTIDX_CYCLE)-1:0] counter_rstidx;

wire [7:0] counter_tdc_nxt = !pps_trigger ? 0 :
                             (counter_tdc >= N_REFCLK_CYCLE-1) ? 0 : counter_tdc + 1;
wire [$clog2(N_RSTIDX_CYCLE)-1:0] counter_rstidx_nxt = !pps_trigger ? 0 :
                             (counter_rstidx >= N_RSTIDX_CYCLE-1) ? 0 : counter_rstidx + 1;

always @(posedge clk200_i, posedge tdc_rst) begin
    if (tdc_rst) begin
        counter_tdc <= 0;
        counter_rstidx <= 0;
        tdc_refclk_o <= 1'b0;
        tdc_rstidx_o <= 1'b0;
    end else begin
        counter_tdc <= counter_tdc_nxt;
        counter_rstidx <= counter_rstidx_nxt;
        //high for counter_tdc 0..TDC_DIV_HALF-1
        tdc_refclk_o <= pps_trigger_nxt && (counter_tdc_nxt <= TDC_DIV_HALF-1);
        //high for counter_rstidx N_RSTIDX_CYCLE-3..2, around a tdc_refclk_o rising edge
        tdc_rstidx_o <= pps_trigger_nxt && ((counter_rstidx_nxt <= 2) ||
                                            (counter_rstidx_nxt >= N_RSTIDX_CYCLE-3));
    end
end

//Counter phase at the pps200_i edge
reg [$clog2(N_RSTIDX_CYCLE)-1:0] rstidx_phase;
reg rstidx_phase_valid;
assign rstidx_phase_o = {rstidx_phase_valid, rstidx_phase};

always @(posedge clk200_i, posedge tdc_rst) begin
    if (tdc_rst) begin
        rstidx_phase <= 0;
        rstidx_phase_valid <= 1'b0;
    end else if (pps_rise && pps_trigger) begin
        rstidx_phase <= counter_rstidx_nxt;
        rstidx_phase_valid <= 1'b1;
    end
end


//Get register values
reg [17:0] counter_apd_sim;
wire stopa_sim;

(* ASYNC_REG = "TRUE" *) reg [2:0] sim_enable_r;
reg [31:0] stopa_sim_limit;
initial begin
    sim_enable_r <= 0;
    stopa_sim_limit <= 0;
end
always @(posedge clk200_i) begin
    sim_enable_r <= {sim_enable_r[1:0],stopa_sim_enable_i};
    if (sim_enable_r[2] == 0 && sim_enable_r[1] == 1) begin
        stopa_sim_limit <= stopa_sim_limit_i;
    end
end

//Generate simulated stopa signal
wire [15:0] limit_high;
wire [7:0] limit_low;
wire [7:0] divide_stopa;
assign limit_high = stopa_sim_limit[31:16];
assign limit_low = stopa_sim_limit[15:8];
assign divide_stopa = stopa_sim_limit[7:0];
assign stopa_sim = ((counter_apd_sim >= limit_low && counter_apd_sim <= limit_high) && pps_trigger) ?1:0;
always @(posedge clk200_i, posedge tdc_rst) begin
    if (tdc_rst) begin
        counter_apd_sim <= 0;
    end else begin
        if (pps_trigger) begin
            counter_apd_sim <= counter_apd_sim + 1;
            if (counter_apd_sim >= N_COUNTER_APD*divide_stopa-1) begin
                counter_apd_sim <= 0;
            end
        end
    end
end

endmodule
