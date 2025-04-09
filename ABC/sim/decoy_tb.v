`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 04:31:05 PM
// Design Name: 
// Module Name: decoy_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for the decoy module
// 
// Dependencies: decoy.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module decoy_tb;

    // Inputs
    // reg clk200;
    reg pps_i;
    reg clk240;
    reg clk80;
    reg clk200;
    reg rst_240;
    reg decoy_rst;
    // reg tx_core_rst;
    reg [3:0] rng_value;
    reg rd_en_4;
    reg pps_trigger;

    // Outputs
    wire decoy_signal;

    // Instantiate the Unit Under Test (UUT)
    decoy uut (
        // .clk200(clk200), 
        .pps_i(pps_i),
        .clk240(clk240),
        .clk80(clk80),
        .clk200(clk200),
        .rst_240(rst_240),
        .decoy_rst(decoy_rst),
        // .tx_core_rst(tx_core_rst), 
        .rng_value(rng_value), 
        .rd_en_4(rd_en_4), 
        .pps_trigger(pps_trigger), 
        .decoy_signal(decoy_signal)
    );

    initial begin
        // Initialize Inputs
        // clk200 = 0;
        clk240 = 0; 
        clk80 = 0;
        clk200 = 0;
        decoy_rst = 1; // Added missing semicolon
        // tx_core_rst = 1;
        // Wait for global reset to finish
        #100
         decoy_rst = 0;
        #50400 
        decoy_rst = 1;
        #100 
        decoy_rst = 0;
    end
    initial begin
        rd_en_4 = 0;
        // rng_a = 1;
        #212.5 rd_en_4 = 0;
        forever begin
            #20 rd_en_4 = 1;
            #5 rd_en_4 = 0;
        end
    end
    initial begin
        rng_value = 1;
        #207.5 rng_value = 1;
        forever begin
            #25 rng_value = 1;
            #25 rng_value = 2;
            #25 rng_value = 3;
        end
    end
    initial begin
        pps_trigger = 0;
        #227.6 pps_trigger = 1; 
    end
    initial begin
        pps_i = 0;
        #227.5 pps_i = 1;
        forever begin
            #1000 pps_i = 0;
            #9000 pps_i = 1;
        end
    end

    // always #2.5 clk200 = ~clk200; // Generate clock with 5ns period (250MHz)
    initial begin
        #2.55 clk240 = 1;
        forever begin 
            #2.083333333 clk240 = ~clk240; // Generate clock with 4.166ns period (240MHz)
        end
    end
    initial begin
        #2.55 clk80 = 1;
        forever begin 
            #6.25 clk80 = ~clk80; // Generate clock with 4.166ns period (240MHz)
        end
    end
    initial begin
        #2.55 clk200 = 1;
        forever begin 
            #5 clk200 = ~clk200; // Generate clock with 4.166ns period (240MHz)
        end
    end
endmodule
