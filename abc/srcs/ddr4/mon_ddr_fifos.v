`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 09/09/2024 05:29:38 PM
// Design Name: Qline_turnkey
// Module Name: mon_ddr_fifos
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Monitoring the virtual fifo, and axis fifos 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mon_ddr_fifos(
    input       clk200_i,
    input       ddr_data_rstn,
    input       clk250_i,
    input       aresetn,

    input [1:0] vfifo_idle,
    input [1:0] vfifo_full,
    input [1:0] vfifo_empty,
    input       gc_out_fifo_full,
    input       gc_out_fifo_empty,
    input       gc_in_fifo_full,
    input       gc_in_fifo_empty,
    input       alpha_out_fifo_full,
    input       alpha_out_fifo_empty,

    output [8:0]    status_200_o,
    output          status_200_valid_o,
    output [2:0]    status_250_o,
    output          status_250_valid_o
);

reg [25:0] counter_200;
reg [25:0] counter_250;
reg mon_trigger_200;

wire [8:0] status_200;
assign status_200 = {vfifo_idle,vfifo_full,vfifo_empty,gc_out_fifo_full,gc_in_fifo_empty,alpha_out_fifo_full};

wire status_200_valid_o;
assign status_200_valid_o = mon_trigger_200_r[2];
reg [8:0] status_200_o;
reg [2:0] mon_trigger_200_r;
initial begin
    mon_trigger_200_r <= 0;
end
always @(posedge clk200_i) begin
    if (!ddr_data_rstn) begin
        counter_200 <= 0;
        mon_trigger_200 <= 0;
        mon_trigger_200_r <= 0;
        status_200_o <= 0;
    end else begin
        counter_200 <= counter_200 + 1;
        if (counter_200 > 199999) begin
            counter_200 <= 0;
        end
        if (counter_200 >= 1 && counter_200 <= 99) begin
            mon_trigger_200 <= 1;
        end else mon_trigger_200 <= 0;
        if (mon_trigger_200) begin
            status_200_o <= status_200;
        end else status_200_o <= status_200_o;
    end
end


wire [2:0] status_250;
assign status_250 = {gc_out_fifo_empty,gc_in_fifo_full,alpha_out_fifo_empty};

wire status_250_valid_o;
assign status_250_valid_o = mon_trigger_250_r[2];

reg [2:0] status_250_o;
(* ASYNC_REG = "TRUE" *) reg [2:0] mon_trigger_250_r;
initial begin
    mon_trigger_250_r <= 0;
end
always @(posedge clk250_i) begin
    if (!aresetn) begin
        mon_trigger_250_r <= 0;
        status_250_o <= 0;
    end else begin
        mon_trigger_250_r <= {mon_trigger_250_r[1:0],mon_trigger_200};
        if (mon_trigger_250_r[2] == 0 && mon_trigger_250_r[1] == 1) begin
            status_250_o <= status_250;
        end else status_250_o <= status_250_o;
    end
end


endmodule
