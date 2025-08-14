`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2024 03:41:21 PM
// Design Name: 
// Module Name: AS6501_IF_tb
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


module AS6501_IF_tb();
    reg           lclk_i;
    reg           lrst_i;
    reg           linterrupt_i;
    // Control register
    reg           enable;
    reg           command_enable;
    reg           command_count;
    // reg           command_i;
    reg           start_gc_i;
    reg  [15:0]   index_stop_bitwise_i;
    reg [31:0]    gate0_i;
    reg [31:0]    gate1_i;
    reg  [15:0]   shift_tdc_time_i;
    reg  [15:0]   shift_gc_back_i;
    reg           reg_enable_tdc_i;
    reg           reg_enable200_i;
    reg [2:0]           command_i;

    // Stop A
    reg           frame_i;
    reg           sdi_i;


    //Debug
    wire [127:0]  m_axis_tdata;
    wire          m_axis_tvalid;
    wire [3:0]    m_axis_tuser;
    reg           m_axis_tready;
    wire          fifo_calib_rst;

    // AXI-Stream to fifo_gc
    // wire [63:0]      s_axis_tdata_gc;
    // wire [3:0]        s_axis_tuser_gc;
    // wire             s_axis_tvalid_gc;
    // reg              s_axis_tready_gc;
    // wire             fifo_calib_rst;    

    // reg clk5;
    // reg arstn;
    wire [31:0]   debug_tdc_data;
    wire          debug_tdc_valid;
    wire [127:0]  debug_m_axis_data;
    wire          debug_m_axis_valid;

    //Signals for global counter
    reg clk200_i;
    reg rd_en_4;
    reg gc_rst;
    reg pps_i;

    //

    //Debug
    wire tvalid200;
    wire [31:0] tdata200;
    wire [1:0] click_result;
    wire start_gc_o;
    wire [47:0] gc;
    wire [47:0] gc_time_valid;
    wire [2:0] command_enable_r;
    wire [15:0] total_count_o;
    wire [15:0] total_count;    



    AS6501_IF AS6501_IF_inst(
        .lclk_i(lclk_i),
        .lrst_i(lrst_i),
        .linterrupt_i(linterrupt_i),
        .sr_enable(enable),
        .sr_command_enable(command_enable),
        .sr_command_i(command_i),
        .sr_command_count(command_count),
        .sr_start_gc_i(start_gc_i),
        .sr_index_stop_bitwise_i(index_stop_bitwise_i),
        .sr_gate0_i(gate0_i),
        .sr_gate1_i(gate1_i),
        .sr_shift_tdc_time_i(shift_tdc_time_i),
        .sr_shift_gc_back_i(shift_gc_back_i),
        .sr_reg_enable_tdc(reg_enable_tdc_i),
        .sr_reg_enable200(reg_enable200_i),
        .frame_i(frame_i),
        .sdi_i(sdi_i),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tuser(m_axis_tuser),
        .m_axis_tready(m_axis_tready),
        .fifo_calib_rst(fifo_calib_rst),
        // .s_axis_tdata_gc(s_axis_tdata_gc),
        // .s_axis_tuser_gc(s_axis_tuser_gc),
        // .s_axis_tvalid_gc(s_axis_tvalid_gc),
        // .s_axis_tready_gc(s_axis_tready_gc),
        // .fifo_calib_rst(fifo_calib_rst),
        // .clk5(clk5),
        // .arstn(arstn),
        .debug_tdc_data(debug_tdc_data),
        .debug_tdc_valid(debug_tdc_valid),
        .debug_m_axis_data(debug_m_axis_data),
        .debug_m_axis_valid(debug_m_axis_valid),
        .clk200_i(clk200_i),
        .rd_en_4(rd_en_4),
        .gc_rst(gc_rst),
        .pps_i(pps_i),
        .tvalid200(tvalid200),
        .tdata200(tdata200),
        .click_result(click_result),
        .start_gc_o(start_gc_o),
        .gc(gc),
        .gc_time_valid(gc_time_valid),
        .command_enable_r(command_enable_r),
        .sr_total_count_o(total_count_o),
        .total_count(total_count)
        );



    initial begin
        lclk_i = 1;
        lrst_i = 1;
        linterrupt_i = 0;
        enable = 0;
        command_enable = 1;
        command_i = 4;
        index_stop_bitwise_i = 3588; //index: 4 bits, stop: 14 bits
        gate0_i = 32'hff000064;
        gate1_i = 32'hff000064;
        shift_tdc_time_i = 0;
        reg_enable_tdc_i = 0;
        #10 reg_enable_tdc_i = 1;
        reg_enable200_i = 0;
        #5 reg_enable200_i = 1;
        frame_i = 0;
        sdi_i = 0;
        m_axis_tready = 1;
        clk200_i = 0;
        rd_en_4 = 0;
        gc_rst = 0;
        start_gc_i = 0;
        pps_i = 0;
        #100 lrst_i = 0; //release lrst
        #20 enable = 1; //enable
        // #9000 pps_i = 1;
        #5 rd_en_4 = 1; // input rd_en_4
        forever begin
            #5 rd_en_4 = 0;
            #20 rd_en_4 = 1;
        end

        #5 command_enable = 1;

    end
    initial begin
        start_gc_i = 0;
        #10999995 start_gc_i = 1;
    end

    initial begin
        command_count = 0;
        #12000000 command_count = 1;
        #1000000 command_count = 0;
        #1000000 command_count = 1;
    end


    // always #33.33 clk15 = ~clk15;
    always #2.5 lclk_i = ~lclk_i;
    always #2.5 clk200_i = ~clk200_i;

    // always begin
    //     #200 pps_i = 1;
    //     #10000000 pps_i =0;
    // end

    initial begin
        frame_i = 0;
        #500 frame_i = 0;
        forever begin
            #1560 frame_i = 1;
            #40 frame_i = 0;
        end
    end

    initial begin
        sdi_i = 0;
        #550 sdi_i = 0;
        forever begin
            #1510 sdi_i = 0;
            #5 sdi_i = 1;
            #5 sdi_i = 1;
            #5 sdi_i = 1;
            #5 sdi_i = 0;
            #35 sdi_i = 1;
            #15 sdi_i = 0;
            #15 sdi_i = 1;
            #5 sdi_i = 0;
        end
    end
    // always begin
    //     #500  begin frame_i = 1; sdi_i =0; end
    //     #5 sdi_i = 1;
    //     #5 sdi_i = 0;
    //     #5 sdi_i = 1;
    //     #5 sdi_i = 1;
    //     #20 begin frame_i = 0; sdi_i = 1; end
    //     #20 sdi_i = 0;
    //     #25 sdi_i = 1;
    //     #5 sdi_i = 0;
    // end

    always begin
        #90000 pps_i = 1;
        #10000 pps_i = 0;
    end

    always begin
        #10000000 gc_rst = 1;
        #100 gc_rst = 0;
    end
endmodule
