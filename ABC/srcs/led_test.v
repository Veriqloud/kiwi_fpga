`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 03:11:37 PM
// Design Name: 
// Module Name: led_test
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


module led_test(
   input pps,
   input clk10,
   input clk100,
   input clk200,
   input clk3125,
   input syncout,
   input sys_reset_n,
   input tdc_rst,
   input tdc_pps_trigger_i, 
   input clockchip_sync,
   output wire syncout_o,
   output [3:0] led,
   output [1:0] sig,
   output wire sig3125,
   output wire ext_clk10_o,
   output wire ext_clk200_o,
   output wire ext_clk100_o,
   output sig_80,
   output pps_trigger
    );
reg [3:0] data = 4'b0000;
reg [23:0] counter = 0;
reg [25:0] counter1 = 0;  
assign led = data;
reg [1:0] sig = 2'b00;
assign syncout_o = syncout;
assign ext_clk200_o = clk200;
assign ext_clk100_o = clk100;

always @ (posedge clk10) begin
   //sig[1] <= ~sig[1];
   counter <= counter + 1;
   data[3] <= counter[23]; 
end


reg pps_trigger;
reg pps_r;

always @(posedge clk200) begin
    if (tdc_rst) begin
        pps_trigger <= 1'b0;
        pps_r <= 0;
    end else begin
        pps_r <= pps;
        if (!pps_r && pps) begin
            pps_trigger <= 1'b1;
        end
    end
end



reg [2:0] shift_pps_trigger;
reg tdc_pps_trigger;
initial begin
   shift_pps_trigger <= 0;
   tdc_pps_trigger <= 0;
end
always @(posedge pps) begin
      shift_pps_trigger <= {shift_pps_trigger[1:0],tdc_pps_trigger_i}; //sync clockchip aligned to pps
      if (shift_pps_trigger[2] == 0 && shift_pps_trigger[0] == 1) begin
         tdc_pps_trigger <= tdc_pps_trigger_i;
      end
end

// reg [2:0] shift_pps_trigger;
// reg [2:0] data;
// wire tdc_pps_trigger;
// initial begin
//    shift_pps_trigger <= 0;
//    data <= 3'd5;
// end

// always @(posedge pps) begin
//    shift_pps_trigger <= {shift_pps_trigger[1:0],tdc_pps_trigger_i};
//    if (shift_pps_trigger[2] == 0 && shift_pps_trigger[0] == 1) begin
//       data <= 3'd6;
//    end else begin
//       data <= data;
//    end
// end
// assign tdc_pps_trigger = shift_pps_trigger[0];


//Create long signal aligned to pps
// reg long_pulse;
// reg [1:0] shift_long_pulse;
// initial begin
//    shift_long_pulse <= 0;
//    long_pulse <= 0;
// end
// always @(posedge clk200) begin
//       long_pulse <= 1;
// end
// // past long pulse from fast domain to slow domain

// always @(posedge pps) begin
//    shift_long_pulse <= {shift_long_pulse[0],long_pulse};
// end
// assign pps_trigger = shift_long_pulse[0];

reg [7:0] counter_tdc;
wire tdc_refclk;

localparam N_TDC_REFCLK = 2; //number of tdc clock to reset
reg [8:0] counter_rstidx;
// reg [$clog2(40*N_TDC_REFCLK)-1:0] counter_rstidx; 
wire rstidx;

assign tdc_refclk = (counter_tdc >= 0 && counter_tdc <=19 && pps_trigger) ?1:0;
assign rstidx = ((counter_rstidx >=0 && counter_rstidx <=1) | counter_rstidx == (40*N_TDC_REFCLK -1) && pps_trigger ) ?1:0;

always @(posedge clk200) begin
   if (!sys_reset_n) begin
      counter_tdc <= 0;
      counter_rstidx<= 0;
   end else begin
      if (pps_trigger) begin
         counter_tdc <= counter_tdc + 1;
         if (counter_tdc >= 39) begin
            counter_tdc <= 0;
         end
         counter_rstidx <= counter_rstidx + 1;
         if (counter_rstidx >= (40*N_TDC_REFCLK -1)) begin
            counter_rstidx <= 0;
         end
      end
   end
end


//----------------global counter test\

reg [2:0] counter40;
reg [2:0] counter40_n;
wire pos_40, neg_40;
wire sig_80;
assign pos_40 = (counter40 == 0  && pps_trigger)? 1:0;
always @(posedge clk200) begin
   if (tdc_rst) begin
      counter40 <= 0;
   end else begin
      if (pps_trigger) begin
         counter40 <= counter40 + 1;
         if (counter40 >= 4) begin
            counter40 <= 0;
         end
      end else begin
         counter40 <= 0;
      end
   end
end

assign neg_40 = (counter40_n == 3 && pps_trigger) ?1:0;
always @(negedge clk200) begin
   if (tdc_rst) begin
      counter40_n <= 0;
   end else begin
      if (pps_trigger) begin
         counter40_n <= counter40_n + 1;
         if (counter40_n >= 4) begin
            counter40_n <= 0;
         end
      end else begin
         counter40_n <= 0;
      end
   end
end

assign sig_80 = pos_40 | neg_40;

//----------------------------------




wire clk3125_int;
assign clk3125_int =clk3125;
assign sig3125 = clk3125_int;
assign ext_clk10_o = clk10;
always @ (posedge clk100) begin
   counter1 <= counter1 + 1;
   data[0] <= counter1[25]; 
end


reg sync_ltc_o;
reg [2:0] clockchip_sync_r;
reg [15:0] counter_clk;

reg pps_clk_r;
reg pps_clk_trigger;
initial begin
    clockchip_sync_r <= 3'b0;
end


always @(posedge clk10 or negedge sys_reset_n) begin
   if (!sys_reset_n) begin
      clockchip_sync_r <= 0;
      sync_ltc_o <= 0;
      pps_clk_trigger <= 0;
      pps_clk_r = 0;
      counter_clk <= 0;
   end else begin
      clockchip_sync_r <= {clockchip_sync_r[1:0],clockchip_sync};
      pps_clk_r <= pps;
      if ((!pps_clk_r && pps) && clockchip_sync_r[2]) begin
         pps_clk_trigger <= 1;
      end
      if (pps_clk_trigger) begin
         counter_clk <= counter_clk + 1;
         if ((counter_clk > 0) && (counter_clk <= 16'd20000)) begin
            sync_ltc_o <= 1'b1;
         end else if (counter_clk > 16'd20000) begin
            counter_clk <= counter_clk;
            sync_ltc_o <= 1'b0;
         end else begin
            sync_ltc_o <= 1'b0;
         end
      end else begin
         sync_ltc_o <= 1'b0;
         counter_clk <= 0;
      end

   end
end


endmodule
