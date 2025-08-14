`timescale 100 ps / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2024 03:25:53 PM
// Design Name: 
// Module Name: led_test_tb
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


module led_test_tb();
    reg pps;
    reg clk10;
    reg clk100;
    reg clk200;
    reg clk3125;
    reg syncout;
    reg sys_reset_n;
    reg tdc_rst;
    reg tdc_pps_trigger_i;
    reg clockchip_sync;
    wire syncout_o;
    wire [3:0] led;
    wire [1:0] sig;
    wire sig3125;
    wire sig_80;
led_test led_test_inst(.clk10(clk10),
    .pps(pps),
    .clk100(clk100),
    .clk200(clk200),
    .clk3125(clk3125),
    .syncout(syncout),
    .syncout_o(syncout_o),
    .sys_reset_n(sys_reset_n),
    .tdc_rst(tdc_rst),
    .tdc_pps_trigger_i(tdc_pps_trigger_i),
    .clockchip_sync(clockchip_sync),
    .led(led),
    .sig(sig),
    .sig3125(sig3125));
initial begin
    pps = 0;
    clk10 = 0;
    clk100 = 0;
    clk200 = 1;
    clk3125 = 0;
    syncout = 0;
    sys_reset_n = 0;
    tdc_rst = 1;
    tdc_pps_trigger_i = 0;
    #100 sys_reset_n = 1;
    #100 tdc_rst = 0;
    #10000000 pps = 1;
    #12000000 tdc_pps_trigger_i = 1;
    #36000000 tdc_pps_trigger_i = 0;
end

initial begin
    #900000 pps = 1;
    forever begin
        #1000000 pps = 0;
        #9000000 pps = 1;
    end
end


always #2.5 clk200 = ~clk200; //25 ~ 2.5ns
always #50 clk10 = ~clk10;

initial begin
    clockchip_sync = 0;
    #1500000 clockchip_sync = 1;
    #30000000 clockchip_sync = 0;
end

endmodule
