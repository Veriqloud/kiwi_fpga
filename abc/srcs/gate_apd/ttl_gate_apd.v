`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 03/04/2024 03:02:51 PM
// Design Name: Qline_turnkey
// Module Name: ttl_gate_apd
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Generate the gate signal for APD. Include the tune and fine delays
//
//              The gate is a 12-bit pattern covering one 12.5 ns period, shifted
//              out by an OSERDESE3 in 4:1 DDR mode (CLK = clk480, CLKDIV =
//              clk240, 960 Mb/s). One pattern bit is 1/(4*240 MHz) = 1.0417 ns,
//              so duty cycle and tune delay are both bit positions in that word:
//              the run of set bits gives the width, its offset gives the delay.
//              The ODELAY cascade in fine_delay then trims the position in ps.
// 
// Dependencies: 
//- ttl_reg_mngt.v
//- fine_delay.v
// 
// Revision 0.03 - Gate generated as a 12-bit OSERDESE3 pattern (1.0417 ns per
//                 bit) instead of a clk240 counter; fine_delay moved to clk240
//                 (DRC REQP-1743 requires ODELAY CLK == OSERDES CLKDIV)
// Revision 0.02 - Fix CDC edge-detect in ttl_params_240_r/80_r (compare [2] to
//                 fully-synchronized [1], not under-synchronized [0]); document
//                 delay_val (<=7) and duty_val (<=2) range constraints
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ttl_gate_apd #(
    //ODELAY3 module parameters    
    parameter DELAY_FORMAT = "COUNT", // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    parameter DELAY_TYPE = "VARIABLE",
    parameter DELAY_VALUE = 50,  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
    parameter REFCLK_FREQUENCY = 300, // 
    parameter UPDATE_MODE = "ASYNC",
    //AXIL parameters    
    parameter integer C_s_axil_DATA_WIDTH   = 32,
    parameter integer C_s_axil_ADDR_WIDTH   = 8
)(
    //Ports of Axi Slave Bus interface
    input   wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_awaddr,
    input   wire [2 : 0]                            s_axil_awprot,
    input   wire                                    s_axil_awvalid,
    output  wire                                    s_axil_awready,
    input   wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_wdata,
    input   wire [(C_s_axil_DATA_WIDTH/8)-1 : 0]    s_axil_wstrb,
    input   wire                                    s_axil_wvalid,
    output  wire                                    s_axil_wready,
    output  wire [1 : 0]                            s_axil_bresp,
    output  wire                                    s_axil_bvalid,
    input   wire                                    s_axil_bready,
    input   wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_araddr,
    input   wire [2 : 0]                            s_axil_arprot,
    input   wire                                    s_axil_arvalid,
    output  wire                                    s_axil_arready,
    output  wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_rdata,
    output  wire [1 : 0]                            s_axil_rresp,
    output  wire                                    s_axil_rvalid,
    input   wire                                    s_axil_rready,
    input   s_axil_aclk,
    input   s_axil_aresetn,

    //input clocks and reset
    input   clk240,     // OSERDESE3 CLKDIV, and CLK of every delay primitive
    input   clk480,     // OSERDESE3 CLK; DDR on this clock gives 960 Mb/s
    input   ttl_rst,
    input   pps_i,
    
    //output with/without delay pulse 
    output  pulse_p,
    output  pulse_n,
    output  pulse_rep_p,
    output  pulse_rep_n
    );


//Axil registers
wire [31:0] ttl_params_o;
wire [31:0] ttl_params_slv_o;
wire [31:0] ttl_pattern_o;
wire ttl_params_en_o;
wire ttl_trigger_enstep_o, ttl_trigger_enstep_slv1_o, ttl_trigger_enstep_slv2_o;
ttl_axil_mngt # ( 
    .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
) ttl_axil_mngt_inst (
    .ttl_trigger_enstep_o(ttl_trigger_enstep_o),              //en_step trigger master
    .ttl_trigger_enstep_slv1_o(ttl_trigger_enstep_slv1_o),    //en_step trigger slave1
    .ttl_trigger_enstep_slv2_o(ttl_trigger_enstep_slv2_o),    //en_step trigger slave2
    .ttl_params_o(ttl_params_o),                              //parameters for master
    .ttl_params_slv_o(ttl_params_slv_o),                      //parameters for slaves
    .ttl_pattern_o(ttl_pattern_o),                            //12-bit gate pattern
    .ttl_params_en_o(ttl_params_en_o),                        //save parameters to regs
    .S_AXI_ACLK(s_axil_aclk),
    .S_AXI_ARESETN(s_axil_aresetn),
    .S_AXI_AWADDR(s_axil_awaddr),
    .S_AXI_AWPROT(s_axil_awprot),
    .S_AXI_AWVALID(s_axil_awvalid),
    .S_AXI_AWREADY(s_axil_awready),
    .S_AXI_WDATA(s_axil_wdata),
    .S_AXI_WSTRB(s_axil_wstrb),
    .S_AXI_WVALID(s_axil_wvalid),
    .S_AXI_WREADY(s_axil_wready),
    .S_AXI_BRESP(s_axil_bresp),
    .S_AXI_BVALID(s_axil_bvalid),
    .S_AXI_BREADY(s_axil_bready),
    .S_AXI_ARADDR(s_axil_araddr),
    .S_AXI_ARPROT(s_axil_arprot),
    .S_AXI_ARVALID(s_axil_arvalid),
    .S_AXI_ARREADY(s_axil_arready),
    .S_AXI_RDATA(s_axil_rdata),
    .S_AXI_RRESP(s_axil_rresp),
    .S_AXI_RVALID(s_axil_rvalid),
    .S_AXI_RREADY(s_axil_rready)
);

// Change clock domain for registers, from axil to 240MHz. The whole gate
// datapath (pattern, serializer, delay cascade) lives in clk240, so one
// synchronizer covers all of it.
(* ASYNC_REG = "TRUE" *) reg [2:0] ttl_params_240_r;
reg [31:0] ttl_params_240;
reg [31:0] ttl_params_slv;
reg [11:0] ttl_pattern_240;
initial begin
    ttl_params_240_r <= 0;
    ttl_params_240 <= 0;
    ttl_params_slv <= 0;
    ttl_pattern_240 <= 0;
end
always @(posedge clk240) begin
    ttl_params_240_r <= {ttl_params_240_r[1:0],ttl_params_en_o};
    if ((ttl_params_240_r[2] == 0) && (ttl_params_240_r[1] == 1)) begin
        ttl_params_240 <= ttl_params_o;
        ttl_params_slv <= ttl_params_slv_o;
        ttl_pattern_240 <= ttl_pattern_o[11:0];
    end
end

//Generate reset in 240MHz domain
(* ASYNC_REG = "TRUE" *) reg [2:0] ttl_rst240_r;
initial begin
    ttl_rst240_r <= 0;
end
always @(posedge clk240) begin
    ttl_rst240_r <= {ttl_rst240_r[1:0],ttl_rst};
end

wire clk240_o;
wire ttl_rst240_o;
wire ttl_rstn240_o;

reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_clk240_inst (
    .clk_i(clk240),
    .rst_i(ttl_rst240_r[1]),
    .clk_o(clk240_o),
    .rstn_o(ttl_rstn240_o),
    .rst_o(ttl_rst240_o));

//Generate PPS trigger signal
// Note: pps_i is sampled with a single flop, unlike the ASYNC_REG chains used
// above for ttl_params_*/ttl_rst*. No timing relationship to clk240 is
// declared in the XDC for this pin, so it is effectively asynchronous here
// regardless of the source clock relationship. Open item for later review.
reg pps_trigger;
reg pps_r;
always @(posedge clk240) begin
    if (ttl_rst240_o) begin
        pps_trigger <= 1'b0;
        pps_r <= 0;
    end else begin
        pps_r <= pps_i;
        if (!pps_r && pps_i) begin
            pps_trigger <= 1'b1;
        end
    end
end

//Generate the pulse. The 12-bit pattern in ttl_pattern_240 covers one 12.5 ns
//gate period at 1.0417 ns per bit; bit 0 is the first slot after pps_trigger.
//OSERDESE3 sends D[0] first, so the pattern goes out low bit first, one nibble
//per clk240 cycle, three nibbles per period.
reg [1:0] phase;
initial begin
    phase <= 0;
end
always @(posedge clk240) begin
    if (ttl_rst240_o || !pps_trigger) begin
        phase <= 2'd0;
    end else begin
        phase <= (phase == 2'd2) ? 2'd0 : phase + 2'd1;
    end
end

reg [3:0] gate_nibble;
always @* begin
    if (!pps_trigger) begin
        gate_nibble = 4'b0000;
    end else begin
        case (phase)
            2'd0:    gate_nibble = ttl_pattern_240[3:0];
            2'd1:    gate_nibble = ttl_pattern_240[7:4];
            default: gate_nibble = ttl_pattern_240[11:8];
        endcase
    end
end

wire pulse_delay_tune;
wire pulse_rep;

OSERDESE3 #(
    .DATA_WIDTH(4),                 // 4 bits per CLKDIV cycle, DDR on CLK: 960 Mb/s
    .INIT(1'b0),
    .ODDR_MODE("FALSE"),
    .OSERDES_D_BYPASS("FALSE"),
    .OSERDES_T_BYPASS("FALSE"),
    .SIM_DEVICE("ULTRASCALE_PLUS")
) OSERDESE3_pulse (
    .OQ(pulse_delay_tune),  // 1-bit output: serialized data, drives the ODELAY chain
    .T_OUT(),               // 1-bit output: 3-state control, unused
    .CLK(clk480),           // 1-bit input: fast clock, DDR
    .CLKDIV(clk240),        // 1-bit input: divided clock, must match ODELAY CLK
    .D({4'b0000, gate_nibble}), // 8-bit input: only D[3:0] used at DATA_WIDTH 4
    .RST(ttl_rst240_o),     // 1-bit input: active-High reset
    .T(1'b0)                // 1-bit input: 3-state input, output always driven
);

// Coarse replica of the gate, one clk240 cycle granularity
assign pulse_rep = |gate_nibble;

OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_pulse_rep (
      .O(pulse_rep_p),     // Diff_p output (connect directly to top-level port)
      .OB(pulse_rep_n),   // Diff_n output (connect directly to top-level port)
      .I(pulse_rep)      // Buffer input
   );

//Instantiate fine delay module
fine_delay #(
    .DELAY_FORMAT(DELAY_FORMAT), // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    .DELAY_TYPE(DELAY_TYPE),
    .DELAY_VALUE(DELAY_VALUE),  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
    .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // 
    .UPDATE_MODE(UPDATE_MODE),
    .CLK_RATIO(3)   // clk_i is 240 MHz
) fine_delay_inst (
    .clk_i(clk240),
    .rst_i(ttl_rst240_o),
    .pulse_delay_tune(pulse_delay_tune),
    .pulse_p(pulse_p),
    .pulse_n(pulse_n),
    .params_i(ttl_params_240),
    .params_slv_i(ttl_params_slv),  
    .ttl_trigger_enstep_o(ttl_trigger_enstep_o),
    .ttl_trigger_enstep_slv1_o(ttl_trigger_enstep_slv1_o),
    .ttl_trigger_enstep_slv2_o(ttl_trigger_enstep_slv2_o)
);


// //Fine delay
// //ODELAY3 Master
// reg [25:0] counter_long;
// reg [25:0] counter_long_slv1;
// reg [25:0] counter_long_slv2;
// wire [13:0] resolution;
// wire [13:0] resolution_slv1;
// wire [13:0] resolution_slv2;

// assign resolution = ttl_params_80[14:1];
// assign resolution_slv1 = ttl_params_slv[14:1];
// assign resolution_slv2 = ttl_params_slv[30:17];
// //Passing domaine
// wire en_step, en_step_slv1, en_step_slv2;
// (* ASYNC_REG = "TRUE" *) reg [2:0] ttl_trigger_enstep_r;
// (* ASYNC_REG = "TRUE" *) reg [2:0] ttl_trigger_enstep_slv1_r;
// (* ASYNC_REG = "TRUE" *) reg [2:0] ttl_trigger_enstep_slv2_r;
// initial begin
//     ttl_trigger_enstep_r <= 0;
//     ttl_trigger_enstep_slv1_r <= 0;
//     ttl_trigger_enstep_slv2_r <= 0;
// end
// always @(posedge clk80) begin
//     ttl_trigger_enstep_r <= {ttl_trigger_enstep_r[1:0],ttl_trigger_enstep_o};
//     ttl_trigger_enstep_slv1_r <= {ttl_trigger_enstep_slv1_r[1:0],ttl_trigger_enstep_slv1_o};
//     ttl_trigger_enstep_slv2_r <= {ttl_trigger_enstep_slv2_r[1:0],ttl_trigger_enstep_slv2_o};
// end
// assign en_step = ttl_trigger_enstep_r[0];
// assign en_step_slv1 = ttl_trigger_enstep_slv1_r[0];
// assign en_step_slv2 = ttl_trigger_enstep_slv2_r[0];

// reg stop, stop_slv1, stop_slv2;
// reg en_vtc, en_vtc_slv1, en_vtc_slv2;
// initial begin
//     stop <= 1;
//     stop_slv1 <= 1;
//     stop_slv2 <= 1;
//     en_vtc <= 1;
//     en_vtc_slv1 <= 1;
//     en_vtc_slv2 <= 1;
// end
// always @(posedge clk80) begin
//     if (ttl_rst80_o) begin 
//         counter_long <= resolution + 1;
//         counter_long_slv1 <= resolution_slv1 + 1;
//         counter_long_slv2 <= resolution_slv2 + 1; 
//     end else begin
//         if (!en_step) begin counter_long <= 0; end
//         else if (en_step) begin   
//             counter_long <= counter_long + 1;
//             if(counter_long > 0  && counter_long <= resolution) begin
//                 stop <= 1'b0;
//                 en_vtc <= 1'b0;
//             end else begin
//                 stop <= 1'b1;
//                 en_vtc <= 1'b1;
//             end
//         end
//         if (!en_step_slv1) begin counter_long_slv1 <= 0; end
//         else if (en_step_slv1) begin   
//             counter_long_slv1 <= counter_long_slv1 + 1;
//             if(counter_long_slv1 > 0  && counter_long_slv1 <= resolution_slv1) begin
//                 stop_slv1 <= 1'b0;
//                 en_vtc_slv1 <= 1'b0;
//             end else begin
//                 stop_slv1 <= 1'b1;
//                 en_vtc_slv1 <= 1'b1;
//             end
//         end
//         if (!en_step_slv2) begin counter_long_slv2 <= 0; end
//         else if (en_step_slv2) begin   
//             counter_long_slv2 <= counter_long_slv2 + 1;
//             if(counter_long_slv2 > 0  && counter_long_slv2 <= resolution_slv2) begin
//                 stop_slv2 <= 1'b0;
//                 en_vtc_slv2 <= 1'b0;
//             end else begin
//                 stop_slv2 <= 1'b1;
//                 en_vtc_slv2 <= 1'b1;
//             end
//         end

//     end    
// end

// reg [4:0] counter_fine, counter_fine_slv1, counter_fine_slv2;
// reg ce, inc;
// reg ce_slv1, inc_slv1;
// reg ce_slv2, inc_slv2;
// wire increase_en, increase_en_slv1, increase_en_slv2;
// assign increase_en = ttl_params_80[0];
// assign increase_en_slv1 = ttl_params_slv[0];
// assign increase_en_slv2 = ttl_params_slv[16];

// always @(posedge clk80) begin
//     if (ttl_rst80_o) begin 
//         counter_fine <= 0;
//         counter_fine_slv1 <= 0;
//         counter_fine_slv2 <= 0; 
//     end else begin
//         if (!stop) begin
//             counter_fine <= counter_fine + 1;
//             if (counter_fine == 9) begin
//                 if (increase_en) begin 
//                     ce <= 1'b1;     
//                     inc <= 1'b1;
//                 end else begin
//                     ce <= 1'b1;
//                     inc <= 1'b0;
//                 end         
//             end else if (counter_fine == 10) begin
//                 ce <= 1'b0;
//             end else if (counter_fine >= 16) begin
//                 counter_fine <= 0;
//             end
//         end else begin
//             counter_fine <= 0;
//         end
//         if (!stop_slv1) begin
//             counter_fine_slv1 <= counter_fine_slv1 + 1;
//             if (counter_fine_slv1 == 9) begin
//                 if (increase_en_slv1) begin 
//                     ce_slv1 <= 1'b1;     
//                     inc_slv1 <= 1'b1;
//                 end else begin
//                     ce_slv1 <= 1'b1;
//                     inc_slv1 <= 1'b0;
//                 end         
//             end else if (counter_fine_slv1 == 10) begin
//                 ce_slv1 <= 1'b0;
//             end else if (counter_fine_slv1 >= 16) begin
//                 counter_fine_slv1 <= 0;
//             end
//         end else begin
//             counter_fine_slv1 <= 0;
//         end
//         if (!stop_slv2) begin
//             counter_fine_slv2 <= counter_fine_slv2 + 1;
//             if (counter_fine_slv2 == 9) begin
//                 if (increase_en_slv2) begin 
//                     ce_slv2 <= 1'b1;     
//                     inc_slv2 <= 1'b1;
//                 end else begin
//                     ce_slv2 <= 1'b1;
//                     inc_slv2 <= 1'b0;
//                 end         
//             end else if (counter_fine_slv2 == 10) begin
//                 ce_slv2 <= 1'b0;
//             end else if (counter_fine_slv2 >= 16) begin
//                 counter_fine_slv2 <= 0;
//             end
//         end else begin
//             counter_fine_slv2 <= 0;
//         end

//     end
// end

// //wire cntvalueout;
// localparam load = 0;
// localparam load_slv1 = 0;
// localparam load_slv2 = 0;
// wire pulsein;
// wire pulsedelay;
// assign pulsein = pulse_delay_tune;



// // ODELAYE3 #(
// // .CASCADE("NONE"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
// // .DELAY_FORMAT(DELAY_FORMAT), // (COUNT, TIME)
// // .DELAY_TYPE(DELAY_TYPE), // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
// // .DELAY_VALUE(DELAY_VALUE), // Output delay tap setting
// // .IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
// // .IS_RST_INVERTED(1'b0), // Optional inversion for RST
// // .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // IDELAYCTRL clock input frequency in MHz (200.0-800.0).
// // .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
// // // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
// // .UPDATE_MODE(UPDATE_MODE) // Determines when updates to the delay will take effect (ASYNC, MANUAL,
// // // SYNC)
// // )
// // ODELAYE3_inst_master (
// // .CASC_OUT(), // 1-bit output: Cascade delay output to IDELAY input cascade
// // .CNTVALUEOUT(), // 9-bit output: Counter value output
// // .DATAOUT(pulsedelay), // 1-bit output: Delayed data from ODATAIN input port
// // .CASC_IN(1'b0), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
// // .CASC_RETURN(0), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
// // .CE(ce), // 1-bit input: Active-High enable increment/decrement input
// // .CLK(clk80), // 1-bit input: Clock input
// // .CNTVALUEIN(), // 9-bit input: Counter value input
// // .EN_VTC(en_vtc), // 1-bit input: Keep delay constant over VT
// // .INC(inc), // 1-bit input: Increment/Decrement tap delay input
// // .LOAD(load), // 1-bit input: Load DELAY_VALUE input
// // .ODATAIN(pulsein), // 1-bit input: Data input
// // .RST(ttl_rst80_o) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
// // );

// //Add cascade wires
// wire cascade_out_1;
// wire cascade_out_2;
// wire cascade_return_1;
// wire cascade_return_2;

// ODELAYE3 #(
// .CASCADE("MASTER"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
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
// .CASC_OUT(cascade_out_1), // 1-bit output: Cascade delay output to IDELAY input cascade
// .CNTVALUEOUT(), // 9-bit output: Counter value output
// .DATAOUT(pulsedelay), // 1-bit output: Delayed data from ODATAIN input port
// .CASC_IN(1'b0), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
// .CASC_RETURN(cascade_return_1), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
// .CE(ce), // 1-bit input: Active-High enable increment/decrement input
// .CLK(clk80), // 1-bit input: Clock input
// .CNTVALUEIN(), // 9-bit input: Counter value input
// .EN_VTC(en_vtc), // 1-bit input: Keep delay constant over VT
// .INC(inc), // 1-bit input: Increment/Decrement tap delay input
// .LOAD(load), // 1-bit input: Load DELAY_VALUE input
// .ODATAIN(pulsein), // 1-bit input: Data input
// .RST(ttl_rst80_o) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
// );


// IDELAYE3 #(
//   .CASCADE("SLAVE_MIDDLE"),               // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
//   .DELAY_FORMAT(DELAY_FORMAT),          // Units of the DELAY_VALUE (COUNT, TIME)
//   .DELAY_SRC("CASC_IN"),          // Delay input (DATAIN, IDATAIN)
//   .DELAY_TYPE(DELAY_TYPE),           // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
//   .DELAY_VALUE(DELAY_VALUE),                // Input delay value setting
//   .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
//   .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
//   .REFCLK_FREQUENCY(REFCLK_FREQUENCY),       // IDELAYCTRL clock input frequency in MHz (200.0-800.0)
//   .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
//                                   // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
//   .UPDATE_MODE(UPDATE_MODE)           // Determines when updates to the delay will take effect (ASYNC, MANUAL,
//                                   // SYNC)
// )
// IDELAYE3_inst_slave (
//   .CASC_OUT(cascade_out_2),       // 1-bit output: Cascade delay output to ODELAY input cascade
//   .CNTVALUEOUT(), // 9-bit output: Counter value output
//   .DATAOUT(cascade_return_1),         // 1-bit output: Delayed data output
//   .CASC_IN(cascade_out_1),         // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
//   .CASC_RETURN(cascade_return_2), // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
//   .CE(ce_slv1),                   // 1-bit input: Active-High enable increment/decrement input
//   .CLK(clk80),                 // 1-bit input: Clock input
//   .CNTVALUEIN(),   // 9-bit input: Counter value input
//   .DATAIN(),           // 1-bit input: Data input from the logic
//   .EN_VTC(en_vtc_slv1),           // 1-bit input: Keep delay constant over VT
//   .IDATAIN(),         // 1-bit input: Data input from the IOBUF
//   .INC(inc_slv1),                 // 1-bit input: Increment / Decrement tap delay input
//   .LOAD(load_slv1),               // 1-bit input: Load DELAY_VALUE input
//   .RST(ttl_rst80_o)                  // 1-bit input: Asynchronous Reset to the DELAY_VALUE
// );

// ODELAYE3 #(
// .CASCADE("SLAVE_END"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
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
// ODELAYE3_inst_slave (
// .CASC_OUT(1'b0), // 1-bit output: Cascade delay output to IDELAY input cascade
// .CNTVALUEOUT(), // 9-bit output: Counter value output
// .DATAOUT(cascade_return_2), // 1-bit output: Delayed data from ODATAIN input port
// .CASC_IN(cascade_out_2), // 1-bit input: Cascade delay input from slave IDELAY CASCADE_OUT
// .CASC_RETURN(1'b0), // 1-bit input: Cascade delay returning from slave IDELAY DATAOUT
// .CE(ce_slv2), // 1-bit input: Active-High enable increment/decrement input
// .CLK(clk80), // 1-bit input: Clock input
// .CNTVALUEIN(), // 9-bit input: Counter value input
// .EN_VTC(en_vtc_slv2), // 1-bit input: Keep delay constant over VT
// .INC(inc_slv2), // 1-bit input: Increment/Decrement tap delay input
// .LOAD(load_slv2), // 1-bit input: Load DELAY_VALUE input
// .ODATAIN(1'b0), // 1-bit input: Data input
// .RST(ttl_rst80_o) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
// );

// OBUFDS #(
//       .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
//       .SLEW("SLOW")           // Specify the output slew rate
//    ) OBUFDS_pulse_delay_fine (
//       .O(pulse_p),     // Diff_p output (connect directly to top-level port)
//       .OB(pulse_n),   // Diff_n output (connect directly to top-level port)
//       .I(pulsedelay)      // Buffer input
//    );
endmodule
