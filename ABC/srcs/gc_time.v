`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2024 03:23:42 PM
// Design Name: 
// Module Name: gc_time
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


module gc_time #(
    parameter integer TSTOP_BITWISE = 14,
    parameter integer INDEX_BITWISE = 4
    )
(
    input tdc_refclck,
    input gc_rst,
    input clk80,
    input pps_i,
    input start_gc_i,
    input [31:0] gate0_i,
    input [31:0] gate1_i,
    input tdc_digital_data,
    // output wire [31:0] value,

    //Debug
    output gc_click,
    output gc,
    output trigger_cycle,
    output counter_time,
    output index_scale,
    output wire stop_sim_o
    );

wire [31:0] tdc_digital_data;
wire [INDEX_BITWISE-1:0] index;
wire [TSTOP_BITWISE-1:0] TSTOP;
wire [31:0] tstop_scale;
wire [7:0] index_scale;

assign index = tdc_digital_data[TSTOP_BITWISE+INDEX_BITWISE-1:TSTOP_BITWISE];
assign TSTOP = tdc_digital_data[TSTOP_BITWISE-1:0]; //20ps is the time scale
assign tstop_scale = TSTOP*20; //20 means 20ps, it's the time scale setting in tdc register
assign index_scale = index*16; //Scale to match with counter_time range

// wire [31:0] value;
assign value = tstop_scale % 12500;

//Reset management
wire clk80_o;
wire gc_rst_o;
wire gc_rstn_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_clk80_inst (
    .clk_i(clk80),
    .rst_i(gc_rst),
    .clk_o(clk80_o),
    .rstn_o(gc_rstn_o),
    .rst_o(gc_rst_o));

//Generate pps_trigger under 80Mhz domain
reg pps_trigger;
reg pps_r;
always @(posedge clk80) begin
    // if (!rstn_tdc_o) begin
    if (gc_rst_o) begin
        pps_trigger <= 1'b0;
        pps_r <= 0;
    end else begin
        pps_r <= pps_i;
        if (!pps_r && pps_i) begin
            pps_trigger <= 1'b1;
        end
    end
end


wire trigger_cycle;
reg [6:0] counter_time;

// assign stop_sim_o = ((counter_time == 12500) && pps_trigger )? 1:0;
assign trigger_cycle = ((((counter_time - index_scale) >= 16) && ((counter_time - index_scale) < 32) && pps_trigger) 
| ((counter_time >=0 && counter_time <= 15) && (index_scale == 112) && pps_trigger))?1:0;//Trigger refclk period which have click event
always @(posedge clk80) begin
    if (gc_rst_o) begin
        counter_time <= 0;
    end else begin
        if (pps_trigger) begin
            counter_time <= counter_time + 1; //count in [ps] time
            if (counter_time >= 127) begin //reset after 8 cycle of 5MHz
                counter_time <= 0;
            end
        end else begin
            counter_time <= 0;
        end
    end
end

wire [15:0] gate_pos0,gate_pos1,gate_pos2,gate_pos3;
assign gate_pos0 = gate0_i[15:0];
assign gate_pos1 = gate0_i[31:16];
assign gate_pos2 = gate1_i[15:0];
assign gate_pos3 = gate1_i[31:16];

reg [31:0] counter_time_reference;
wire [31:0] tstop_inwindow;
assign tstop_inwindow = tstop_scale - counter_time_reference;
// assign stop_sim_o = (((tstop_scale - counter_time_reference) < 12500) && ((tstop_scale - counter_time_reference) >= 0) && trigger_cycle && pps_trigger )? 1:0;
assign stop_sim_o = (((tstop_inwindow < gate_pos1 && tstop_inwindow >= gate_pos0) && trigger_cycle && pps_trigger) 
    | ((tstop_inwindow < gate_pos3 && tstop_inwindow >= gate_pos2) && trigger_cycle && pps_trigger))? 1:0;
always @(posedge clk80) begin
    if (gc_rst_o) begin
        counter_time_reference <= 0;
    end else begin
        if (pps_trigger && trigger_cycle) begin
            counter_time_reference <= counter_time_reference + 12500; //count in [ps] time
            if (counter_time_reference >= 12500*15) begin //reset after 8 cycle of 5MHz
                counter_time_reference <= 0;
            end
        end else begin
            counter_time_reference <= 0;
        end
    end
end


//Make a separate reset for global counter
//Start_gc is from axil, need to align to pps
reg [2:0] start_gc_r;
reg start_gc_o;
initial begin
    start_gc_r <= 0;
    start_gc_o <= 0;
end
always @(posedge pps_i) begin
    start_gc_r <= {start_gc_r[1:0],start_gc_i};
    if (start_gc_r[2] == 0 && start_gc_r[0] == 1) begin
        start_gc_o <= start_gc_i;
    end
end

reg [51:0] gc; 
reg [51:0] gc_click;
always @(posedge clk80) begin
    if (gc_rst_o) begin
        gc <= 0;
        gc_click <= 0;
    end else begin
        if (start_gc_o) begin
            gc <= gc + 1;
            if (stop_sim_o) begin
                gc_click <= gc;
            end
        end else begin
            gc <= 0;
        end
    end
end
endmodule
