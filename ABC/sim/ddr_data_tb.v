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
    reg [1:0]     rng_a_data;
    reg           tvalid200;
    reg [31:0]    tdata200;
    reg [15:0]    tdata200_mod;
    reg [31:0]    gate_pos0;
    reg [31:0]    gate_pos1;
    reg [31:0]    gate_pos2;
    reg [31:0]    gate_pos3;

    //AXIL control ports
    reg           sr_start_write_ddr_i;
    reg [2:0]     sr_command_i;
    reg           sr_command_gc_i;
    reg           sr_command_enable;
    reg           sr_command_alpha_enable;
    reg           sr_command_gc_enable;
    reg           sr_reg_enable_i;
    reg [47:0]    sr_dq_gc_start_i;
    reg [31:0]    sr_threshold_i;
    reg [31:0]    sr_threshold_full_i;
    reg [15:0]    sr_fiber_delay_i;
    reg           sr_pair_delay_i;
    reg [15:0]    sr_de_fiber_delay_i;
    reg           sr_de_pair_delay_i;
    reg [15:0]    sr_ab_fiber_delay_i;


    //AXIL output monitoring ports
    wire [47:0]   sr_current_dq_gc;

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
    .rng_a_data(rng_a_data),
    .tvalid200(tvalid200),
    .tdata200(tdata200),
    .tdata200_mod(tdata200_mod),
    .gate_pos0(gate_pos0),
    .gate_pos1(gate_pos1),
    .gate_pos2(gate_pos2),
    .gate_pos3(gate_pos3),
    .sr_start_write_ddr_i(sr_start_write_ddr_i),
    .sr_command_i(sr_command_i),
    .sr_command_gc_i(sr_command_gc_i),
    .sr_command_enable(sr_command_enable),
    .sr_command_alpha_enable(sr_command_alpha_enable),
    .sr_command_gc_enable(sr_command_gc_enable),
    .sr_reg_enable_i(sr_reg_enable_i),
    .sr_dq_gc_start_i(sr_dq_gc_start_i),
    .sr_threshold_i(sr_threshold_i),
    .sr_threshold_full_i(sr_threshold_full_i),
    .sr_current_dq_gc(sr_current_dq_gc),
    .sr_fiber_delay_i(sr_fiber_delay_i),
    .sr_pair_delay_i(sr_pair_delay_i),
    .sr_de_fiber_delay_i(sr_de_fiber_delay_i),
    .sr_de_pair_delay_i(sr_de_pair_delay_i),
    .sr_ab_fiber_delay_i(sr_ab_fiber_delay_i),
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
    sr_dq_gc_start_i = 48'h00000433;
    sr_threshold_i = 32'd39999;
    sr_fiber_delay_i = 16'd0;
    sr_pair_delay_i = 1'b0;
    sr_de_fiber_delay_i = 16'd42;
    sr_de_pair_delay_i = 1'b1;

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
    #20 sr_command_i = 0;
    #20 sr_command_i = 3'd3;
    #20 sr_reg_enable_i = 0;
    #20 sr_reg_enable_i = 1;
    sr_command_enable = 1;    
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
    rng_data = 0; rng_a_data = 0;
    #15 rng_data = 2; rng_a_data = 2;
    forever begin
        repeat(8)begin
            #25 rng_data = 4'h0; rng_a_data = 2'h1;
        end
        repeat(8)begin
            #25 rng_data = 4'h1; rng_a_data = 2'h0;
        end
        repeat(8)begin
            #25 rng_data = 4'h0; rng_a_data = 2'h3;
        end
        repeat(8)begin
            #25 rng_data = 4'h2; rng_a_data = 2'h0;
        end

        repeat(8)begin
            #25 rng_data = 4'h0; rng_a_data = 2'h1;
        end
        repeat(8)begin
            #25 rng_data = 4'h1; rng_a_data = 2'h0;
        end
        repeat(8)begin
            #25 rng_data = 4'h0; rng_a_data = 2'h3;
        end
        repeat(8)begin
            #25 rng_data = 4'h3; rng_a_data = 2'h3;
        end


        // #25 rng_data = 4'h0; rng_a_data = 2'h1;
        // #25 rng_data = 4'h0; rng_a_data = 2'h1;
        // #25 rng_data = 4'h0; rng_a_data = 2'h1;
        // #25 rng_data = 4'h0; rng_a_data = 2'h1;
        // #25 rng_data = 4'h1; rng_a_data = 2'h0;
        // #25 rng_data = 4'h1; rng_a_data = 2'h0;
        // #25 rng_data = 4'h1; rng_a_data = 2'h0;
        // #25 rng_data = 4'h1; rng_a_data = 2'h0;
        // #25 rng_data = 4'h0; rng_a_data = 2'h3;
        // #25 rng_data = 4'h0; rng_a_data = 2'h3;
        // #25 rng_data = 4'h0; rng_a_data = 2'h3;
        // #25 rng_data = 4'h0; rng_a_data = 2'h3;
        // #25 rng_data = 4'h2; rng_a_data = 2'h0;
        // #25 rng_data = 4'h2; rng_a_data = 2'h0;
        // #25 rng_data = 4'h2; rng_a_data = 2'h0;
        // #25 rng_data = 4'h2; rng_a_data = 2'h0;
    end    
