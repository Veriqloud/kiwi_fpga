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
// Description: Monitoring the virtual fifo, and axis fifos. Samples the flags
//   every MON_PERIOD cycles of clk200 and presents them as two status words,
//   each captured in the clock domain its flags natively belong to.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - status_200_o is now captured once per period instead of being
//                 re-latched on every cycle of the trigger window. It used to
//                 keep changing while status_200_valid_o was already asserted,
//                 so the unsynchronised read in ddr_data_axil_mngt could tear
//                 and report a combination that never existed.
//               - Added MON_PERIOD / MON_PULSE in place of magic numbers
// Additional Comments:
// - Bit map, needed by software to decode slv_reg13 and slv_reg14:
//     status_200_o [10:9] vfifo_idle    [8:7] vfifo_full   [6:5] vfifo_empty
//                  [4:3]  reserved, tied 0
//                  [2]    gc_out_fifo_full
//                  [1]    gc_in_fifo_empty
//                  [0]    alpha_out_fifo_full
//     status_250_o [2]    gc_out_fifo_empty
//                  [1]    gc_in_fifo_full
//                  [0]    alpha_out_fifo_empty
//
// - The 200/250 split is deliberate: a FIFO's full flag lives in its write
//   domain and its empty flag in its read domain, so each is sampled where it
//   is already synchronous. Only mon_trigger_200 crosses domains.
// - if ddr_data_rstn is asserted, the status_250_o keep same value, this is normal
//   because only reboot reset register to 0, it will update when the next
//   mon_trigger_200 is asserted.
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

    output [10:0]    status_200_o,
    output          status_200_valid_o,
    output [2:0]    status_250_o,
    output          status_250_valid_o
);

localparam integer MON_PERIOD = 20000;  // clk200 cycles between captures (100us)
localparam integer MON_PULSE  = 99;     // valid strobe width, clk200 cycles

reg [25:0] counter_200;
reg mon_trigger_200;

wire [10:0] status_200;
assign status_200 = {vfifo_idle,vfifo_full,vfifo_empty,1'b0,1'b0,gc_out_fifo_full,gc_in_fifo_empty,alpha_out_fifo_full};

wire status_200_valid_o;
assign status_200_valid_o = mon_trigger_200_r[2];
reg [10:0] status_200_o;
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
        if (counter_200 >= MON_PERIOD - 1) begin
            counter_200 <= 0;
        end
        if (counter_200 == 1) begin
            status_200_o <= status_200;
        end else status_200_o <= status_200_o;
        if (counter_200 >= 1 && counter_200 <= MON_PULSE) begin
            mon_trigger_200 <= 1;
        end else mon_trigger_200 <= 0;
        // if (mon_trigger_200) begin
        //     status_200_o <= status_200;
        // end else status_200_o <= status_200_o;
        mon_trigger_200_r <= {mon_trigger_200_r[1:0],mon_trigger_200};
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
