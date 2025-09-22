`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2025 01:34:26 PM
// Design Name: 
// Module Name: decoy_rng_fifos_tb
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


module decoy_rng_fifos_tb();
    reg               s_axis_clk;
    reg               s_axis_tresetn;
    reg   [127:0] s_axis_tdata;
    reg           s_axis_tvalid;
    wire         s_axis_tready;

    reg           clk200;
    reg           tx_core_rst;
    reg           rd_en_16;
    reg           rd_en_4;
    wire[1:0]    de_rng_dout4;

    decoy_rng_fifos decoy_rng_fifos_inst (
        .s_axis_clk(s_axis_clk),
        .s_axis_tresetn(s_axis_tresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .clk200(clk200),
        .tx_core_rst(tx_core_rst),
        .rd_en_16(rd_en_16),
        .rd_en_4(rd_en_4),
        .de_rng_dout4(de_rng_dout4)
    );
    initial begin
        s_axis_clk = 0;
        s_axis_tresetn = 1;
        clk200 = 0;
        tx_core_rst = 0;
    end
    always #2 s_axis_clk = ~s_axis_clk; // 250 MHz
    always #2.5 clk200 = ~clk200; // 200 MHz

    initial begin
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        #10;
        s_axis_tresetn = 0;
        #10;
        s_axis_tresetn = 1;
        #20;
        // Write some data
        repeat (10) begin
            @(posedge s_axis_clk);
            s_axis_tdata = $random;
            s_axis_tvalid = 1;
            @(posedge s_axis_clk);
            while (!s_axis_tready) @(posedge s_axis_clk);
            s_axis_tvalid = 0;
            @(posedge s_axis_clk);
        end

    end
    initial begin
        rd_en_16 = 0;
        tx_core_rst = 1;
        #100;
        tx_core_rst = 0;
        // Read data from FIFO
        #202.5;
        rd_en_16 = 1;
        forever begin
            @(posedge clk200);
            rd_en_16 = 0;
            #95;
            @(posedge clk200);
            rd_en_16 = 1;
        end

    end
    initial begin
        rd_en_4 = 0;
        #202.5;
        rd_en_4 = 1;
        forever begin
            @(posedge clk200);
            rd_en_4 = 0;
            #20;
            @(posedge clk200);
            rd_en_4 = 1;
        end
    end

endmodule
