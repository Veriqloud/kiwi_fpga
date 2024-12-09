`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2024 01:44:29 PM
// Design Name: 
// Module Name: ddr_data
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


module ddr_data(
    input           clk200_i,
    input           pps_i,
    // input           ddr_data_rst,
    input           ddr_data_rstn,
    //input from fastdac
    input           rd_en_4,
    input [3:0]     rng_data,

    //input from tdc 
    input           tvalid200,
    input [31:0]    tdata200,
    input [15:0]    tdata200_mod,
    input [31:0]    gate_pos0,
    input [31:0]    gate_pos1,
    input [31:0]    gate_pos2,
    input [31:0]    gate_pos3,
    //AXIL control ports
    input           start_write_ddr_i,
    input [2:0]     command_i, 
    input           command_gc_i,
    input           command_enable,
    input           command_alpha_enable,
    input           command_gc_enable,
    input           reg_enable_i,
    input [47:0]    dq_gc_start_i,
    input [31:0]    threshold_i,
    input [31:0]    threshold_full_i,
    input [31:0]    fiber_delay_i,
    input           pair_delay_i,

    //AXIL output monitoring ports
    output [47:0]   current_dq_gc,
    output          current_dq_gc_valid,

    //AXI-Stream master ports for sending alpha to ddr
    output reg [255:0]                        m_axis_tdata,
    input wire                                m_axis_tready,
    output reg                                m_axis_tvalid,
    input                                     m_axis_clk,

    //AXI-Stream slave ports for reading alpha from ddr
    input [255:0]    s_axis_tdata,
    output reg       s_axis_tready,
    input wire       s_axis_tvalid,
    input            s_axis_clk,


    //AXI-Stream master ports for sending dq_gc, click result to xdma
    input              m_axis_gc_clk,
    output reg [63:0] m_axis_tdata_gc,
    input wire         m_axis_tready_gc,
    output reg         m_axis_tvalid_gc,
    output reg         fifo_gc_rst,

    //AXI-Stream slave ports for receiving dq_gc, click result from xdma
    input              s_axis_gc_clk,
    input              s_gc_aresetn,
    input [63:0]       s_axis_tdata_gc,
    output wire        s_axis_tready_gc,
    input wire         s_axis_tvalid_gc,

    //AXI-Stream master ports fro sending alpha to xdma
    input              m_axis_alpha_clk,
    output reg [127:0] m_axis_tdata_alpha,
    input wire         m_axis_tready_alpha,
    output reg         m_axis_tvalid_alpha,
    output reg         fifo_alpha_rst,

    //Debug
    output [1:0] alpha_q,
    output [47:0] read_count,
    output [2:0] state_alpha,
    output [63:0] tdata_gc,
    output wire s_axis_tvalid_gc_debug,
    output rd_en_fifo_gc,
    output fifo_gc_full,
    output fifo_gc_empty,
    output alpha_pack_done,
    output wire [6:0] alpha_cycle_counter,
    output start_save_alpha,
    output read_done,
    output wire [31:0] dq_gc_start_r_debug,
    // output [31:0] threshold_full_debug,
    // output counter_datout,
    output rd_gc_valid,
    output cycle_counter,
    output pack_done,
    output data_pack,
    // output wire [31:0] threshold_wait,
    // output [41:0] delta_time_count,
    // output debug_empty_flag,
    output gc_time_valid_div,
    output gc_time_valid_mod,
    output dq_gc,
    output command_gc_enable_r

    );

//Debug signals
// wire [15:0] threshold_wait;
wire [31:0] threshold_full_debug;
wire [31:0] threshold_wait;
assign s_axis_tvalid_gc_debug = s_axis_tvalid_gc;
assign current_dq_gc_debug = current_dq_gc[3:0];
assign dq_gc_start_r_debug = dq_gc_start_r[47:6];
assign threshold_full_debug = threshold_full_r;
// assign threshold_wait = dq_gc_start_r[47:32];
assign threshold_wait = threshold_r;
//clock domain changing from 200MHz to 250MHz
reg s_axis_tready_gc_200;
reg [2:0] s_axis_tready_gc_r;
initial begin
    s_axis_tready_gc_r <= 0;
end
always @(posedge s_axis_gc_clk) begin
    s_axis_tready_gc_r <= {s_axis_tready_gc_r[1:0],s_axis_tready_gc_200}; 
end
assign s_axis_tready_gc = s_axis_tready_gc_r[2];

//Instant the fifo_gc_in, from AXI-Stream to 200MHz
//Need to manage wr and re with ddr reading
wire rd_en_fifo_gc;
// assign rd_en_fifo_gc = rd_en_gc;
// assign rd_en_fifo_gc = rd_en_gc_test;
assign rd_en_fifo_gc = (counter_rd_en_gc == 1) ? 1:0;
wire [63:0] tdata_gc;
wire fifo_gc_empty;
wire fifo_gc_almost_empty;
wire fifo_gc_full;
wire rd_gc_valid;
reg fifo_gc_in_rst;
fifo_gc_in_64x64 fifo_gc_in_inst (
  // .rst(!s_gc_aresetn),                    // input wire rst
  .rst(!fifo_gc_in_rst),                    // input wire rst
  .wr_clk(s_axis_gc_clk),              // input wire wr_clk
  .rd_clk(clk200_i),              // input wire rd_clk
  .din(s_axis_tdata_gc),                    // input wire [63 : 0] din
  .wr_en(s_axis_tvalid_gc),                // input wire wr_en
  .rd_en(rd_en_fifo_gc),                // input wire rd_en
  .dout(tdata_gc),                  // output wire [63 : 0] dout
  .full(fifo_gc_full),                  // output wire full
  .almost_full(),    // output wire almost_full
  .empty(fifo_gc_empty),                // output wire empty
  .almost_empty(fifo_gc_almost_empty),  // output wire almost_empty
  .valid(rd_gc_valid),                // output wire valid
  .prog_full(),        // output wire prog_full
  // .prog_empty(),      // output wire prog_empty
  .wr_rst_busy(),    // output wire wr_rst_busy
  .rd_rst_busy()    // output wire rd_rst_busy
);


//Axil register receiver, change clock domain from axil 15MHz to 200MHz
reg [2:0] start_write_ddr_r;
reg start_write_ddr_o;
reg [2:0] pps_r;
reg [3:0] tvalid200_r;
reg [2:0] command_enable_r;
reg [2:0] command_alpha_enable_r;
reg [2:0] command_gc_enable_r;
reg [2:0] command_r;
reg [2:0] command_gc_r;
reg [2:0] reg_enable_r;
reg [47:0] dq_gc_start_r;
reg [31:0] threshold_r;
reg [31:0] threshold_full_r;
reg [31:0] fiber_delay_r;
reg pair_delay_r;

initial begin
    pps_r <= 0;
    tvalid200_r <= 0;
    start_write_ddr_r <= 0;
    start_write_ddr_o <= 0;
    command_enable_r <= 0;
    command_alpha_enable_r <= 0;
    command_gc_enable_r <= 0;
    reg_enable_r <= 0;
    command_r <= 3'b000; //initial here, axil control later
    command_gc_r <= 1'b0; //initial here, axil control later
    dq_gc_start_r <= 48'b0;
    threshold_r <= 32'b0;
    threshold_full_r <= 32'b0;
    fiber_delay_r <= 32'b0;
    pair_delay_r <= 0;
end

always @(posedge clk200_i) begin
    reg_enable_r <= {reg_enable_r[1:0], reg_enable_i};
    if(reg_enable_r[2] == 0 && reg_enable_r[1] == 1) begin
        command_r <= command_i;
        command_gc_r <= command_gc_i;
        dq_gc_start_r <= dq_gc_start_i;
        threshold_r <= threshold_i;
        threshold_full_r <= threshold_full_i;
        fiber_delay_r <= fiber_delay_i;
        pair_delay_r <= pair_delay_i;
    end
end


//Internal registers and wires
reg [47:0] dq_gc;
reg [47:0] dq_gc_time;
reg [47:0] read_count;
reg [3:0] alpha;
reg [1:0] alpha_q;
reg [6:0] rd_en_4_r;
reg [6:0] cycle_counter;
reg [2:0] counter_valid;
reg [255:0] data_pack;
reg pack_done;
reg read_done;
reg rd_en_gc;
reg rd_en_gc_test;
reg [31:0] count_wait_long;
reg [47:0] current_dq_gc;
reg [51:0] counter_datout;
reg [31:0] counter_wait;
reg [31:0] counter_rd_en_gc;

//wires
wire [15:0] tdata200_mod_dq;
assign tdata200_mod_dq = tdata200[13:0]%1250;

//convert to gc unit
wire [2:0] index_shift;
assign index_shift = tdata200[16:14] + 1; 
wire [5:0] index_shift_gc;
assign index_shift_gc = index_shift<<3; //multiply by 8, 5MHz = 8[gcs]
reg [3:0] time_ref_gc;
always @(*) begin
    if (tdata200[13:0] < 1250)
        time_ref_gc = 4'd1;
    else if (tdata200[13:0] < 2500)
        time_ref_gc = 4'd2;
    else if (tdata200[13:0] < 3750)
        time_ref_gc = 4'd3;
    else if (tdata200[13:0] < 5000)
        time_ref_gc = 4'd4;
    else if (tdata200[13:0] < 6250)
        time_ref_gc = 4'd5;
    else if (tdata200[13:0] < 7500)
        time_ref_gc = 4'd6;
    else if (tdata200[13:0] < 8750)
        time_ref_gc = 4'd7;
    else 
        time_ref_gc = 4'd8;
end
wire [47:0] dq_gc_div64;
assign dq_gc_div64 = ((dq_gc-12)>>6)<<6; //12 gcs is delay time from click to tvalid200

//global counter read out of gc_fifo_in
wire [47:0] gc_time_valid;
wire [41:0] gc_time_valid_div;
wire [6:0] gc_time_valid_mod;
wire q_pos;
// wire [41:0] delta_time_count;
// wire debug_empty_flag;

assign gc_time_valid = tdata_gc[47:0] - fiber_delay_r; //might have some calib value
assign gc_time_valid_div = gc_time_valid[47:6];
assign gc_time_valid_mod = gc_time_valid[5:0];
assign q_pos = tdata_gc[48];

// assign gc_time_valid = (pair_delay_r == 1)?(tdata_gc[47:0] - fiber_delay_r)
// :((tdata_gc[48] == 1)?(tdata_gc[47:0] - fiber_delay_r + 1):(tdata_gc[47:0] - fiber_delay_r));
// assign gc_time_valid_div = gc_time_valid[47:6];
// assign gc_time_valid_mod = gc_time_valid[5:0];
// assign q_pos = (pair_delay_r == 1)?(tdata_gc[48]):(~tdata_gc[48]); 


wire current_dq_gc_valid;
assign current_dq_gc_valid = command_enable_r[2];

//State machine 
reg [2:0] state;
parameter IDLE = 0, WAIT_START = 1, DETECT_PPS = 2, START = 3;
reg [2:0] state_alpha;
parameter IDLE_AL = 0, WAIT = 1, COUNTING = 2, DONE = 3;

initial begin
    state <= IDLE;
    state_alpha <= IDLE_AL;
end

always @(posedge clk200_i) begin
    if (!ddr_data_rstn) begin

        start_write_ddr_r <= 0;
        start_write_ddr_o <= 0;
        pps_r <= 0;
        tvalid200_r <= 0;

        dq_gc <= 48'b0;
        dq_gc_time <= 48'b0;
        read_count <= 48'b0;
        alpha <= 4'b0;
        alpha_q <= 2'b0;
        rd_en_4_r <= 0;
        cycle_counter <= 7'b0;
        counter_valid <= 3'b0;
        data_pack <= 256'b0;
        pack_done <= 0;
        read_done <= 0;
        rd_en_gc <= 0;
        rd_en_gc_test <= 0;
        count_wait_long <= 0;
        current_dq_gc <= 0;
        counter_datout <= 0;
        counter_wait <= 0;
        counter_rd_en_gc <= 0;

        command_enable_r <= 0;
        command_gc_enable_r <= 0;

        m_axis_tdata <= 256'b0; //m_axis to ddr fifo
        m_axis_tvalid <= 0;
        s_axis_tready <= 0;

        m_axis_tdata_gc <= 64'b0; //m_axis to gc_fifo
        m_axis_tvalid_gc <= 0;
        fifo_gc_rst <= 0;
        fifo_gc_in_rst <= 0;


        s_axis_tready_gc_200 <= 0; //s_axis receive gc_in

        state <= IDLE;
        state_alpha <= IDLE_AL;
    end begin
        case (state)
            IDLE: begin
                start_write_ddr_r <= 0;
                start_write_ddr_o <= 0;
                pps_r <= 0;
                tvalid200_r <= 0;

                dq_gc <= 48'b0;
                dq_gc_time <= 48'b0;
                read_count <= 48'b0;
                rd_en_4_r <= 0;
                cycle_counter <= 7'b0;
                counter_valid <= 3'b0;
                data_pack <= 256'b0;
                pack_done <= 0;
                read_done <= 0;
                rd_en_gc <= 0;
                current_dq_gc <= 0;
                counter_datout <= 0;
                counter_wait <= 0;
                counter_rd_en_gc <= 0;

                m_axis_tdata <= 256'b0;
                m_axis_tvalid <= 0;
                s_axis_tready <= 0;

                m_axis_tdata_gc <= 64'b0;
                m_axis_tvalid_gc <= 0;
                fifo_gc_rst <= 0;

                s_axis_tready_gc_200 <= 0;

                state <= WAIT_START;
                state_alpha <= IDLE_AL;
            end
            WAIT_START: begin
                start_write_ddr_r <= {start_write_ddr_r[1:0], start_write_ddr_i};
                if (start_write_ddr_r[2] == 0 && start_write_ddr_r[1] == 1) begin
                    start_write_ddr_o <= 1'b1;
                    state <= DETECT_PPS;
                end 
                else begin
                    state_alpha <= IDLE_AL;
                    state <= WAIT_START;
                end
            end
            DETECT_PPS: begin
                pps_r <= pps_i;
                if (!pps_r && pps_i) begin
                    state <= START;
                end 
                else  begin
                    state <= DETECT_PPS;
                    state_alpha <= IDLE_AL;
                end
            end
            START: begin
                tvalid200_r <= {tvalid200_r[2:0], tvalid200};
                rd_en_4_r <= {rd_en_4_r[5:0],rd_en_4};
                if (rd_en_4_r[5]) begin
                    dq_gc <= dq_gc + 1;
                end else begin
                    dq_gc <= dq_gc;
                end
                command_gc_enable_r <= {command_gc_enable_r[1:0],command_gc_enable};
                if (command_gc_enable_r[2]) begin
                    fifo_gc_rst <= 1;
                end else fifo_gc_rst <= 0;
                // Get gc_click from detection
                if (tvalid200_r[2]== 0 && tvalid200_r[1] == 1) begin
                    dq_gc_time <= dq_gc_div64 + index_shift_gc + time_ref_gc;
                end else dq_gc_time <= dq_gc_time;
                if (tvalid200_r[3] == 0 && tvalid200_r[2] == 1) begin
                    if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625)) begin
                        m_axis_tdata_gc <= {2'b00,dq_gc_time}; //2'b00: click_result|q_pos
                        m_axis_tvalid_gc <= 1'b1;
                    end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq >=625 && tdata200_mod_dq <1250)) begin
                        m_axis_tdata_gc <= {2'b01,dq_gc_time};
                        m_axis_tvalid_gc <= 1'b1;
                    end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625)) begin
                        m_axis_tdata_gc <= {2'b10,dq_gc_time};
                        m_axis_tvalid_gc <= 1'b1;
                    end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq >=625 && tdata200_mod_dq <1250)) begin
                        m_axis_tdata_gc <= {2'b11,dq_gc_time};
                        m_axis_tvalid_gc <= 1'b1;
                    end else begin
                        m_axis_tdata_gc <= m_axis_tdata_gc;
                        m_axis_tvalid_gc <= 1'b0;
                    end                               
                end else begin
                    m_axis_tdata_gc <= m_axis_tdata_gc;
                    m_axis_tvalid_gc <= 1'b0;
                end

                // if (tvalid200) begin
                //     counter_valid <= counter_valid + 1;
                //     if (counter_valid == 1) begin
                //         if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625)) begin
                //             m_axis_tdata_gc <= {2'b00,dq_gc}; //2'b00: click_result|q_pos
                //             m_axis_tvalid_gc <= 1'b1;
                //         end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq >=625 && tdata200_mod_dq <1250)) begin
                //             m_axis_tdata_gc <= {2'b01,dq_gc};
                //             m_axis_tvalid_gc <= 1'b1;
                //         end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625)) begin
                //             m_axis_tdata_gc <= {2'b10,dq_gc};
                //             m_axis_tvalid_gc <= 1'b1;
                //         end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq >=625 && tdata200_mod_dq <1250)) begin
                //             m_axis_tdata_gc <= {2'b11,dq_gc};
                //             m_axis_tvalid_gc <= 1'b1;
                //         end else begin
                //             m_axis_tdata_gc <= m_axis_tdata_gc;
                //             m_axis_tvalid_gc <= 1'b0;
                //         end                               
                //     end else begin
                //         m_axis_tdata_gc <= m_axis_tdata_gc;
                //         m_axis_tvalid_gc <= 1'b0;
                //     end 
                // end else begin
                //     counter_valid <= 0;
                //     m_axis_tdata_gc <= m_axis_tdata_gc;
                //     m_axis_tvalid_gc <= 1'b0;
                // end

                //Get current global counter
                //if (command_r == 3'b010) begin
                command_enable_r <= {command_enable_r[1:0],command_enable};
                if(command_enable_r[2] == 0 && command_enable_r[1] == 1) begin
                    current_dq_gc <= dq_gc;
                end else current_dq_gc <= current_dq_gc;
                //end

                //Pack data to save in ddr, verify number of write and read are matched
                if (rd_en_4_r[1] == 1'b1) begin
                    cycle_counter <= cycle_counter + 1;
                    data_pack[(4*cycle_counter)+:4] <= rng_data;
                    if (cycle_counter >= 7'd63) begin
                        cycle_counter <= 7'b0;
                        pack_done <= 1'b1;
                    end
                end else begin
                    cycle_counter <= cycle_counter;
                    data_pack <= data_pack;
                end
                if (pack_done == 1'b1) begin
                    pack_done <= 1'b0;
                    m_axis_tdata <= data_pack;
                    m_axis_tvalid <= 1'b1;
                    data_pack <= 256'b0;
                end else begin
                    m_axis_tdata <= m_axis_tdata;
                    m_axis_tvalid <= 1'b0;
                end

                //Reading saved alpha from ddr and reading received gc from fifo_gc,
                //get the right alpha out
                s_axis_tready_gc_200 <= 1'b1; //ready to receive dq_gc and click_result
                fifo_gc_in_rst <= 1'b1;
                counter_datout <= counter_datout + 1;

                // rd_en_gc_test <= m_axis_tvalid_gc;

                counter_rd_en_gc <= counter_rd_en_gc + 1;
                if (counter_rd_en_gc >= threshold_wait) begin
                    counter_rd_en_gc <= 0;
                end
                
                if (rd_gc_valid) begin
                    state_alpha <= COUNTING;
                end else begin
                    state_alpha <= WAIT;
                end


                // state_alpha <= IDLE_AL;
                // if (counter_datout >= threshold_full_debug) begin
                //     state_alpha <= COUNTING;
                //     counter_datout <= counter_datout;
                // end

            end
        endcase

   
        // case (state_alpha)
        //     IDLE_AL : begin
        //         read_count <= 0;
        //         read_done <= 0;
        //         counter_wait <= 0;
        //     end
        //     WAIT: begin
        //         read_done <= 0;
        //         counter_wait <= counter_wait + 1;
        //         if (counter_wait >= threshold_wait) begin
        //             state_alpha <= COUNTING;
        //             counter_wait <= counter_wait;
        //         end else state_alpha <= WAIT;
        //     end
        //     COUNTING: begin
        //         s_axis_tready <= 1'b1;
        //         read_done <= 0;
        //         if (s_axis_tvalid) begin
        //             read_count <= read_count + 1;
        //         end else begin
        //             read_count <= read_count;
        //         end
        //         if ((read_count-1) == 624) begin //1249 for 1k rate, 24 for 50k rate
        //             s_axis_tready <= 0;
        //             state_alpha <= DONE;
        //         end else begin
        //             state_alpha <= COUNTING;
        //         end
        //         if (counter_datout == 0) begin
        //             state_alpha <= IDLE_AL;
        //         end
        //     end
        //     DONE: begin
        //         read_done <= 1;
        //         read_count <= 0;
        //         counter_wait <= 0;
        //         state_alpha <= WAIT;
        //     end
        // endcase


        case (state_alpha)
            IDLE_AL: begin
                read_count <= 48'b0;
                read_done <= 1'b0;
            end
            WAIT: begin
                read_done <= 0;
                if (rd_gc_valid) begin
                    state_alpha <= COUNTING;
                end else state_alpha <= WAIT;
            end
            COUNTING: begin
                s_axis_tready <= 1;
                read_done <= 0;
                // if ((!s_axis_tvalid) || (!s_axis_tready)) begin
                //     read_count <= read_count;
                // end
                if (s_axis_tvalid && s_axis_tready) begin
                    read_count <= read_count + 1;
                end else begin
                    read_count <= read_count;
                end

                if (((read_count-0) == gc_time_valid_div) && (q_pos == 1'b0) && s_axis_tvalid && s_axis_tready) begin
                    alpha_q <= s_axis_tdata[(4*gc_time_valid_mod + 2)+:2];
                    state_alpha <= DONE;
                    s_axis_tready <= 0;
                end else if (((read_count-0) == gc_time_valid_div) && (q_pos == 1'b1) && s_axis_tvalid && s_axis_tready) begin
                    alpha_q <= s_axis_tdata[4*gc_time_valid_mod+:2]; 
                    state_alpha <= DONE;
                    s_axis_tready <= 0;
                end else begin
                    state_alpha <= COUNTING;
                end

                if (dq_gc == 0) begin
                    state_alpha <= IDLE_AL;
                end
                // if (counter_datout == 0) begin
                //     state_alpha <= IDLE_AL;
                // end
            end
            DONE: begin
                read_done <= 1;
                read_count <= read_count;
                state_alpha <= WAIT;
            end
        endcase

    end
end



//Manage read alpha and stop read alpha 
reg start_save_alpha;
reg [6:0] alpha_cycle_counter;
reg [127:0] alpha_pack;
reg alpha_pack_done;

always @(posedge clk200_i) begin
    if (!ddr_data_rstn) begin
        fifo_alpha_rst <= 0;
        start_save_alpha <= 0;
        alpha_cycle_counter <= 0;
        alpha_pack <= 0;
        alpha_pack_done  <= 0;

        command_alpha_enable_r <= 0;

        m_axis_tdata_alpha <= 128'b0;
        m_axis_tvalid_alpha <= 0;
    end else begin
        if (command_r == 3'b011) begin //Read_angle from set_current_gc
            fifo_alpha_rst <= 1'b0;
            command_alpha_enable_r <= {command_alpha_enable_r[1:0], command_alpha_enable};
            if (command_alpha_enable_r[2]) begin
                fifo_alpha_rst <= 1'b1;
                if (read_count >= dq_gc_start_r[47:6]) begin
                    start_save_alpha <= 1'b1;
                    if (start_save_alpha == 1'b1 && read_done == 1'b1) begin
                        alpha_cycle_counter <= alpha_cycle_counter + 1;
                        alpha_pack[(2*alpha_cycle_counter)+:2] <= alpha_q;
                        if (alpha_cycle_counter >= 7'd63) begin
                            alpha_cycle_counter <= 0;
                            alpha_pack_done <= 1'b1;
                        end
                    end else begin
                        alpha_cycle_counter <= alpha_cycle_counter;
                        alpha_pack <= alpha_pack;
                    end
                    if (alpha_pack_done == 1'b1) begin
                        alpha_pack_done <= 0;
                        m_axis_tdata_alpha <= alpha_pack;
                        m_axis_tvalid_alpha <= 1'b1;
                        alpha_pack <= 128'b0;
                    end else begin
                        m_axis_tdata_alpha <= m_axis_tdata_alpha;
                        m_axis_tvalid_alpha <= 1'b0;
                    end
                end else begin
                    start_save_alpha <= 1'b0;
                end
            end else begin
                m_axis_tdata_alpha <= m_axis_tdata_alpha;
                m_axis_tvalid_alpha <= 1'b0;
                // fifo_alpha_rst <= 0;
            end
        end else if (command_r == 3'b100) begin //stop read_angle, reset fifo
            fifo_alpha_rst = 1'b0;
        end        
    end
end


endmodule
