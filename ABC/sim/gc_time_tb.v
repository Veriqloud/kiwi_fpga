`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2024 04:00:58 PM
// Design Name: 
// Module Name: gc_time_tb
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


module gc_time_tb();
    reg tdc_refclck;
    reg tdc_rst;
    reg clk80;
    reg pps_trigger;
    reg start_gc;
    reg [31:0] tdc_digital_data;
    // wire  [31:0] value;
    wire stop_sim_o;

    gc_time gc_time_inst(
        .tdc_refclck(tdc_refclck),
        .tdc_rst(tdc_rst),
        .clk80(clk80),
        .pps_trigger(pps_trigger),
        .start_gc(start_gc),
        .tdc_digital_data(tdc_digital_data),
        // .value(value),
        .stop_sim_o(stop_sim_o));


    initial begin
        tdc_refclck = 1;
        tdc_rst = 1;
        pps_trigger = 0;
        start_gc = 0;
        clk80 = 1;
        tdc_digital_data = 0;
        #10 tdc_rst = 0;
        #190 pps_trigger = 1;
        #200 start_gc = 1;
    end

    always #100 tdc_refclck = ~tdc_refclck;
    always #6.25 clk80 = ~clk80;
    always begin 
        #1700 tdc_digital_data = 32'h1cc3;
        #1600 tdc_digital_data = 32'h184dc;
    end



endmodule
