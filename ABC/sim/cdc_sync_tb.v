`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2024 12:09:56 PM
// Design Name: 
// Module Name: cdc_sync_tb
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


module cdc_sync_tb();
    reg clk_fast;
    reg clk_slow;
    reg command_en;
    reg rstn_fast;
    reg rstn_slow;

cdc_sync cdc_sync_inst(
    .clk_fast(clk_fast),
    .clk_slow(clk_slow),
    .command_en(command_en),
    .rstn_fast(rstn_fast),
    .rstn_slow(rstn_slow)
    );

initial begin
    clk_fast = 0;
    clk_slow = 0;
    rstn_fast = 0;
    #5 rstn_fast = 1;
    rstn_slow = 0;
    #99 rstn_slow = 1;
end

always #2.5 clk_fast = ~clk_fast;
always #33.33 clk_slow = ~clk_slow;

initial begin
    command_en = 0;
    #213 command_en = 1;
    #400 command_en = 0;
    #2015 command_en = 1;
end
endmodule
