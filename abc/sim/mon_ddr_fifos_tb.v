`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2024 06:17:24 PM
// Design Name: 
// Module Name: mon_ddr_fifos_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mon_ddr_fifos_tb();
    reg clk200_i;
    reg ddr_data_rstn;
    reg clk250_i;
    reg aresetn;
    reg clk15;
    reg aresetn_15;
    reg [1:0] vfifo_idle;
    reg [1:0] vfifo_full;
    reg [1:0] vfifo_empty;
    reg gc_out_fifo_full;
    reg gc_out_fifo_empty;
    reg gc_in_fifo_full;
    reg gc_in_fifo_empty;
    reg alpha_out_fifo_full;
    reg alpha_out_fifo_empty;

    wire [8:0] status_200_o;
    wire status_200_valid_o;
    wire [2:0] status_250_o;
    wire status_250_valid_o;

mon_ddr_fifos mon_ddr_fifos_inst(
    .clk200_i(clk200_i),
    .ddr_data_rstn(ddr_data_rstn),
    .clk250_i(clk250_i),
    .aresetn(aresetn),
    .clk15(clk15),
    .aresetn_15(aresetn_15),
    .vfifo_idle(vfifo_idle),
    .vfifo_full(vfifo_full),
    .vfifo_empty(vfifo_empty),
    .gc_out_fifo_full(gc_out_fifo_full),
    .gc_out_fifo_empty(gc_out_fifo_empty),
    .gc_in_fifo_full(gc_in_fifo_full),
    .gc_in_fifo_empty(gc_in_fifo_empty),
    .alpha_out_fifo_full(alpha_out_fifo_full),
    .alpha_out_fifo_empty(alpha_out_fifo_empty),
    .status_200_o(status_200_o),
    .status_200_valid_o(status_200_valid_o),
    .status_250_o(status_250_o),
    .status_250_valid_o(status_250_valid_o)
    );

initial begin
    clk200_i = 0;
    clk250_i = 0;
    clk15 = 0;
end

always #2.5 clk200_i = ~clk200_i;
always #2 clk250_i = ~clk250_i;
always #33.33 clk15 = ~clk15;

initial begin
    ddr_data_rstn = 0;
    aresetn = 0;
    aresetn_15 = 0;
    #24 aresetn = 1;
    #33.33 aresetn_15 = 1;
    #100 ddr_data_rstn = 1;
end

initial begin
    vfifo_idle = 1;
    vfifo_full = 0;
    vfifo_empty = 1;
    gc_out_fifo_full = 1;
    gc_out_fifo_empty = 1;
    gc_in_fifo_full = 0;
    gc_in_fifo_empty = 1;
    alpha_out_fifo_full = 1;
    alpha_out_fifo_empty = 1;
end

always @(clk200_i) begin
    vfifo_idle = $random;
    vfifo_full = $random;
    vfifo_empty = $random;
end
always @(clk250_i) begin
    gc_out_fifo_empty = $random;
    gc_in_fifo_full = $random;
    alpha_out_fifo_empty = $random;    
end
endmodule
