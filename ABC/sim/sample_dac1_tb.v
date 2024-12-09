`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2024 03:25:26 PM
// Design Name: 
// Module Name: sample_dac1_tb
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


module sample_dac1_tb();
    reg                                    s_axis_clk;
    reg                                    s_axis_tresetn;
    reg [127 : 0]                          s_axis_tdata;
    reg                                    s_axis_tvalid;
    wire                                   s_axis_tready;
    reg                                  tx_core_clk;
    reg                                    tx_core_reset;
    wire  [127 : 0]                        tx_tdata;
    reg                                    tx_tready;
    reg               dac1_shift_en_o;
    reg               fastdac_sequence_wen_int;
    reg [9:0]         fastdac_sequence_addr_int;
    reg [31:0]        fastdac_sequence_din_int;
    reg               fastdac_rng_wen_int;
    reg [11:0]         fastdac_rng_addr_int;
    reg [31:0]        fastdac_rng_din_int;
    reg [3:0]         shift1_i;
    reg [31:0]        fastdac_amp_dac1_i;
    reg [31:0]        fastdac_amp_dac2_i;
    reg [7:0]         fastdac_dpram_max_addr_seq_dac0_int;
    reg [7:0]         fastdac_dpram_max_addr_seq_dac1_int;
    reg [14:0]         fastdac_dpram_max_addr_rng_dac1_int;
    reg               fastdac_rng_mode_i;
    reg               fastdac_dac1_mode_i;
    reg fb_mode_i;
    reg [14:0] up_offset_i;
    reg tvalid200;
    reg [15:0] tdata200_mod;
    reg [31:0] gate_pos0;
    reg [31:0] gate_pos1;
    reg [31:0] gate_pos2;
    reg [31:0] gate_pos3;


sample_dac1 sample_dac1_inst(
    .s_axis_clk(s_axis_clk),
    .s_axis_tresetn(s_axis_tresetn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .tx_core_clk(tx_core_clk),
    .tx_core_reset(tx_core_reset),
    .tx_tdata(tx_tdata),
    .tx_tready(tx_tready),
    .dac1_shift_en_o(dac1_shift_en_o),
    .fastdac_sequence_wen_int(fastdac_sequence_wen_int),
    .fastdac_sequence_addr_int(fastdac_sequence_addr_int),
    .fastdac_sequence_din_int(fastdac_sequence_din_int),
    .fastdac_rng_wen_int(fastdac_rng_wen_int),
    .fastdac_rng_addr_int(fastdac_rng_addr_int),
    .fastdac_rng_din_int(fastdac_rng_din_int),
    .shift1_i(shift1_i),
    .fastdac_amp_dac1_i(fastdac_amp_dac1_i),
    .fastdac_amp_dac2_i(fastdac_amp_dac2_i),
    .fastdac_dpram_max_addr_seq_dac0_int(fastdac_dpram_max_addr_seq_dac0_int),
    .fastdac_dpram_max_addr_seq_dac1_int(fastdac_dpram_max_addr_seq_dac1_int),
    .fastdac_dpram_max_addr_rng_dac1_int(fastdac_dpram_max_addr_rng_dac1_int),
    .fastdac_rng_mode_i(fastdac_rng_mode_i),
    .fastdac_dac1_mode_i(fastdac_dac1_mode_i),
    .fb_mode_i(fb_mode_i),
    .up_offset_i(up_offset_i),
    .tvalid200(tvalid200),
    .tdata200_mod(tdata200_mod),
    .gate_pos0(gate_pos0),
    .gate_pos1(gate_pos1),
    .gate_pos2(gate_pos2),
    .gate_pos3(gate_pos3)
    );

initial begin
    s_axis_clk = 0;
    s_axis_tresetn = 0;
    #10 s_axis_tresetn = 1;
    tx_core_clk = 0;
    tx_core_reset = 1;
    #20 tx_core_reset = 0;
end

always #2.5 tx_core_clk = ~tx_core_clk;
always #2 s_axis_clk = ~s_axis_clk;

initial begin
    s_axis_tvalid = 0;
    s_axis_tdata = 128'h12341111222222223333333344444444;
    #95 begin s_axis_tvalid = 0; s_axis_tdata = 128'h12341111222222223333333344444444; end
    forever begin
        #95 s_axis_tvalid = 1;
        #5 s_axis_tvalid = 0;
        s_axis_tdata = 128'h12341111222222223333333344444444;
    end
end

initial begin
    dac1_shift_en_o = 0;
    fastdac_sequence_wen_int = 1'b1;
    fastdac_sequence_addr_int = 0;
    fastdac_sequence_din_int = 16'ha;
    fastdac_sequence_wen_int = 1'b1;
    fastdac_sequence_addr_int = 0;
    fastdac_sequence_din_int = 16'ha;
    shift1_i = 0;
    fastdac_amp_dac1_i = 32'h20004000;
    fastdac_amp_dac2_i = 32'hc000e000;
    fastdac_dpram_max_addr_seq_dac0_int = 1;
    fastdac_dpram_max_addr_rng_dac1_int = 1;
    fastdac_dpram_max_addr_rng_dac1_int = 1;
    fastdac_rng_mode_i = 1;
    fastdac_dac1_mode_i = 1;
    fb_mode_i = 1;
    up_offset_i = 15'h4000;
    #500 dac1_shift_en_o = 1;
end

initial begin
    tx_tready = 0;
    #2000 tx_tready = 1;
end

initial begin
    gate_pos0 = 32'd10;
    gate_pos1 = 32'd200;
    gate_pos2 = 32'd500;
    gate_pos3 = 32'd600;

    tvalid200 = 0;
    forever begin
        #999975 tvalid200 = 1;
        #25 tvalid200 = 0;
    end
end

initial begin
    tdata200_mod = 16'd100;
    forever begin
        #7000000 tdata200_mod = 16'd550;
        #7000000 tdata200_mod = 16'd100;
    end
end
endmodule