end


initial begin
    ddr_data_rstn = 0;
    #10 ddr_data_rstn = 1;
    #2400000 ddr_data_rstn = 0;
    #1000000 ddr_data_rstn = 1;
end

//Start moment
initial begin
    sr_start_write_ddr_i = 0; 
    #10 sr_start_write_ddr_i = 1;
    #200000 sr_start_write_ddr_i = 0;
    #4000000 sr_start_write_ddr_i = 1;
end

initial begin
    sr_command_gc_enable = 0;
    #80000 sr_command_gc_enable = 1;
end

initial begin
    sr_command_alpha_enable = 0;
    #1000000 sr_command_alpha_enable = 1;
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
    s_axis_tdata = 0; 
    // wait (s_axis_tready == 1'b0) begin
    //     s_axis_tvalid = 0;
    //     s_axis_tdata = 0;
    // end
    // wait (s_axis_tready == 1'b1) begin
    //     #45 s_axis_tvalid = 1;
    //     s_axis_tvalid = 0;
    //     #295 s_axis_tvalid = 1;
    //     repeat (5) begin
    //         #5 s_axis_tvalid = 0;
    //         #295 s_axis_tvalid = 1;
    //     end
    // end
    forever begin
        wait (s_axis_tready == 1'b1) s_axis_tvalid = 1;
        repeat(40) begin
            #5 s_axis_tvalid = 0; s_axis_tdata = 256'h0101010101010110101010101010100202020202020202303030303030303001;
            #295 s_axis_tvalid = 1;
            #5 s_axis_tvalid = 0; s_axis_tdata = 256'h0101010101010110101010101010103333333333333333303030303030303001;
            #295 s_axis_tvalid = 1;
        end
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
            
    end
end
// initial begin
//     s_axis_tvalid = 1;
//     s_axis_tdata = 0;
//     wait (s_axis_tready == 1'b1)  s_axis_tvalid = 1;
//     #21 s_axis_tvalid = 1;
//     s_axis_tvalid = 0;
//     #295 s_axis_tvalid = 1;
//     forever begin
//         #5 s_axis_tvalid = 0;
//         #295 s_axis_tvalid = 1;
//     end

//     wait (s_axis_tready == 1'b0) #10 s_axis_tvalid = 0;
//     forever begin
//         s_axis_tvalid = 0;
//         s_axis_tdata = 0;
//     end
// end

// initial begin
//     s_axis_tdata = 0;
//     #290075 s_axis_tdata = 256'h1111;
//     #5 s_axis_tdata = 256'h2222;
//     #5 s_axis_tdata = 256'h3333;
//     forever begin
//         // #300 s_axis_tdata = 256'hffffffffaaaaaaaaffffffffaaaaaaaaffffffffaaaaaaaaffffffffaaaaaaaa;
//         #300 s_axis_tdata = 256'hffffffff00000e00ffffffff000f0000ffffffffaaaaa7aa1f1f1f1fffffffff;
//         #300 s_axis_tdata = 256'hffffffff00000a00ffffffff000f0000ffffffffaaaaacaa1f1f1f1fffffffff;
//     end
// end

endmodule
