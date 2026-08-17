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
//              taken from the ttl_params_* registers. The delayed pulse leaves
//              through an OBUFDS as an LVDS pair.
//
// Dependencies: Xilinx ODELAYE3 / IDELAYE3 / OBUFDS primitives (UltraScale+).
//               Requires an IDELAYCTRL in the same I/O bank, clocked at
//               REFCLK_FREQUENCY, for the tap delay lines to be calibrated.
//
// Revision 0.01 - File Created
// Revision 0.02 - Header completed, port comments added
// Additional Comments:
// Tap stepping is rate-limited by counter_fine: one CE pulse every 16 clk80
// cycles, so a tune window of N cycles moves the line by about N/16 taps.
//////////////////////////////////////////////////////////////////////////////////


module fine_delay #(
    parameter DELAY_FORMAT = "COUNT", // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    parameter DELAY_TYPE = "VARIABLE",
    parameter DELAY_VALUE = 50,  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process
    parameter REFCLK_FREQUENCY = 300, // IDELAYCTRL reference clock, MHz (200.0-800.0)
    parameter UPDATE_MODE = "ASYNC"   // when tap updates take effect (ASYNC, MANUAL, SYNC)
)(
    input   clk80,              // 80 MHz control clock: tune engines and all delay primitives
    input   ttl_rst80_o,        // active-high reset, clk80 domain (input despite the _o suffix)
    input   pulse_delay_tune,   // pulse to be delayed, drives the master ODELAYE3 ODATAIN
    output  pulse_p,            // delayed pulse, LVDS positive leg (OBUFDS)
    output  pulse_n,            // delayed pulse, LVDS negative leg (OBUFDS)

    //AXIL registers
    // Master stage (ODELAYE3 MASTER) control word:
    //   [0]     increase_en - 1 = increment taps, 0 = decrement
    //   [14:1]  resolution  - tune window length in clk80 cycles (~/16 = tap steps)
    //   [31:15] unused
    input [31:0]    ttl_params_80,
    // Slave stages control word, two fields packed into one register:
    //   [0]     increase_en_slv1 - direction for the IDELAYE3 SLAVE_MIDDLE stage
    //   [14:1]  resolution_slv1  - tune window for the IDELAYE3 SLAVE_MIDDLE stage
    //   [15]    unused
    //   [16]    increase_en_slv2 - direction for the ODELAYE3 SLAVE_END stage
    //   [30:17] resolution_slv2  - tune window for the ODELAYE3 SLAVE_END stage
    //   [31]    unused
    input [31:0]    ttl_params_slv,
    // Tune triggers, asynchronous to clk80 (sourced from the AXIL clock domain).
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
    
assign resolution = ttl_params_80[14:1];
assign resolution_slv1 = ttl_params_slv[14:1];
assign resolution_slv2 = ttl_params_slv[30:17];

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
always @(posedge clk80) begin
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
always @(posedge clk80) begin
    if (ttl_rst80_o) begin 
        counter_long <= resolution + 1;
        counter_long_slv1 <= resolution_slv1 + 1;
        counter_long_slv2 <= resolution_slv2 + 1; 
    end else begin
        if (!en_step) begin counter_long <= 0; end
        else if (en_step) begin   
            counter_long <= counter_long + 1;
            if(counter_long > 0  && counter_long <= resolution) begin
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
            if(counter_long_slv1 > 0  && counter_long_slv1 <= resolution_slv1) begin
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
            if(counter_long_slv2 > 0  && counter_long_slv2 <= resolution_slv2) begin
                stop_slv2 <= 1'b0;
                en_vtc_slv2 <= 1'b0;
            end else begin
                stop_slv2 <= 1'b1;
                en_vtc_slv2 <= 1'b1;
            end
        end

    end    
end
    
reg [4:0] counter_fine, counter_fine_slv1, counter_fine_slv2;
reg ce, inc;
reg ce_slv1, inc_slv1;
reg ce_slv2, inc_slv2;
wire increase_en, increase_en_slv1, increase_en_slv2;
assign increase_en = ttl_params_80[0];
assign increase_en_slv1 = ttl_params_slv[0];
assign increase_en_slv2 = ttl_params_slv[16];

always @(posedge clk80) begin
    if (ttl_rst80_o) begin 
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
            end else if (counter_fine >= 16) begin
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
            end else if (counter_fine_slv1 >= 16) begin
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
            end else if (counter_fine_slv2 >= 16) begin
                counter_fine_slv2 <= 0;
            end
        end else begin
            counter_fine_slv2 <= 0;
        end

    end
end
    
localparam load = 0;
localparam load_slv1 = 0;
localparam load_slv2 = 0;
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
// .CLK(clk80), // 1-bit input: Clock input
// .CNTVALUEIN(), // 9-bit input: Counter value input
// .EN_VTC(en_vtc), // 1-bit input: Keep delay constant over VT
// .INC(inc), // 1-bit input: Increment/Decrement tap delay input
// .LOAD(load), // 1-bit input: Load DELAY_VALUE input
// .ODATAIN(pulsein), // 1-bit input: Data input
// .RST(ttl_rst80_o) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
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
    .CLK(clk80), // 1-bit input: Clock input
    .CNTVALUEIN(), // 9-bit input: Counter value input
    .EN_VTC(en_vtc), // 1-bit input: Keep delay constant over VT
    .INC(inc), // 1-bit input: Increment/Decrement tap delay input
    .LOAD(load), // 1-bit input: Load DELAY_VALUE input
    .ODATAIN(pulsein), // 1-bit input: Data input
    .RST(ttl_rst80_o) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
);


IDELAYE3 #(
  .CASCADE("SLAVE_MIDDLE"),               // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
  .DELAY_FORMAT(DELAY_FORMAT),          // Units of the DELAY_VALUE (COUNT, TIME)
  .DELAY_SRC("CASC_IN"),          // Delay input (DATAIN, IDATAIN)
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
    .CLK(clk80),                 // 1-bit input: Clock input
    .CNTVALUEIN(),   // 9-bit input: Counter value input
    .DATAIN(),           // 1-bit input: Data input from the logic
    .EN_VTC(en_vtc_slv1),           // 1-bit input: Keep delay constant over VT
    .IDATAIN(),         // 1-bit input: Data input from the IOBUF
    .INC(inc_slv1),                 // 1-bit input: Increment / Decrement tap delay input
    .LOAD(load_slv1),               // 1-bit input: Load DELAY_VALUE input
    .RST(ttl_rst80_o)                  // 1-bit input: Asynchronous Reset to the DELAY_VALUE
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
    .CASC_OUT(1'b0), // 1-bit output: Cascade delay output to IDELAY input cascade
    .CNTVALUEOUT(), // 9-bit output: Counter value output
    .DATAOUT(cascade_return_2), // 1-bit output: Delayed data from ODATAIN input port
    .CASC_IN(cascade_out_2), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
    .CASC_RETURN(1'b0), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
    .CE(ce_slv2), // 1-bit input: Active-High enable increment/decrement input
    .CLK(clk80), // 1-bit input: Clock input
    .CNTVALUEIN(), // 9-bit input: Counter value input
    .EN_VTC(en_vtc_slv2), // 1-bit input: Keep delay constant over VT
    .INC(inc_slv2), // 1-bit input: Increment/Decrement tap delay input
    .LOAD(load_slv2), // 1-bit input: Load DELAY_VALUE input
    .ODATAIN(1'b0), // 1-bit input: Data input
    .RST(ttl_rst80_o) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
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
