`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
// 
// Create Date: 03/31/2025 04:52:23 PM
// Design Name: Qline_turnkey
// Module Name: fine_delay
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Cascade ODELAY3 for delay upto ~12ns, resolution in ps
//              Chain is ODELAYE3(MASTER) -> IDELAYE3(SLAVE_MIDDLE) ->
//              ODELAYE3(SLAVE_END). Each stage owns its own tap-step engine
//              (master / slv1 / slv2), driven by an AXIL trigger and a tap count
//              taken from the params_* registers. The delayed pulse leaves
//              through an OBUFDS as an LVDS pair.
//
//              clk_i drives both the tap-step engines and the CLK pin of every
//              delay primitive. When the delayed signal comes from an OSERDESE3,
//              clk_i must be the same net as that serializer's CLKDIV pin
//              (DRC REQP-1743): the TTL gate path runs this module at 240 MHz
//              with CLK_RATIO=3, decoy runs it at 80 MHz with CLK_RATIO=1.
//
// Dependencies: Xilinx ODELAYE3 / IDELAYE3 / OBUFDS primitives (UltraScale+).
//               Requires an IDELAYCTRL in the same I/O bank, clocked at
//               REFCLK_FREQUENCY, for the tap delay lines to be calibrated.
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Header completed, port comments added
// Additional Comments:
// Tap stepping is rate-limited by counter_fine: one CE pulse every 17*CLK_RATIO
// clk_i cycles, and the tune window is resolution*CLK_RATIO clk_i cycles. Both
// scale with CLK_RATIO, so a given register value always means the same
// wall-clock window and the same number of taps whatever clk_i is.
//////////////////////////////////////////////////////////////////////////////////


module fine_delay #(
    parameter DELAY_FORMAT = "COUNT", // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    parameter DELAY_TYPE = "VARIABLE",
    parameter DELAY_VALUE = 50,  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process
    parameter REFCLK_FREQUENCY = 300, // IDELAYCTRL reference clock, MHz (200.0-800.0)
    parameter UPDATE_MODE = "ASYNC",  // when tap updates take effect (ASYNC, MANUAL, SYNC)
    parameter integer CLK_RATIO = 1   // clk_i frequency / 80 MHz; scales the tap-step timing
)(
    input   clk_i,              // control clock: tune engines and CLK of all delay primitives
    input   rst_i,              // active-high reset, clk_i domain
    input   pulse_delay_tune,   // pulse to be delayed, drives the master ODELAYE3 ODATAIN
    output  pulse_p,            // delayed pulse, LVDS positive leg (OBUFDS)
    output  pulse_n,            // delayed pulse, LVDS negative leg (OBUFDS)

    //AXIL registers
    // Master stage (ODELAYE3 MASTER) control word:
    //   [0]     increase_en - 1 = increment taps, 0 = decrement
    //   [14:1]  resolution  - tune window length, in 80 MHz cycles (~/17 = tap steps)
    //   [31:15] unused
    input [31:0]    params_i,
    // Slave stages control word, two fields packed into one register:
    //   [0]     increase_en_slv1 - direction for the IDELAYE3 SLAVE_MIDDLE stage
    //   [14:1]  resolution_slv1  - tune window for the IDELAYE3 SLAVE_MIDDLE stage
    //   [15]    unused
    //   [16]    increase_en_slv2 - direction for the ODELAYE3 SLAVE_END stage
    //   [30:17] resolution_slv2  - tune window for the ODELAYE3 SLAVE_END stage
    //   [31]    unused
    input [31:0]    params_slv_i,
    // Tune triggers, asynchronous to clk_i (sourced from the AXIL clock domain).
    // Each opens its stage's tune window; see the counter_long block below.
    input           ttl_trigger_enstep_o,       // master ODELAYE3
    input           ttl_trigger_enstep_slv1_o,  // IDELAYE3 SLAVE_MIDDLE
    input           ttl_trigger_enstep_slv2_o   // ODELAYE3 SLAVE_END
);

//ODELAY3 Master
reg [25:0] counter_long;
reg [25:0] counter_long_slv1;
reg [25:0] counter_long_slv2;
wire [13:0] resolution;
wire [13:0] resolution_slv1;
wire [13:0] resolution_slv2;
    
assign resolution = params_i[14:1];
assign resolution_slv1 = params_slv_i[14:1];
assign resolution_slv2 = params_slv_i[30:17];

// Tune window, in clk_i cycles
wire [25:0] window      = resolution      * CLK_RATIO;
wire [25:0] window_slv1 = resolution_slv1 * CLK_RATIO;
wire [25:0] window_slv2 = resolution_slv2 * CLK_RATIO;

// CE is always a single clk_i cycle wide, so always exactly one tap per pulse
localparam integer FINE_PERIOD = 17 * CLK_RATIO;

//Passing domaine
wire en_step, en_step_slv1, en_step_slv2;
(* ASYNC_REG = "TRUE" *) reg [2:0] ttl_trigger_enstep_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] ttl_trigger_enstep_slv1_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] ttl_trigger_enstep_slv2_r;
initial begin
    ttl_trigger_enstep_r <= 0;
    ttl_trigger_enstep_slv1_r <= 0;
    ttl_trigger_enstep_slv2_r <= 0;
end
always @(posedge clk_i) begin
    ttl_trigger_enstep_r <= {ttl_trigger_enstep_r[1:0],ttl_trigger_enstep_o};
    ttl_trigger_enstep_slv1_r <= {ttl_trigger_enstep_slv1_r[1:0],ttl_trigger_enstep_slv1_o};
    ttl_trigger_enstep_slv2_r <= {ttl_trigger_enstep_slv2_r[1:0],ttl_trigger_enstep_slv2_o};
end
assign en_step = ttl_trigger_enstep_r[2];
assign en_step_slv1 = ttl_trigger_enstep_slv1_r[2];
assign en_step_slv2 = ttl_trigger_enstep_slv2_r[2];

reg stop, stop_slv1, stop_slv2;
reg en_vtc, en_vtc_slv1, en_vtc_slv2;
initial begin
    stop <= 1;
    stop_slv1 <= 1;
    stop_slv2 <= 1;
    en_vtc <= 1;
    en_vtc_slv1 <= 1;
    en_vtc_slv2 <= 1;
end
always @(posedge clk_i) begin
    if (rst_i) begin 
        counter_long <= window + 1;
        counter_long_slv1 <= window_slv1 + 1;
        counter_long_slv2 <= window_slv2 + 1; 
    end else begin
        if (!en_step) begin counter_long <= 0; end
        else if (en_step) begin   
            counter_long <= counter_long + 1;
            if(counter_long > 0  && counter_long <= window) begin
                stop <= 1'b0;
                en_vtc <= 1'b0;
            end else begin
                stop <= 1'b1;
                en_vtc <= 1'b1;
            end
        end
        if (!en_step_slv1) begin counter_long_slv1 <= 0; end
        else if (en_step_slv1) begin   
            counter_long_slv1 <= counter_long_slv1 + 1;
            if(counter_long_slv1 > 0  && counter_long_slv1 <= window_slv1) begin
                stop_slv1 <= 1'b0;
                en_vtc_slv1 <= 1'b0;
            end else begin
                stop_slv1 <= 1'b1;
                en_vtc_slv1 <= 1'b1;
            end
        end
        if (!en_step_slv2) begin counter_long_slv2 <= 0; end
        else if (en_step_slv2) begin   
            counter_long_slv2 <= counter_long_slv2 + 1;
            if(counter_long_slv2 > 0  && counter_long_slv2 <= window_slv2) begin
                stop_slv2 <= 1'b0;
                en_vtc_slv2 <= 1'b0;
            end else begin
                stop_slv2 <= 1'b1;
                en_vtc_slv2 <= 1'b1;
            end
        end

    end    
end
    
reg [7:0] counter_fine, counter_fine_slv1, counter_fine_slv2;
reg ce, inc;
reg ce_slv1, inc_slv1;
reg ce_slv2, inc_slv2;
wire increase_en, increase_en_slv1, increase_en_slv2;
assign increase_en = params_i[0];
assign increase_en_slv1 = params_slv_i[0];
assign increase_en_slv2 = params_slv_i[16];

always @(posedge clk_i) begin
    if (rst_i) begin 
        counter_fine <= 0;
        counter_fine_slv1 <= 0;
        counter_fine_slv2 <= 0; 
    end else begin
        if (!stop) begin
            counter_fine <= counter_fine + 1;
            if (counter_fine == 9) begin
                if (increase_en) begin 
                    ce <= 1'b1;     
                    inc <= 1'b1;
                end else begin
                    ce <= 1'b1;
                    inc <= 1'b0;
                end         
            end else if (counter_fine == 10) begin
                ce <= 1'b0;
            end else if (counter_fine >= FINE_PERIOD-1) begin
                counter_fine <= 0;
            end
        end else begin
            counter_fine <= 0;
        end
        if (!stop_slv1) begin
            counter_fine_slv1 <= counter_fine_slv1 + 1;
            if (counter_fine_slv1 == 9) begin
                if (increase_en_slv1) begin 
                    ce_slv1 <= 1'b1;     
                    inc_slv1 <= 1'b1;
                end else begin
                    ce_slv1 <= 1'b1;
                    inc_slv1 <= 1'b0;
                end         
            end else if (counter_fine_slv1 == 10) begin
                ce_slv1 <= 1'b0;
            end else if (counter_fine_slv1 >= FINE_PERIOD-1) begin
                counter_fine_slv1 <= 0;
            end
        end else begin
            counter_fine_slv1 <= 0;
        end
        if (!stop_slv2) begin
            counter_fine_slv2 <= counter_fine_slv2 + 1;
            if (counter_fine_slv2 == 9) begin
                if (increase_en_slv2) begin 
                    ce_slv2 <= 1'b1;     
                    inc_slv2 <= 1'b1;
                end else begin
                    ce_slv2 <= 1'b1;
                    inc_slv2 <= 1'b0;
                end         
            end else if (counter_fine_slv2 == 10) begin
                ce_slv2 <= 1'b0;
            end else if (counter_fine_slv2 >= FINE_PERIOD-1) begin
                counter_fine_slv2 <= 0;
            end
        end else begin
            counter_fine_slv2 <= 0;
        end

    end
end
    
localparam load = 1'b0;
localparam load_slv1 = 1'b0;
localparam load_slv2 = 1'b0;
wire pulsein;
wire pulsedelay;
assign pulsein = pulse_delay_tune;  
    
// ODELAYE3 #(
// .CASCADE("NONE"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
// .DELAY_FORMAT(DELAY_FORMAT), // (COUNT, TIME)
// .DELAY_TYPE(DELAY_TYPE), // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
// .DELAY_VALUE(DELAY_VALUE), // Output delay tap setting
// .IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
// .IS_RST_INVERTED(1'b0), // Optional inversion for RST
// .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // IDELAYCTRL clock input frequency in MHz (200.0-800.0).
// .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
// // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
// .UPDATE_MODE(UPDATE_MODE) // Determines when updates to the delay will take effect (ASYNC, MANUAL,
// // SYNC)
// )
// ODELAYE3_inst_master (
// .CASC_OUT(), // 1-bit output: Cascade delay output to IDELAY input cascade
// .CNTVALUEOUT(), // 9-bit output: Counter value output
// .DATAOUT(pulsedelay), // 1-bit output: Delayed data from ODATAIN input port
// .CASC_IN(1'b0), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
// .CASC_RETURN(0), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
// .CE(ce), // 1-bit input: Active-High enable increment/decrement input
// .CLK(clk_i), // 1-bit input: Clock input
// .CNTVALUEIN(), // 9-bit input: Counter value input
// .EN_VTC(en_vtc), // 1-bit input: Keep delay constant over VT
// .INC(inc), // 1-bit input: Increment/Decrement tap delay input
// .LOAD(load), // 1-bit input: Load DELAY_VALUE input
// .ODATAIN(pulsein), // 1-bit input: Data input
// .RST(rst_i) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
// );
    
//Add cascade wires
wire cascade_out_1;
wire cascade_out_2;
wire cascade_return_1;
wire cascade_return_2;
    
ODELAYE3 #(
    .CASCADE("MASTER"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
    .DELAY_FORMAT(DELAY_FORMAT), // (COUNT, TIME)
    .DELAY_TYPE(DELAY_TYPE), // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
    .DELAY_VALUE(DELAY_VALUE), // Output delay tap setting
    .IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
    .IS_RST_INVERTED(1'b0), // Optional inversion for RST
    .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // IDELAYCTRL clock input frequency in MHz (200.0-800.0).
    .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
    .UPDATE_MODE(UPDATE_MODE) // Determines when updates to the delay will take effect (ASYNC, MANUAL, SYNC)
)
ODELAYE3_inst_master (
    .CASC_OUT(cascade_out_1), // 1-bit output: Cascade delay output to IDELAY input cascade
    .CNTVALUEOUT(), // 9-bit output: Counter value output
    .DATAOUT(pulsedelay), // 1-bit output: Delayed data from ODATAIN input port
    .CASC_IN(1'b0), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
    .CASC_RETURN(cascade_return_1), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
    .CE(ce), // 1-bit input: Active-High enable increment/decrement input
    .CLK(clk_i), // 1-bit input: Clock input
    .CNTVALUEIN(), // 9-bit input: Counter value input
    .EN_VTC(en_vtc), // 1-bit input: Keep delay constant over VT
    .INC(inc), // 1-bit input: Increment/Decrement tap delay input
    .LOAD(load), // 1-bit input: Load DELAY_VALUE input
    .ODATAIN(pulsein), // 1-bit input: Data input
    .RST(rst_i) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
);


IDELAYE3 #(
  .CASCADE("SLAVE_MIDDLE"),               // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
  .DELAY_FORMAT(DELAY_FORMAT),          // Units of the DELAY_VALUE (COUNT, TIME)
  .DELAY_SRC("IDATAIN"),          // Delay input (DATAIN, IDATAIN); the cascaded
                                  // data path is selected by CASCADE, not by this
  .DELAY_TYPE(DELAY_TYPE),           // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
  .DELAY_VALUE(DELAY_VALUE),                // Input delay value setting
  .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
  .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
  .REFCLK_FREQUENCY(REFCLK_FREQUENCY),       // IDELAYCTRL clock input frequency in MHz (200.0-800.0)
  .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
                                  // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
  .UPDATE_MODE(UPDATE_MODE)           // Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                  // SYNC)
)
IDELAYE3_inst_slave (
    .CASC_OUT(cascade_out_2),       // 1-bit output: Cascade delay output to ODELAY input cascade
    .CNTVALUEOUT(), // 9-bit output: Counter value output
    .DATAOUT(cascade_return_1),         // 1-bit output: Delayed data output
    .CASC_IN(cascade_out_1),         // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
    .CASC_RETURN(cascade_return_2), // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
    .CE(ce_slv1),                   // 1-bit input: Active-High enable increment/decrement input
    .CLK(clk_i),                 // 1-bit input: Clock input
    .CNTVALUEIN(),   // 9-bit input: Counter value input
    .DATAIN(),           // 1-bit input: Data input from the logic
    .EN_VTC(en_vtc_slv1),           // 1-bit input: Keep delay constant over VT
    .IDATAIN(),         // 1-bit input: Data input from the IOBUF
    .INC(inc_slv1),                 // 1-bit input: Increment / Decrement tap delay input
    .LOAD(load_slv1),               // 1-bit input: Load DELAY_VALUE input
    .RST(rst_i)                  // 1-bit input: Asynchronous Reset to the DELAY_VALUE
);

ODELAYE3 #(
    .CASCADE("SLAVE_END"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
    .DELAY_FORMAT(DELAY_FORMAT), // (COUNT, TIME)
    .DELAY_TYPE(DELAY_TYPE), // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
    .DELAY_VALUE(DELAY_VALUE), // Output delay tap setting
    .IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
    .IS_RST_INVERTED(1'b0), // Optional inversion for RST
    .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // IDELAYCTRL clock input frequency in MHz (200.0-800.0).
    .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
    // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
    .UPDATE_MODE(UPDATE_MODE) // Determines when updates to the delay will take effect (ASYNC, MANUAL,
    // SYNC)
)
ODELAYE3_inst_slave (
    .CASC_OUT(), // 1-bit output: Cascade delay output to IDELAY input cascade, unused on SLAVE_END
    .CNTVALUEOUT(), // 9-bit output: Counter value output
    .DATAOUT(cascade_return_2), // 1-bit output: Delayed data from ODATAIN input port
    .CASC_IN(cascade_out_2), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
    .CASC_RETURN(1'b0), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
    .CE(ce_slv2), // 1-bit input: Active-High enable increment/decrement input
    .CLK(clk_i), // 1-bit input: Clock input
    .CNTVALUEIN(), // 9-bit input: Counter value input
    .EN_VTC(en_vtc_slv2), // 1-bit input: Keep delay constant over VT
    .INC(inc_slv2), // 1-bit input: Increment/Decrement tap delay input
    .LOAD(load_slv2), // 1-bit input: Load DELAY_VALUE input
    .ODATAIN(1'b0), // 1-bit input: Data input
    .RST(rst_i) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
);

OBUFDS #(
    .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
    .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_pulse_delay_fine (
    .O(pulse_p),     // Diff_p output (connect directly to top-level port)
    .OB(pulse_n),   // Diff_n output (connect directly to top-level port)
    .I(pulsedelay)      // Buffer input
   );
endmodule
