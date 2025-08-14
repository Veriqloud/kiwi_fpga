`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2023 05:11:35 PM
// Design Name: 
// Module Name: sync_ltc_tb
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


module sync_ltc_tb(
    );
reg pps;
reg clk10;
reg rst;
reg sync_trigger;
wire sync_ltc;

sync_ltc sync_ltc_inst(.pps(pps),
    .clk10(clk10),
    .rst(rst),
    .sync_trigger(sync_trigger),
    .sync_ltc(sync_ltc));

initial begin
    clk10 = 0;
    rst = 0;
    pps = 0;
    sync_trigger = 0;
    #10 rst = 1;
    #130 sync_trigger = 1;
    #300 sync_trigger = 0;
end

always #100 begin
    #10 pps = 1;
    #40 pps = 0;
end
always #1 clk10 = ~clk10;

endmodule
