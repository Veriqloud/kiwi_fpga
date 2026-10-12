`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 07/17/2024 01:44:29 PM
// Design Name: Qline_turnkey
// Module Name: ddr_data
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2 
// Description:
//- Package data to send to DDR Virtual Fifo
//- Read data from DDR Virtual Fifo
//- Send selected data to AXIS
//
// Dependencies:
// - ip/fifo_gc_in_64x64
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed the main always block: the reset branch was closed with
//                 `end begin` instead of `end else begin`, so both state
//                 machines ran on every clock including during reset and their
//                 assignments overrode the reset values. The FSM could leave
//                 WAIT_START and reach DETECT_PPS while ddr_data_rstn was still
//                 asserted.
//               - Added default arms to the state and state_alpha case
//                 statements so unused encodings recover instead of holding
//               - fifo_alpha_rst in the command 3'b100 branch used a blocking
//                 assignment while the same register used non-blocking
//                 elsewhere
//               - Declared current_dq_gc_debug, which was an implicit net
//               - Removed the unused s_gc_aresetn port. NOTE: build_bd.tcl
//                 still lists ddr_data_0/s_gc_aresetn in the aresetn_1 net and
//                 must be updated before the next BD regeneration.
//               - Removed dead registers alpha, counter_valid, rd_en_gc,
//                 rd_en_gc_test, count_wait_long, counter_wait, counter_tlast
//                 and the unused fifo_gc prog/almost flags
// Revision 0.03 - DDR path integrity (docs/monitoring.md, "DDR path status"):
//               - m_axis (to axis_burst / vfifo) is a full AXI-Stream master:
//                 a word waits for tready; a word that completes while the
//                 previous one still waits is dropped and counted
//                 (wr_drop / wr_drop_cnt) instead of being lost silently
//               - start_write low for 2^STOP_FILTER_LOG2 cycles stops the
//                 writer at the next 16-word packet boundary; quiesced = writer
//                 stopped and m_axi of the vfifo idle (axi_quiet_i)
//               - bits [7:6] of bytes 0..23 of every DDR word carry the word
//                 index; the reader compares it with read_count (slip)
//               - the reader keeps the last word it consumed: a lookup whose
//                 word was already consumed is served from that copy, a lookup
//                 whose word is further back is answered with alpha/decoy 0,
//                 bit 3 of its alpha nibble set, err_passed and esc_cnt,
//                 instead of draining the vfifo forever
// Additional Comments:
// - pps200_i is synchronous to clk200_i (pps_timebase), so the WAIT_START
//   condition and the one-flop DETECT_PPS edge detect are timed paths.
//
// - TODO the alpha FSM leaves IDLE_AL only because the START branch of the
//   state case assigns state_alpha every cycle, and IDLE_AL is the one arm of
//   the state_alpha case that does not assign it back. Every other arm
//   overrides that assignment, so it is dead except in IDLE_AL. Adding an
//   apparently harmless `state_alpha <= IDLE_AL;` to that arm would deadlock
//   the FSM. Move the release into the arm that owns it:
//     IDLE_AL: if (state == START) state_alpha <= rd_gc_valid ? COUNTING_CM : WAIT;
//   and drop the assignment from the START branch.
//////////////////////////////////////////////////////////////////////////////////


module ddr_data #(
    parameter integer STOP_FILTER_LOG2 = 18   // 2^18 clk200 cycles = 1.31 ms
)(
    input           clk200_i,
    input           pps200_i,       // PPS synchronous to clk200_i (pps_timebase)
    input           ddr_data_rstn,
    //input from fastdac
    input           rd_en_4,
    input [3:0]     rng_data,
    input [1:0]     rng_a_data, 

    //input from tdc 
    input           tvalid200,
    input [31:0]    tdata200,
    input [15:0]    tdata200_mod,
    input [31:0]    gate_pos0,
    input [31:0]    gate_pos1,
    input [31:0]    gate_pos2,
    input [31:0]    gate_pos3,
    //AXIL control ports
    input           sr_start_write_ddr_i,
    input [2:0]     sr_command_i, 
    input           sr_command_gc_i,
    input           sr_command_enable,
    input           sr_command_alpha_enable,
    input           sr_command_gc_enable,
    input           sr_reg_enable_i,
    input [47:0]    sr_dq_gc_start_i,
    input [31:0]    sr_threshold_i,
    input [15:0]    sr_fiber_delay_i,
    input           sr_pair_delay_i,
    input [15:0]    sr_de_fiber_delay_i,
    input           sr_de_pair_delay_i,
    input [15:0]    sr_ab_fiber_delay_i,

    //AXIL output monitoring ports
    output [47:0]   sr_current_dq_gc,
    output          sr_current_dq_gc_valid,

    //AXI-Stream master ports for sending alpha to ddr
    output  reg [255:0]      m_axis_tdata,
    input   wire             m_axis_tready,
    output  reg              m_axis_tvalid,
    input                    m_axis_clk,
    output reg               m_axis_tlast,

    //AXI-Stream slave ports for reading alpha from ddr
    input [255:0]    s_axis_tdata,
    output  reg      s_axis_tready,
    input   wire     s_axis_tvalid,
    input            s_axis_clk,


    //AXI-Stream master ports for sending dq_gc, click result to xdma
    input              m_axis_gc_clk,
    output reg [63:0]  m_axis_tdata_gc,
    input wire         m_axis_tready_gc,
    output reg         m_axis_tvalid_gc,
    output reg         fifo_gc_rst,

    //AXI-Stream slave ports for receiving dq_gc, click result from xdma
    input              s_axis_gc_clk,
    // input              s_gc_aresetn,
    input [63:0]       s_axis_tdata_gc,
    output wire        s_axis_tready_gc,
    input wire         s_axis_tvalid_gc,

    //AXI-Stream master ports fro sending alpha to xdma
    input              m_axis_alpha_clk,
    output reg [127:0] m_axis_tdata_alpha,
    input wire         m_axis_tready_alpha,
    output reg         m_axis_tvalid_alpha,
    output reg         fifo_alpha_rst,

    //DDR path status (docs/monitoring.md, "DDR path status")
    input              axi_quiet_i,     //vfifo m_axi idle, from axi_virtual_controller_wrapper
    input [31:0]       axi_wbeats_i,    //W beats the vfifo has sent to DDR since reset
    output [20:0]      ext_status_o,    //-> 0x34 [31:11]
    output [31:0]      ext_counts_o,    //-> 0x44

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
    output rd_gc_valid,
    output cycle_counter,
    output pack_done,
    output data_pack,
    output gc_time_valid_div,
    output gc_time_valid_mod,
    output dq_gc,
    output command_gc_enable_r,
    output debug_rc_gc_div
);



//Debug signals
wire [31:0] threshold_wait;
assign s_axis_tvalid_gc_debug = s_axis_tvalid_gc;
assign dq_gc_start_r_debug = dq_gc_start_r[47:6];
assign threshold_wait = threshold_r;
//debug delta number of read out of ddr and global counter received
wire [47:0] debug_rc_gc_div; 
assign debug_rc_gc_div = read_count - gc_time_valid_div;
//clock domain changing from 200MHz to 250MHz
reg s_axis_tready_gc_200;
(* ASYNC_REG = "TRUE" *) reg [2:0] s_axis_tready_gc_r;
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
assign rd_en_fifo_gc = (counter_rd_en_gc == 1) ? 1:0;
wire [63:0] tdata_gc;
wire fifo_gc_empty;
wire fifo_gc_full;
wire rd_gc_valid;
reg fifo_gc_in_rst;
fifo_gc_in_64x64 fifo_gc_in_inst (
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
    .almost_empty(),  // output wire almost_empty
    .valid(rd_gc_valid),                // output wire valid
    .prog_full(),        // output wire prog_full
    .prog_empty(),      // output wire prog_empty
    .wr_rst_busy(),    // output wire wr_rst_busy
    .rd_rst_busy()    // output wire rd_rst_busy
);



//Axil register receiver, change clock domain from axil 15MHz to 200MHz
(* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] start_write_ddr_r;
reg start_write_ddr_o;
reg [2:0] pps_r;
reg [3:0] tvalid200_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] command_enable_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] command_alpha_enable_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] command_gc_enable_r;
reg [2:0] command_r;
reg [2:0] command_gc_r;
reg [47:0] dq_gc_start_r;
reg [31:0] threshold_r;
reg [15:0] fiber_delay_r;
reg pair_delay_r;
reg [15:0] de_fiber_delay_r;
reg de_pair_delay_r;
reg [15:0] ab_fiber_delay_r;

initial begin
    pps_r <= 0;
    tvalid200_r <= 0;
    start_write_ddr_r <= 0;
    start_write_ddr_o <= 0;
    command_enable_r <= 0;
    command_alpha_enable_r <= 0;
    command_gc_enable_r <= 0;
    reg_enable_r <= 0;
    command_r <= 3'b000; 
    command_gc_r <= 1'b0; 
    dq_gc_start_r <= 48'b0;
    threshold_r <= 32'b0;
    fiber_delay_r <= 16'b0;
    pair_delay_r <= 0;
    de_fiber_delay_r <= 16'b0;
    de_pair_delay_r <= 0;
    ab_fiber_delay_r <= 16'b0;
end

always @(posedge clk200_i) begin
    reg_enable_r <= {reg_enable_r[1:0], sr_reg_enable_i};
    if(reg_enable_r[2] == 0 && reg_enable_r[1] == 1) begin
        command_r <= sr_command_i;
        command_gc_r <= sr_command_gc_i;
        dq_gc_start_r <= sr_dq_gc_start_i;
        threshold_r <= sr_threshold_i;
        fiber_delay_r <= sr_fiber_delay_i;
        pair_delay_r <= sr_pair_delay_i;
        de_fiber_delay_r <= sr_de_fiber_delay_i;
        de_pair_delay_r <= sr_de_pair_delay_i;
        ab_fiber_delay_r <= sr_ab_fiber_delay_i;
    end
end


//Internal registers and wires
reg [47:0] dq_gc;
reg [47:0] dq_gc_time;
reg [47:0] read_count;
reg [1:0] alpha_q;
reg decoy_q;
reg [6:0] rd_en_4_r;
reg [6:0] cycle_counter;
reg [255:0] data_pack;
reg pack_done;
reg read_done;
reg [47:0] sr_current_dq_gc;
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
    else if (tdata200[13:0] < 10000)
        time_ref_gc = 4'd8;
    else 
        time_ref_gc = 4'd9;
end
wire [47:0] dq_gc_div64;
assign dq_gc_div64 = ((dq_gc-12)>>6)<<6; //12 gcs is delay time from click to tvalid200

//pack alpha: 32x8bits
wire [47:0] gc_time_valid;
wire [42:0] gc_time_valid_div;
wire [4:0] gc_time_valid_mod;
wire q_pos;
wire [47:0] de_gc_time_valid;
wire [42:0] de_gc_time_valid_div;
wire [4:0] de_gc_time_valid_mod;
wire de_q_pos;


assign gc_time_valid = (pair_delay_r == 1)?(tdata_gc[47:0] - fiber_delay_r)
:((tdata_gc[48] == 1)?(tdata_gc[47:0] - fiber_delay_r + 1):(tdata_gc[47:0] - fiber_delay_r));
assign gc_time_valid_div = gc_time_valid[47:5];
assign gc_time_valid_mod = gc_time_valid[4:0];
assign q_pos = (pair_delay_r == 1)?(tdata_gc[48]):(~tdata_gc[48]); 

assign de_gc_time_valid = (de_pair_delay_r == 1)?(tdata_gc[47:0] - de_fiber_delay_r)
:((tdata_gc[48] == 1)?(tdata_gc[47:0] - de_fiber_delay_r + 1):(tdata_gc[47:0] - de_fiber_delay_r));
assign de_gc_time_valid_div = de_gc_time_valid[47:5];
assign de_gc_time_valid_mod = de_gc_time_valid[4:0];
assign de_q_pos = (de_pair_delay_r == 1)?(tdata_gc[48]):(~tdata_gc[48]);


wire sr_current_dq_gc_valid;
assign sr_current_dq_gc_valid = command_enable_r[2];

//State machine 
reg [2:0] state;
parameter IDLE = 0, WAIT_START = 1, DETECT_PPS = 2, START = 3;
reg [2:0] state_alpha;
parameter IDLE_AL = 0, WAIT = 1, COUNTING_CM = 2, COUNTING_DE = 3, COUNTING_AL = 4, DONE = 5;

initial begin
    state <= IDLE;
    state_alpha <= IDLE_AL;
end

//DDR path integrity
reg         stop_req;                       //start_write held low, writer told to stop
reg [STOP_FILTER_LOG2:0] stop_cnt;
reg         wr_enable;                      //writer may load new words into m_axis
reg [47:0]  wr_word_idx;                    //index of the word being packed
reg         wr_drop;                        //sticky: a word was dropped (m_axis busy)
reg [15:0]  wr_drop_cnt;                    //saturating
reg [255:0] last_word;                      //last word consumed on s_axis
reg [47:0]  last_idx;                       //its read_count
reg         last_valid;
reg         lookup_bad;                     //current lookup could not be answered
reg         err_passed;                     //sticky: a lookup's word was already gone
reg [15:0]  esc_cnt;                        //saturating count of such lookups
reg         slip;                           //sticky: embedded word index != read_count
reg [7:0]   slip_delta;                     //embedded - read_count, last mismatch
reg [31:0]  wr_in_cnt;                      //words accepted on m_axis since reset
wire [63:0] wr_idx_ext = {16'd0, wr_word_idx};
wire [47:0] gc_div48 = {5'd0, gc_time_valid_div};
wire [47:0] de_div48 = {5'd0, de_gc_time_valid_div};
wire        s_hs = s_axis_tvalid && s_axis_tready;
reg  [47:0] rd_idx_embedded;
integer     k_idx;
always @(*) begin
    for (k_idx = 0; k_idx < 24; k_idx = k_idx + 1)
        rd_idx_embedded[2*k_idx +: 2] = s_axis_tdata[8*k_idx+6 +: 2];
end
//Quiesced: the writer loads nothing more and its last word has been taken,
//every word it handed over has gone out as a W beat, and the vfifo m_axi has
//nothing outstanding (B received) and no VALID for 1023 cycles.
wire wr_stopped = !wr_enable && !m_axis_tvalid;
wire wr_drained = ($signed(axi_wbeats_i - wr_in_cnt) >= 0);
wire quiesced   = wr_stopped && wr_drained && axi_quiet_i;
assign ext_status_o = {slip_delta, 5'd0, wr_drained, stop_req, slip, wr_drop, err_passed,
                       axi_quiet_i, wr_stopped, quiesced};
assign ext_counts_o = {esc_cnt, wr_drop_cnt};

always @(posedge clk200_i) begin
    if (!ddr_data_rstn) begin

        start_write_ddr_r <= 0;
        start_write_ddr_o <= 0;
        pps_r <= 0;
        tvalid200_r <= 0;

        dq_gc <= 48'b0;
        dq_gc_time <= 48'b0;
        read_count <= 48'b0;
        alpha_q <= 2'b0;
        decoy_q <= 1'b0;
        rd_en_4_r <= 0;
        cycle_counter <= 7'b0;
        data_pack <= 256'b0;
        pack_done <= 0;
        read_done <= 0;
        sr_current_dq_gc <= 0;
        counter_rd_en_gc <= 0;

        command_enable_r <= 0;
        command_gc_enable_r <= 0;

        m_axis_tdata <= 256'b0; //m_axis to ddr fifo
        m_axis_tvalid <= 0;
        m_axis_tlast <= 0;
        s_axis_tready <= 0;

        m_axis_tdata_gc <= 64'b0; //m_axis to gc_fifo
        m_axis_tvalid_gc <= 0;
        fifo_gc_rst <= 0;
        fifo_gc_in_rst <= 0;

        s_axis_tready_gc_200 <= 0; //s_axis receive gc_in

        stop_req <= 0;
        stop_cnt <= 0;
        wr_enable <= 0;
        wr_word_idx <= 0;
        wr_drop <= 0;
        wr_drop_cnt <= 0;
        last_word <= 0;
        last_idx <= 0;
        last_valid <= 0;
        lookup_bad <= 0;
        err_passed <= 0;
        esc_cnt <= 0;
        slip <= 0;
        slip_delta <= 0;
        wr_in_cnt <= 0;

        state <= IDLE;
        state_alpha <= IDLE_AL;
    end else begin
        if (m_axis_tvalid && m_axis_tready) wr_in_cnt <= wr_in_cnt + 1;
        //every word taken from the vfifo, whatever the alpha state
        if (s_hs) begin
            read_count <= read_count + 1;
            last_word <= s_axis_tdata;
            last_idx <= read_count;
            last_valid <= 1'b1;
            if (rd_idx_embedded != read_count) begin
                slip_delta <= rd_idx_embedded[7:0] - read_count[7:0];
                slip <= 1'b1;
            end
        end

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
                data_pack <= 256'b0;
                pack_done <= 0;
                read_done <= 0;
                sr_current_dq_gc <= 0;
                counter_rd_en_gc <= 0;

                m_axis_tdata <= 256'b0;
                m_axis_tvalid <= 0;
                m_axis_tlast <= 0;
                s_axis_tready <= 0;

                m_axis_tdata_gc <= 64'b0;
                m_axis_tvalid_gc <= 0;
                fifo_gc_rst <= 0;

                s_axis_tready_gc_200 <= 0;

                stop_req <= 0;
                stop_cnt <= 0;
                wr_enable <= 0;
                wr_word_idx <= 0;
                last_valid <= 0;

                state <= WAIT_START;
                state_alpha <= IDLE_AL;
            end
            WAIT_START: begin
                start_write_ddr_r <= {start_write_ddr_r[1:0], sr_start_write_ddr_i};
                if (start_write_ddr_r[2] == 1 && !pps200_i) begin
                    start_write_ddr_o <= 1'b1;
                    state <= DETECT_PPS;
                end 
                else begin
                    state_alpha <= IDLE_AL;
                    state <= WAIT_START;
                end

            end
            DETECT_PPS: begin
                pps_r <= pps200_i;
                if (!pps_r && pps200_i) begin
                    state <= START;
                    wr_enable <= 1'b1;
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
                command_gc_enable_r <= {command_gc_enable_r[1:0],sr_command_gc_enable};
                if ((command_gc_enable_r[2]) && (dq_gc > ab_fiber_delay_r)) begin
                // if ((command_gc_enable_r[2]) && (dq_gc > de_fiber_delay_r)) begin
                        fifo_gc_rst <= 1;
                end else fifo_gc_rst <= 0;

                // Get gc_click from detection
                if (tvalid200_r[2]== 0 && tvalid200_r[1] == 1) begin
                    dq_gc_time <= dq_gc_div64 + index_shift_gc + time_ref_gc;
                end else dq_gc_time <= dq_gc_time;
                if (tvalid200_r[3] == 0 && tvalid200_r[2] == 1) begin
                    if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625) && (dq_gc_time[2:0] != 3'b000)) begin
                        m_axis_tdata_gc <= {2'b00,dq_gc_time}; //2'b00: click_result|q_pos
                        m_axis_tvalid_gc <= 1'b1;
                    end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq >=625 && tdata200_mod_dq <1250)) begin
                        m_axis_tdata_gc <= {2'b01,dq_gc_time};
                        m_axis_tvalid_gc <= 1'b1;
                    end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625)&& (dq_gc_time[2:0] != 3'b000)) begin
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
                //Get current global counter
                command_enable_r <= {command_enable_r[1:0],sr_command_enable};
                if(command_enable_r[2] == 0 && command_enable_r[1] == 1) begin
                    sr_current_dq_gc <= dq_gc;
                end else sr_current_dq_gc <= sr_current_dq_gc;
                //end

                //Stop request: start_write held low for 2^STOP_FILTER_LOG2 cycles
                start_write_ddr_r <= {start_write_ddr_r[1:0], sr_start_write_ddr_i};
                if (start_write_ddr_r[2]) begin
                    stop_cnt <= 0;
                end else if (!stop_cnt[STOP_FILTER_LOG2]) begin
                    stop_cnt <= stop_cnt + 1;
                end
                if (stop_cnt[STOP_FILTER_LOG2]) stop_req <= 1'b1;

                //Pack data to save in ddr. Bits [7:6] of byte j (j < 24) carry
                //bits [2j+1:2j] of the word index, checked on read.
                if (rd_en_4_r[1] == 1'b1) begin
                    cycle_counter <= cycle_counter + 1;
                    data_pack[(8*cycle_counter)+:8] <= {wr_idx_ext[(2*cycle_counter)+:2],rng_a_data,rng_data};
                    if (cycle_counter >= 7'd31) begin
                            cycle_counter <= 7'b0;
                        pack_done <= 1'b1;
                    end
                end else begin
                    cycle_counter <= cycle_counter;
                    data_pack <= data_pack;
                end
                //AXI-Stream master: a word is held until tready. A word that
                //completes while the previous one is still waiting is dropped
                //and counted. After a stop request the writer finishes the
                //current 16-word packet (tlast) and loads nothing more; if the
                //output is blocked it stops at once.
                if (pack_done == 1'b1) begin
                    pack_done <= 1'b0;
                    data_pack <= 256'b0;
                    wr_word_idx <= wr_word_idx + 1;
                    if (wr_enable) begin
                        if (m_axis_tvalid && !m_axis_tready) begin
                            wr_drop <= 1'b1;
                            if (wr_drop_cnt != 16'hffff) wr_drop_cnt <= wr_drop_cnt + 1;
                            if (stop_req) wr_enable <= 1'b0;
                        end else begin
                            m_axis_tdata <= data_pack;
                            m_axis_tvalid <= 1'b1;
                            m_axis_tlast <= (dq_gc[8:0] == 9'd511);
                            if (stop_req && dq_gc[8:0] == 9'd511) wr_enable <= 1'b0;
                        end
                    end else if (m_axis_tvalid && m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                    end
                end else if (m_axis_tvalid && m_axis_tready) begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                end

                //Reading saved alpha from ddr and reading received gc from fifo_gc,
                //get the right alpha out
                s_axis_tready_gc_200 <= 1'b1; //ready to receive dq_gc and click_result
                fifo_gc_in_rst <= 1'b1;

                counter_rd_en_gc <= counter_rd_en_gc + 1;
                if ((counter_rd_en_gc >= threshold_wait) && (state_alpha==WAIT)) begin
                    counter_rd_en_gc <= 0;
                end
                
                if (rd_gc_valid) begin
                    // state_alpha <= COUNTING;
                    // state_alpha <= COUNTING_DE;
                    state_alpha <= COUNTING_CM;
                end else begin
                    state_alpha <= WAIT;
                end
            end
            default: state <= IDLE;
        endcase

        case (state_alpha)
            IDLE_AL: begin
                read_count <= 48'b0;
                read_done <= 1'b0;
                last_valid <= 1'b0;
            end
            WAIT: begin
                read_done <= 0;
                if (rd_gc_valid) begin
                    if (gc_time_valid_div == de_gc_time_valid_div) begin
                        state_alpha <= COUNTING_CM;
                    end else begin
                        // state_alpha <= COUNTING_DE;
                        state_alpha <= COUNTING_AL;
                    end

                end else state_alpha <= WAIT;
            end
            COUNTING_CM: begin
                read_done <= 0;
                if (last_valid && last_idx == gc_div48) begin
                    //word already consumed (previous lookup): use the copy
                    alpha_q <= q_pos ? last_word[8*gc_time_valid_mod+:2] : last_word[(8*gc_time_valid_mod+2)+:2];
                    decoy_q <= de_q_pos ? last_word[8*de_gc_time_valid_mod+4] : last_word[8*de_gc_time_valid_mod+5];
                    lookup_bad <= 1'b0;
                    state_alpha <= DONE;
                    s_axis_tready <= 0;
                end else if (read_count > gc_div48) begin
                    //word is gone: answer, flag, and move on
                    alpha_q <= 2'b00;
                    decoy_q <= 1'b0;
                    lookup_bad <= 1'b1;
                    err_passed <= 1'b1;
                    if (esc_cnt != 16'hffff) esc_cnt <= esc_cnt + 1;
                    state_alpha <= DONE;
                    s_axis_tready <= 0;
                end else begin
                    s_axis_tready <= 1;
                    if ((read_count == gc_div48) && s_hs) begin
                        alpha_q <= q_pos ? s_axis_tdata[8*gc_time_valid_mod+:2] : s_axis_tdata[(8*gc_time_valid_mod+2)+:2];
                        decoy_q <= de_q_pos ? s_axis_tdata[8*de_gc_time_valid_mod+4] : s_axis_tdata[8*de_gc_time_valid_mod+5];
                        lookup_bad <= 1'b0;
                        state_alpha <= DONE;
                        s_axis_tready <= 0;
                    end else begin
                        state_alpha <= COUNTING_CM;
                    end
                end

                if (dq_gc == 0) begin
                    state_alpha <= IDLE_AL;
                end
            end
            COUNTING_AL: begin
                read_done <= 0;
                decoy_q <= decoy_q;
                s_axis_tready <= 1;
                if (last_valid && last_idx == gc_div48) begin
                    alpha_q <= q_pos ? last_word[8*gc_time_valid_mod+:2] : last_word[(8*gc_time_valid_mod+2)+:2];
                    lookup_bad <= 1'b0;
                    state_alpha <= COUNTING_DE;
                end else if (read_count > gc_div48) begin
                    alpha_q <= 2'b00;
                    lookup_bad <= 1'b1;
                    err_passed <= 1'b1;
                    if (esc_cnt != 16'hffff) esc_cnt <= esc_cnt + 1;
                    state_alpha <= COUNTING_DE;
                end else if ((read_count == gc_div48) && s_hs) begin
                    alpha_q <= q_pos ? s_axis_tdata[8*gc_time_valid_mod+:2] : s_axis_tdata[(8*gc_time_valid_mod+2)+:2];
                    lookup_bad <= 1'b0;
                    state_alpha <= COUNTING_DE;
                end else begin
                    state_alpha <= COUNTING_AL;
                end

                if (dq_gc == 0) begin
                    state_alpha <= IDLE_AL;
                end
            end

            COUNTING_DE: begin
                read_done <= 0;
                if (last_valid && last_idx == de_div48) begin
                    decoy_q <= de_q_pos ? last_word[8*de_gc_time_valid_mod+4] : last_word[8*de_gc_time_valid_mod+5];
                    state_alpha <= DONE;
                    s_axis_tready <= 0;
                end else if (read_count > de_div48) begin
                    decoy_q <= 1'b0;
                    lookup_bad <= 1'b1;
                    err_passed <= 1'b1;
                    if (esc_cnt != 16'hffff) esc_cnt <= esc_cnt + 1;
                    state_alpha <= DONE;
                    s_axis_tready <= 0;
                end else begin
                    s_axis_tready <= 1;
                    if ((read_count == de_div48) && s_hs) begin
                        decoy_q <= de_q_pos ? s_axis_tdata[8*de_gc_time_valid_mod+4] : s_axis_tdata[8*de_gc_time_valid_mod+5];
                        state_alpha <= DONE;
                        s_axis_tready <= 0;
                    end else begin
                        state_alpha <= COUNTING_DE;
                    end
                end

                if (dq_gc == 0) begin
                    state_alpha <= IDLE_AL;
                end

            end
            // COUNTING_DE: begin
            //     s_axis_tready <= 1;
            //     read_done <= 0;
            //     if (s_axis_tvalid && s_axis_tready) begin
            //         read_count <= read_count + 1;
            //     end else begin
            //         read_count <= read_count;
            //     end
            //     if (((read_count-0) == de_gc_time_valid_div) && (de_q_pos == 1'b0) && s_axis_tvalid && s_axis_tready) begin
            //         decoy_q <= s_axis_tdata[(8*de_gc_time_valid_mod + 5)+:1];
            //         state_alpha <= COUNTING_AL;
            //     end else if (((read_count-0) == de_gc_time_valid_div) && (de_q_pos == 1'b1) && s_axis_tvalid && s_axis_tready) begin
            //         decoy_q <= s_axis_tdata[(8*de_gc_time_valid_mod+4)+:1]; 
            //         state_alpha <= COUNTING_AL;
            //     end else begin
            //         state_alpha <= COUNTING_DE;
            //     end
            //     if (dq_gc == 0) begin
            //         state_alpha <= IDLE_AL;
            //     end

            // end
            // COUNTING_AL: begin
            //     s_axis_tready <= 1;
            //     read_done <= 0;
            //     decoy_q <= decoy_q;
            //     if (s_axis_tvalid && s_axis_tready) begin
            //         read_count <= read_count + 1;
            //     end else begin
            //         read_count <= read_count;
            //     end

            //     if (((read_count-0) == gc_time_valid_div) && (q_pos == 1'b0) && s_axis_tvalid && s_axis_tready) begin
            //         alpha_q <= s_axis_tdata[(8*gc_time_valid_mod + 2)+:2];
            //         state_alpha <= DONE;
            //         s_axis_tready <= 0;
            //     end else if (((read_count-0) == gc_time_valid_div) && (q_pos == 1'b1) && s_axis_tvalid && s_axis_tready) begin
            //         alpha_q <= s_axis_tdata[8*gc_time_valid_mod+:2]; 
            //         state_alpha <= DONE;
            //         s_axis_tready <= 0;
            //     end else begin
            //         state_alpha <= COUNTING_AL;
            //     end

            //     if (dq_gc == 0) begin
            //         state_alpha <= IDLE_AL;
            //     end
            // end
            DONE: begin
                read_done <= 1;
                state_alpha <= WAIT;
            end
            default: state_alpha <= IDLE_AL;
        endcase

    end
end

//Manage read alpha and stop read alpha 
reg start_save_alpha;
reg [6:0] alpha_cycle_counter;
reg [127:0] alpha_pack;
reg alpha_pack_done;

initial begin
    alpha_cycle_counter <= 0;
end

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
            command_alpha_enable_r <= {command_alpha_enable_r[1:0], sr_command_alpha_enable};
            if (command_alpha_enable_r[2]) begin
                fifo_alpha_rst <= 1'b1;
                if (read_count >= dq_gc_start_r[47:6]) begin
                    start_save_alpha <= 1'b1;
                    if (start_save_alpha == 1'b1 && read_done == 1'b1) begin
                        alpha_cycle_counter <= alpha_cycle_counter + 1;
                        alpha_pack[(4*alpha_cycle_counter)+:4] <= {lookup_bad,decoy_q,alpha_q};
                        if (alpha_cycle_counter >= 7'd31) begin
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
            end
        end else if (command_r == 3'b100) begin //stop read_angle, reset fifo
            fifo_alpha_rst <= 1'b0;
        end        
    end
end
endmodule
