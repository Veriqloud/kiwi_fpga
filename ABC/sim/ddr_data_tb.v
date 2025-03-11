`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company; 
// Engineer; 
// 
// Create Date; 07/17/2024 02;28;02 PM
// Design Name; 
// Module Name; ddr_data_tb
// Project Name; 
// Target Devices; 
// Tool Versions; 
// Description; 
// 
// Dependencies; 
// 
// Revision;
// Revision 0.01 - File Created
// Additional Comments;
// 
//////////////////////////////////////////////////////////////////////////////////


module ddr_data_tb();
    reg           clk200_i;
    reg           pps_i;
    reg           ddr_data_rstn;
    reg           rd_en_4;
    reg [3:0]     rng_data;
    reg           tvalid200;
    reg [31:0]    tdata200;
    reg [15:0]    tdata200_mod;
    reg [31:0]    gate_pos0;
    reg [31:0]    gate_pos1;
    reg [31:0]    gate_pos2;
    reg [31:0]    gate_pos3;

    //AXIL control ports
    reg           start_write_ddr_i;
    reg [2:0]     command_i;
    reg           command_gc_i;
    reg           command_enable;
    reg           command_alpha_enable;
    reg           command_gc_enable;
    reg           reg_enable_i;
    reg [47:0]    dq_gc_start_i;
    reg [31:0]    threshold_i;
    reg [31:0]    threshold_full_i;


    //AXIL output monitoring ports
    wire [47:0]   current_dq_gc;

    //AXI-Stream master ports
    wire [255:0]                            m_axis_tdata;
    wire                                    m_axis_tvalid;
    reg                                     m_axis_tready;
    //AXI-Stream slave ports
    reg [255:0]                             s_axis_tdata;
    wire                                    s_axis_tready;
    reg                                     s_axis_tvalid;


    //AXI-Stream master ports for sending dq_gc, click result to xdma
    wire [63:0] m_axis_tdata_gc;
    reg         m_axis_tready_gc;
    wire        m_axis_tvalid_gc;
    wire        fifo_gc_rst;

    //AXI-Stream slave ports for receiving dq_gc, click result from xdma
    reg          s_axis_gc_clk;
    reg          s_gc_aresetn;
    reg [63:0]   s_axis_tdata_gc;
    wire         s_axis_tready_gc;
    reg          s_axis_tvalid_gc;

    //AXI-Stream master ports fro sending alpha to xdma
    wire [127:0] m_axis_tdata_alpha;
    reg          m_axis_tready_alpha;
    wire         m_axis_tvalid_alpha;
    wire         fifo_alpha_rst;

    //Debug
    wire [1:0]  alpha_q;
    wire [47:0] read_count;
    wire [2:0]  state_alpha;
    wire [15:0] tdata_gc;
    wire        s_axis_tvalid_gc_debug;
    wire rd_en_fifo_gc;
    wire fifo_gc_full;
    wire fifo_gc_empty;
    wire fifo_gc_in_rst;
    wire alpha_pack_done;
    wire [6:0] alpha_cycle_counter;
    wire start_save_alpha;
    wire read_done;
    wire [31:0] dq_gc_start_r_debug;
    // wire [47:0] delta_time_count;

ddr_data ddr_data_int(
    .clk200_i(clk200_i),
    .pps_i(pps_i),
    .ddr_data_rstn(ddr_data_rstn),
    .rd_en_4(rd_en_4),
    .rng_data(rng_data),
    .tvalid200(tvalid200),
    .tdata200(tdata200),
    .tdata200_mod(tdata200_mod),
    .gate_pos0(gate_pos0),
    .gate_pos1(gate_pos1),
    .gate_pos2(gate_pos2),
    .gate_pos3(gate_pos3),
    .start_write_ddr_i(start_write_ddr_i),
    .command_i(command_i),
    .command_gc_i(command_gc_i),
    .command_enable(command_enable),
    .command_alpha_enable(command_alpha_enable),
    .command_gc_enable(command_gc_enable),
    .reg_enable_i(reg_enable_i),
    .dq_gc_start_i(dq_gc_start_i),
    .threshold_i(threshold_i),
    .threshold_full_i(threshold_full_i),
    .current_dq_gc(current_dq_gc),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tready(s_axis_tready),
    .s_axis_tvalid(s_axis_tvalid),
    .m_axis_tdata_gc(m_axis_tdata_gc),
    .m_axis_tready_gc(m_axis_tready_gc),
    .m_axis_tvalid_gc(m_axis_tvalid_gc),
    .fifo_gc_rst(fifo_gc_rst),
    .s_axis_gc_clk(s_axis_gc_clk),
    .s_gc_aresetn(s_gc_aresetn),
    .s_axis_tdata_gc(s_axis_tdata_gc),
    .s_axis_tready_gc(s_axis_tready_gc),
    .s_axis_tvalid_gc(s_axis_tvalid_gc),
    .m_axis_tdata_alpha(m_axis_tdata_alpha),
    .m_axis_tready_alpha(m_axis_tready_alpha),
    .m_axis_tvalid_alpha(m_axis_tvalid_alpha),
    .fifo_alpha_rst(fifo_alpha_rst),
    .alpha_q(alpha_q),
    .read_count(read_count),
    .state_alpha(state_alpha),
    .tdata_gc(tdata_gc),
    .s_axis_tvalid_gc_debug(s_axis_tvalid_gc_debug),
    .read_done(read_done)
    // .delta_time_count(delta_time_count)
    // .current_dq_gc_debug(current_dq_gc_debug) 
    ); 

initial begin
    clk200_i = 1;
    s_axis_gc_clk = 1;
    // ddr_data_rstn = 0;
    s_gc_aresetn = 0;
    pps_i = 0;
    // rd_en_4 = 0;
    // rng_data = 0;
    gate_pos0 = 0;
    gate_pos1 = 31'd400;
    gate_pos2 = 31'd400;
    gate_pos3 = 31'd625;
    dq_gc_start_i = 48'ha00000433;
    threshold_i = 32'd39999;

    m_axis_tready = 1;
    m_axis_tready_gc = 1;
    // s_axis_tready_gc = 0;    
    // #10 ddr_data_rstn = 1;
    #10 s_gc_aresetn = 1;
end


//Define the clocks and pps
always #2.5 clk200_i = ~clk200_i;
always #2 s_axis_gc_clk = ~s_axis_gc_clk;
initial begin
    #90000 pps_i = 1;
    forever begin
        #100000 pps_i = 0;
        #900000 pps_i = 1;
    end
end

//Registers
initial begin
    #20 command_i = 0;
    #20 command_i = 3'd3;
    #20 reg_enable_i = 0;
    #20 reg_enable_i = 1;
    command_enable = 1;    
end

initial begin
    rd_en_4 = 1;
    #10 rd_en_4 = 0;
    forever begin
        #20 rd_en_4 = 1;
        #5 rd_en_4 = 0;
    end

end

//rng_data to write to ddr fifo
initial begin
    rng_data = 0;
    #15 rng_data = 2;
    forever begin
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h1;
        #25 rng_data = 4'h1;
        #25 rng_data = 4'h1;
        #25 rng_data = 4'h1;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h0;
        #25 rng_data = 4'h2;
        #25 rng_data = 4'h2;
        #25 rng_data = 4'h2;
        #25 rng_data = 4'h2;

        // #25 rng_data = rng_data + 1;
    end    
end


initial begin
    ddr_data_rstn = 0;
    #10 ddr_data_rstn = 1;
    #2400000 ddr_data_rstn = 0;
    #100000 ddr_data_rstn = 1;
end

//Start moment
initial begin
    start_write_ddr_i = 0; 
    #10 start_write_ddr_i = 1;
    #200000 start_write_ddr_i = 0;
    #2000000 start_write_ddr_i = 1;
end

initial begin
    command_gc_enable = 0;
    #80000 command_gc_enable = 1;
end

initial begin
    command_alpha_enable = 0;
    #1000000 command_alpha_enable = 1;
end
//detection result is sent to m_axis_gc
initial begin
    tvalid200 = 0;
    tdata200 = 0;
    tdata200_mod = 0;
    #95260 tvalid200 = 1;
    forever begin
        tdata200 = $random;
        tdata200_mod = tdata200%625;
        #25 begin 
            tvalid200 = 0;
        end
        #19975 tvalid200 = 1;
    end 
end

//Detection result should go back to fifo_gc_in
initial begin
    s_axis_tdata_gc = 1810;
    s_axis_tvalid_gc = 0;
    #200000 s_axis_tvalid_gc = 0;
    wait (s_axis_tready_gc == 1'b1)
    forever begin
        begin
            s_axis_tvalid_gc = 1;
            s_axis_tdata_gc = s_axis_tdata_gc + 64'd800;
            #4 s_axis_tvalid_gc = 0; 
        end
        #20000 s_axis_tvalid_gc = 0;

    end
end



// simulate data go in and out of ddr. the stream beat is much faster than rd_gc_valid
initial begin
    s_axis_tvalid = 1;
    // s_axis_tvalid = 0;
    s_axis_tdata = 0;
    wait (s_axis_tready == 1'b1)  s_axis_tvalid = 1;
    #21 s_axis_tvalid = 1;
    s_axis_tvalid = 0;
    #295 s_axis_tvalid = 1;
    forever begin
        #5 s_axis_tvalid = 0;
        #295 s_axis_tvalid = 1;
    end

    wait (s_axis_tready == 1'b0) #10 s_axis_tvalid = 0;
    forever begin
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
    end
end

initial begin
    s_axis_tdata = 0;
    #290075 s_axis_tdata = 256'h1111;
    #5 s_axis_tdata = 256'h2222;
    #5 s_axis_tdata = 256'h3333;
    forever begin
        // #300 s_axis_tdata = 256'hffffffffaaaaaaaaffffffffaaaaaaaaffffffffaaaaaaaaffffffffaaaaaaaa;
        #300 s_axis_tdata = 256'hffffffff00000e00ffffffff00000000ffffffffaaaaa7aaffffffff00000000;
        #300 s_axis_tdata = 256'hffffffff00000a00ffffffff00000000ffffffffaaaaacaaffffffff00000000;
    end
end

endmodule
