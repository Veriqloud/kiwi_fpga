`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 02/02/2024 03:33:49 PM
// Design Name: 
// Module Name: tdc_clk_rst_mngt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generate reference clock, reset index, simulated stopa for tdc
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tdc_clk_rst_mngt #(
    parameter N_TDC_REFCLK = 8,
    parameter TDC_DIV_HALF = 20,
    parameter N_COUNTER_APD = 800
    )
    (
    input clk200_i,
    input tdc_rst,
    input pps_i,
    output tdc_refclk_o,
    output tdc_rstidx_o,
    input [31:0] stopa_sim_limit_i,
    input stopa_sim_enable_i,
    //Debug ports
    output pps_trigger,
    output stopa_sim

    );

// Generate pps_trigger signal
reg pps_trigger;
reg pps_r;

always @(posedge clk200_i, posedge tdc_rst) begin
    if (tdc_rst) begin
        pps_trigger <= 1'b0;
        pps_r <= 0;
    end else begin
        pps_r <= pps_i;
        if (!pps_r && pps_i) begin
            pps_trigger <= 1'b1;
        end
    end
end


//counter to get 5MHz tdc_refclk from 200MHz, aligned to pps by using pps_trigger
reg [7:0] counter_tdc;
wire tdc_refclk_o;

reg [$clog2((TDC_DIV_HALF*2)*N_TDC_REFCLK)-1:0] counter_rstidx;
wire tdc_rstidx_o;


assign tdc_refclk_o = (counter_tdc >= 0 && counter_tdc <= (TDC_DIV_HALF-1) && pps_trigger) ?1:0;
assign tdc_rstidx_o = ((counter_rstidx >=0 && counter_rstidx <=2) | (counter_rstidx >= ((TDC_DIV_HALF*2)*N_TDC_REFCLK -3) && counter_rstidx <= ((TDC_DIV_HALF*2)*N_TDC_REFCLK -1)) && pps_trigger ) ?1:0;

always @(posedge clk200_i, posedge tdc_rst) begin
    if (tdc_rst) begin
        counter_tdc <= 0;
        counter_rstidx <= 0;
    end else begin
        if (pps_trigger) begin
            counter_tdc <= counter_tdc + 1;
            if (counter_tdc >= (TDC_DIV_HALF*2-1)) begin
                counter_tdc <= 0;
            end
            counter_rstidx <= counter_rstidx + 1;
            if (counter_rstidx >= ((TDC_DIV_HALF*2)*N_TDC_REFCLK-1)) begin
                counter_rstidx <= 0;
            end
        end else begin
            counter_tdc <= 0;
            counter_rstidx <= 0;
        end
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
