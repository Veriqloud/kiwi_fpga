`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2026 01:18:40 PM
// Design Name: 
// Module Name: axis_busrt_formation_tb
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


module axis_busrt_formation_tb();
    reg s_aclk;
    reg s_aresetn;
    reg s_axis_tvalid;
    wire s_axis_tready;
    reg [255 : 0] s_axis_tdata;
    reg s_axis_tlast;
    reg [3 : 0] s_axis_tuser;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire [255 : 0] m_axis_tdata;
    wire m_axis_tlast;
    wire [3 : 0] m_axis_tuser;
    wire axis_prog_full;
    wire axis_prog_empty;

    axis_burst dut(
        .s_aclk(s_aclk),
        .s_aresetn(s_aresetn),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser(m_axis_tuser),
        .axis_prog_full(axis_prog_full),
        .axis_prog_empty(axis_prog_empty)
    );
    initial begin
        s_aclk = 0;
        s_aresetn = 0;
        #10 s_aresetn = 1;
        // s_axis_tready = 1;
        m_axis_tready = 1;
    end
    always #2.5 s_aclk = ~s_aclk; // 100MHz clock

    initial begin
        s_axis_tdata <= 0;
        forever begin
            #160 s_axis_tdata = 1;
            #160 s_axis_tdata = 2;
            #160 s_axis_tdata = 3;
            #160 s_axis_tdata = 4;
             #160 s_axis_tdata = 5;
             #160 s_axis_tdata = 6;
             #160 s_axis_tdata = 7;
             #160 s_axis_tdata = 8;
        end
    end
    initial begin
        s_axis_tvalid = 0;
        forever begin
            #155 s_axis_tvalid = 1;
            #5 s_axis_tvalid = 0;
        end
    end
    initial begin
        s_axis_tlast = 0;
        forever begin
            #2555 s_axis_tlast = 1;
            #5 s_axis_tlast = 0;
        end
    end
 
endmodule
