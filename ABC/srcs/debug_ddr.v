`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 03:56:46 PM
// Design Name: 
// Module Name: debug_ddr
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


module debug_ddr(
    input clk200_i,
    input ddr_data_rstn,
    input pps_i,

    input start_write_ddr_i,
    input [31:0] threshold_full,

    //AXIS Master to send data to AXI virtual fifo Slave AXIS
    output reg [127:0]                        m_axis_tdata,
    input wire                                m_axis_tready,
    output reg                                m_axis_tvalid,

    //AXIS Slave receive data from AXI Virtual fifo Master AXIS
    input [127:0]    s_axis_tdata,
    output reg       s_axis_tready,
    input wire       s_axis_tvalid,

    //debug ports
    output [7:0] read_count,
    output read_done,
    output [2:0] state_alpha,
    output [7:0] counter_datout

    );

reg [2:0] start_write_ddr_r;
reg start_write_ddr_o;
reg [2:0] pps_r;
initial begin
    start_write_ddr_r <= 0;
    start_write_ddr_o <= 0;
    pps_r <= 0;
end

//internal regs and wires
reg [7:0] counter_datin;
reg [31:0] counter_datout;
wire enable_datin;
assign enable_datin = (counter_datin == 2)?1:0;

reg [7:0] read_count;
reg read_done;


reg [2:0] state;
parameter IDLE=0, WAIT_START=1, DETECT_PPS=2, START=3;
reg [2:0] state_alpha;
parameter IDLE_AL = 0, COUNTING = 1, DONE =2;

always @(posedge clk200_i) begin
    if (!ddr_data_rstn) begin
        start_write_ddr_r <= 0;
        start_write_ddr_o <= 0;
        pps_r <= 0;
        counter_datin <= 0;
        counter_datout <= 0;
        read_count <= 0;
        read_done <= 0;

        m_axis_tdata <= 128'b0;
        m_axis_tvalid <= 1'b0;

        s_axis_tready <= 1'b0;

        state <= IDLE;
        state_alpha <= IDLE_AL;
    end else begin
        case (state)
            IDLE: begin
                start_write_ddr_r <= 0;
                start_write_ddr_o <= 0;
                pps_r <= 0;
                counter_datin <=0;
                counter_datout <= 0;
                read_count <= 0;
                read_done <= 0;

                state <= WAIT_START;
            end
            WAIT_START: begin
                start_write_ddr_r <= {start_write_ddr_r[1:0], start_write_ddr_i};
                if (start_write_ddr_r[2] == 0 && start_write_ddr_r[1] == 1) begin
                    start_write_ddr_o <= 1'b1;
                    state <= DETECT_PPS;
                end
            end
            DETECT_PPS: begin
                pps_r <= pps_i;
                if (!pps_r && pps_i) begin
                    state <= START;
                end else state <= DETECT_PPS;
            end
            START: begin
                counter_datin <= counter_datin + 1;
                if (counter_datin >= 159) begin
                    counter_datin <= 0;
                end
                if (enable_datin) begin
                    m_axis_tdata <= m_axis_tdata+1;
                    m_axis_tvalid <= 1'b1;
                end else begin
                    m_axis_tdata <= m_axis_tdata;
                    m_axis_tvalid <= 1'b0;
                end
                counter_datout <= counter_datout + 1; //delay to check when fifo is full
                if (counter_datout >= threshold_full) begin
                    // s_axis_tready <= 1'b1;
                    state_alpha <= COUNTING;
                    counter_datout <= counter_datout;
                end
                // s_axis_tready <= 1'b1;
            end
        endcase

        case (state_alpha)
            IDLE_AL : begin
                read_count <= 0;
                read_done <= 0;
            end
            COUNTING: begin
                s_axis_tready <= 1'b1;
                read_done <= 0;
                if (s_axis_tvalid) begin
                    read_count <= read_count + 1;
                end else begin
                    read_count <= read_count;
                end
                if ((read_count-1) == 24) begin
                    s_axis_tready <= 0;
                    state_alpha <= DONE;
                    // read_count <= 0;
                end else begin
                    state_alpha <= COUNTING;
                end
                if (counter_datout == 0) begin
                    state_alpha <= IDLE_AL;
                end
            end
            DONE: begin
                read_done <= 1;
                read_count <= 0;
                state_alpha <= COUNTING;
            end
        endcase
    end
end
endmodule
