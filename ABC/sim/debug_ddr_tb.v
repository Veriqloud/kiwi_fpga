`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 04:31:11 PM
// Design Name: 
// Module Name: debug_ddr_tb
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


module debug_ddr_tb();
    reg clk200_i;
    reg ddr_data_rstn;
    reg pps_i;

    reg start_write_ddr_i;
    reg [31:0] threshold_full;

    //AXIS Master to send data to AXI virtual fifo Slave AXIS
    wire [127:0]                        m_axis_tdata;
    reg                                 m_axis_tready;
    wire                                m_axis_tvalid;

    //AXIS Slave receive data from AXI Virtual fifo Master AXIS
    reg [127:0]    s_axis_tdata;
    wire       s_axis_tready;
    reg        s_axis_tvalid;

    debug_ddr debug_ddr_inst(
    .clk200_i(clk200_i),
    .ddr_data_rstn(ddr_data_rstn),
    .pps_i(pps_i),
    .start_write_ddr_i(start_write_ddr_i),
    .threshold_full(threshold_full),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tready(m_axis_tready),
    .m_axis_tvalid(m_axis_tvalid),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tready(s_axis_tready),
    .s_axis_tvalid(s_axis_tvalid)
    );

initial begin
    clk200_i = 1;
    ddr_data_rstn = 0;
    pps_i = 0;
    start_write_ddr_i = 1;
    threshold_full = 200;

    m_axis_tready = 0;
    #10 ddr_data_rstn = 1;
end
always #2.5 clk200_i = ~clk200_i;
initial begin
    #90000 pps_i = 1;
    forever begin
        #100000 pps_i = 0;
        #900000 pps_i = 1;
    end
end

initial begin
    s_axis_tvalid = 1;
    s_axis_tdata = 0;
    wait (s_axis_tready == 1'b1)  s_axis_tvalid = 1;
    #5 s_axis_tvalid = 1;
    forever begin
        #5 begin 
            s_axis_tvalid = 0;
            s_axis_tdata = $random;
        end
        #295 s_axis_tvalid = 1;
    end

    // wait (s_axis_tready == 1'b0) #10 s_axis_tvalid = 0;
    // forever begin
    //     s_axis_tvalid = 0;
    //     s_axis_tdata = 0;
    // end
end


endmodule
