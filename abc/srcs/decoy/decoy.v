`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
// 
// Create Date: 03/25/2025 03:42:53 PM
// Design Name: Qline_turnkey
// Module Name: decoy
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Generate pulse to bias Amplitude Modulator
// 
// Dependencies: fine_delay.v
// Revision: 0.02
// Revision 0.01 - File Created
// Revision 0.02 - Reset clk200-domain regs on rst_200_o; state_rng default
//                 recovers to IDLE_SR; removed dead rng_a_r_test debug signal; gave
//                 counter/rd_en_4_r explicit port widths
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module decoy#(
    //ODELAY3 module parameters    
    parameter DELAY_FORMAT = "COUNT", // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    parameter DELAY_TYPE = "VARIABLE",
    parameter DELAY_VALUE = 50,  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
    parameter REFCLK_FREQUENCY = 300, // 
    parameter UPDATE_MODE = "ASYNC",
    //AXIL parameters    
    parameter integer C_s_axil_DATA_WIDTH   = 32,
    parameter integer C_s_axil_ADDR_WIDTH   = 12,
    parameter SIMULATION = 1 //1 for simulation, 0 for synthesis
)
(
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

    //clock and reset
    input           clk240,
    input           clk80,
    input           clk200,
    input           pps10_i,    // PPS synchronous to clk10 (pps_timebase), used in clk240
    input           pps200_i,   // PPS synchronous to clk200 (pps_timebase)
    input           decoy_rst,
    //rng temp from fastdac
    input   wire [1:0]    rng_value, 
    input                 rd_en_4,
    //output pulse
    output          decoy_signal_p,
    output          decoy_signal_n,
    //output registers
    output reg  [15:0]   rdec_p0_r,   

    //debug signal
    output [2:0]    counter,
    output          temp_signal2,
    output          temp_signal1,
    output [4:0]    rng_xfer_dbg,   // {update strobe, clk240 symbol index}
    output [1:0]    rng_a_r,
    output [1:0]    rng_a,
    output          decoy_signal,
    output [3:0]    dpram_rng_dout, 
    output [2:0]    state_rng,
    output          read_enable,
    output [5:0]    sequence_rng_addr_r,
    output [5:0]    decoy_dpram_max_addr_rng_r,
    output [2:0]    decoy_rng_addr_int,
    output [31:0]   decoy_rng_din_int
);


//Axil registers
wire reg_enable_o; //enable writing to regs
wire [3:0] tune_step_o; //tune step
wire decoy_trigger_enstep_o; //trigger enable step
wire decoy_trigger_enstep_slv1_o; //trigger enable step
wire decoy_trigger_enstep_slv2_o; //trigger enable step  
wire [31:0] decoy_params_80_o; //decoy params
wire [31:0] decoy_params_slv_o; //decoy params
wire decoy_rng_mode_o; //decoy rng mode
wire decoy_rng_wen_int; //decoy rng write enable
wire [2:0] decoy_rng_addr_int; //decoy rng address
wire [31:0] decoy_rng_din_int; //decoy rng data in
wire [5:0] decoy_dpram_max_addr_rng_int; //decoy dpram max address
wire [15:0] rdec_p0_o; //range-decoder P0 (raw AXIL value, s_axil_aclk domain)



decoy_axil_mngt # ( 
    .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
) decoy_axil_mngt_inst (
    .reg_enable_o(reg_enable_o),              //enable writing to regs
    .tune_step_o(tune_step_o),            //tune step
    .trigger_enstep_o(decoy_trigger_enstep_o), //trigger enable step
    .trigger_enstep_slv1_o(decoy_trigger_enstep_slv1_o), //trigger enable step
    .trigger_enstep_slv2_o(decoy_trigger_enstep_slv2_o), //trigger enable step
    .decoy_params_80_o(decoy_params_80_o), //decoy params
    .decoy_params_slv_o(decoy_params_slv_o), //decoy params
    .decoy_rng_mode_o(decoy_rng_mode_o), //decoy rng mode
    .decoy_rng_wen_int(decoy_rng_wen_int), //decoy rng write enable
    .decoy_rng_addr_int(decoy_rng_addr_int), //decoy rng address
    .decoy_rng_din_int(decoy_rng_din_int), //decoy rng data in
    .decoy_dpram_max_addr_rng_int(decoy_dpram_max_addr_rng_int), //decoy dpram max address
    .rdec_p0_o(rdec_p0_o), //decoy rng p0
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

//Generate reset in clk240 domain
(* ASYNC_REG = "TRUE" *) reg [2:0] rst_240_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] rst_80_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] rst_200_r;
initial begin
    rst_240_r <= 0;
    rst_80_r <= 0;
    rst_200_r <= 0;
end
always @(posedge clk240) begin
    rst_240_r <= {rst_240_r[1:0],decoy_rst};
end
always @(posedge clk80) begin
    rst_80_r <= {rst_80_r[1:0],decoy_rst};
end
always @(posedge clk200) begin
    rst_200_r <= {rst_200_r[1:0],decoy_rst};
end 
            
wire clk240_o;
wire rst_240_o;
wire rstn_240_o;

reset_register #(.RST_ACTIVE_LEVEL("HIGH")) decoy_rst_240_inst (
    .clk_i(clk240),
    .rst_i(rst_240_r[1]),
    .clk_o(clk240_o),
    .rstn_o(rstn_240_o),
    .rst_o(rst_240_o));

wire clk80_o;
wire rst_80_o;
wire rstn_80_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_clk80_inst (
    .clk_i(clk80),
    .rst_i(rst_80_r[1]),
    .clk_o(clk80_o),
    .rstn_o(rstn_80_o),
    .rst_o(rst_80_o));

wire clk200_o;
wire rst_200_o;
wire rstn_200_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_clk200_inst (
    .clk_i(clk200),
    .rst_i(rst_200_r[1]),
    .clk_o(clk200_o),
    .rstn_o(rstn_200_o),
    .rst_o(rst_200_o));
    
//registers to domain clk200
(* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable_200_r;
reg [5:0] decoy_dpram_max_addr_rng_r;
reg decoy_rng_mode_r;
initial begin
    reg_enable_200_r = 0;
    decoy_dpram_max_addr_rng_r = 0;
    decoy_rng_mode_r = 0;
end
always @(posedge clk200) begin
    if(rst_200_o) begin
        reg_enable_200_r <= 0;
        decoy_dpram_max_addr_rng_r <= 0;
        decoy_rng_mode_r <= 0;
    end else begin
        reg_enable_200_r <= {reg_enable_200_r[1:0], reg_enable_o};
        if (reg_enable_200_r[2] == 0 && reg_enable_200_r[1] == 1) begin
            decoy_dpram_max_addr_rng_r <= decoy_dpram_max_addr_rng_int;
            decoy_rng_mode_r <= decoy_rng_mode_o;
        end
    end  
end
    
//Genererate RNG value
reg [5:0] sequence_rng_addr_r;
wire [3:0] dpram_rng_dout;
reg read_enable;
dpram_in_wider_out #(
    .RAM_INIT("decoy_rng_sequence.mem"),
    .WIDTHB(4),
    .SIZEB(64),
    .ADDRWIDTHB(6),
    .WIDTHA(32),
    .SIZEA(8),
    .ADDRWIDTHA(3))
dpram_seq_rng_16x4_inst(
    .clkA(s_axil_aclk), 
    .clkB(clk200), 
    .enaA(decoy_rng_wen_int), 
    .weA(decoy_rng_wen_int), 
    .enaB(read_enable), 
    .addrA(decoy_rng_addr_int), 
    .addrB(sequence_rng_addr_r), 
    .diA(decoy_rng_din_int[31:0]), 
    .doB(dpram_rng_dout)    
);
//State machine to readout the rng_test from dpram
reg [2:0] state_rng;
reg pps_200_r;
localparam IDLE_SR = 0, WAIT_SR = 1, SR0 = 2, SR1 = 3;
always @(posedge clk200) begin
    if(rst_200_o) begin
        sequence_rng_addr_r <= 0;
        pps_200_r <= 0;
        read_enable <= 0;
        state_rng <= IDLE_SR;
    end else begin
        case(state_rng)
            IDLE_SR: begin
                if (pps200_i) begin
                    state_rng <= IDLE_SR;
                end else state_rng <= WAIT_SR;
            end
            WAIT_SR: begin
                pps_200_r <= pps200_i;
                if (!pps_200_r && pps200_i) begin
                    state_rng <= SR0;
                    read_enable <= 1;
                end else state_rng <= WAIT_SR;
            end
            SR0: begin
                sequence_rng_addr_r <= 0;
                if (rd_en_4 == 1) begin
                    state_rng <= SR1;
                end
            end
            SR1: begin
                if (rd_en_4 == 1) begin
                    if (sequence_rng_addr_r == (decoy_dpram_max_addr_rng_r-1)) begin //Max_addr=64
                        sequence_rng_addr_r <= 0;
                    end else 
                        sequence_rng_addr_r <= sequence_rng_addr_r+1;                    
                    state_rng <= SR1;
                end
            end
            default: state_rng <= IDLE_SR;
        endcase
    end
end  

//Regiters from axil clock domain to clk240 domain
(* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable_240_r;
reg [3:0] tune_step_r;
reg decoy_rng_mode_240_r;
initial begin
    reg_enable_240_r = 0;
    tune_step_r = 0;
    decoy_rng_mode_240_r = 0;
end
always @(posedge clk240) begin
    if (rst_240_o) begin
        reg_enable_240_r <= 0;
        tune_step_r <= 0;
        decoy_rng_mode_240_r <= 0;
    end else begin
        reg_enable_240_r <= {reg_enable_240_r[1:0], reg_enable_o};
        if (reg_enable_240_r[2] == 0 && reg_enable_240_r[1] == 1) begin
            tune_step_r <= tune_step_o;
            decoy_rng_mode_240_r <= decoy_rng_mode_o;
        end  
    end
end

(* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable_80_r;
reg [31:0] decoy_params_80_r;
reg [31:0] decoy_params_slv_r;
initial begin
    reg_enable_80_r = 0;
    decoy_params_80_r = 0;
    decoy_params_slv_r = 0;
    rdec_p0_r = 0;
end
always @(posedge clk80) begin
    if (rst_80_o) begin
        reg_enable_80_r <= 0;
        decoy_params_80_r <= 0;
        decoy_params_slv_r <= 0;
        rdec_p0_r <= 0;
    end else begin
        reg_enable_80_r <= {reg_enable_80_r[1:0], reg_enable_o};
        if (reg_enable_80_r[2] == 0 && reg_enable_80_r[1] == 1) begin
            decoy_params_80_r <= decoy_params_80_o;
            decoy_params_slv_r <= decoy_params_slv_o;
            rdec_p0_r <= rdec_p0_o;
        end
    end
end


//Generate pattern corresponding to rng value 1 and 2
reg [2:0] counter;  // 3-bit counter
reg temp_signal2;
reg temp_signal1;
reg pps_r;
reg count_enable;
reg [1:0] state_temp;
localparam IDLE = 2'b00, WAIT = 2'b01, TRIGGER = 2'b10;
always @(posedge clk240) begin
    if (rst_240_o) begin
        counter <= 0;
        temp_signal2 <= 0;
        temp_signal1 <= 0;
        pps_r<= 0;
        state_temp <= IDLE;
    end else begin
        case(state_temp)
            IDLE: begin
                if (pps10_i) begin
                    state_temp <= IDLE;
                end else state_temp <= WAIT;
            end
            WAIT: begin
                pps_r <= pps10_i;
                if (!pps_r && pps10_i) begin
                    state_temp <= TRIGGER;
                end else state_temp <= WAIT;
            end
            TRIGGER: begin
                counter <= counter + 1;
                if (counter == 6) begin counter <= 1; end
                if (counter == 3 || counter == 4 || counter == 2) begin temp_signal2 <= 0; temp_signal1 <= 1; end
                else begin temp_signal2 <= 1; temp_signal1 <= 0; end               
            end
            default: state_temp <= IDLE;
        endcase
    end
end

//Generate nrg_a in clk200 domain to save to ddr
wire [1:0] rng_a;
// assign rng_a = rng_value[1:0];
assign rng_a = decoy_rng_mode_r?rng_value[1:0]:dpram_rng_dout[1:0];
// assign rng_a = decoy_rng_mode_r?dpram_rng_dout[1:0]:rng_value[1:0];

//rng_a crosses from clk200 to clk240 through a table indexed by the symbol
//number within the second. Each side counts its 40 MHz symbols from its own
//synchronous PPS (pps200_i, pps10_i), which mark the same second, so the entry
//written for symbol n is read for symbol n + RNG_XFER_LAG and no clock samples
//a signal from the other one. An entry is RNG_XFER_LAG symbols (200 ns) old
//when read and is rewritten 16 symbols (400 ns) after it was written, which
//leaves +-200 ns for the offset between pps10_i and pps200_i.
localparam integer RNG_XFER_AW = 4;
localparam [RNG_XFER_AW-1:0] RNG_XFER_LAG = 8;

//On both sides an event in the cycle of the PPS edge still belongs to the
//second that is ending; the index is 0 for the next event whatever the phase of
//the symbol grid.

//clk200 side: rng_a settles 2 cycles after the rd_en_4 tick and holds for 5,
//so it is written 3 cycles after the tick
(* ram_style = "registers" *) reg [1:0] rng_xfer_mem [0:(1<<RNG_XFER_AW)-1];
reg [2:0] rd_en_4_d;
reg pps200_d;
reg [RNG_XFER_AW-1:0] xfer_wr_sym;
initial begin
    rd_en_4_d = 0;
    pps200_d = 1;
    xfer_wr_sym = 0;
end
always @(posedge clk200) begin
    if (rst_200_o) begin
        rd_en_4_d <= 0;
        pps200_d <= 1;
        xfer_wr_sym <= 0;
    end else begin
        rd_en_4_d <= {rd_en_4_d[1:0], rd_en_4};
        pps200_d <= pps200_i;
        xfer_wr_sym <= (pps200_i && !pps200_d) ? 0 : xfer_wr_sym + rd_en_4_d[2];
    end
end
always @(posedge clk200) begin
    if (rd_en_4_d[2]) begin
        rng_xfer_mem[xfer_wr_sym] <= rng_a;
    end
end

//clk240 side: a symbol is counter 2..6,1, the temp_signal1 half then the
//temp_signal2 half; rng_a_r changes on the edge where counter == 2, so the
//first output slot of the symbol already uses the new value
reg pps10_d;
reg [RNG_XFER_AW-1:0] xfer_rd_sym;
reg xfer_update;
reg [1:0] rng_a_r;
wire symbol_start = (state_temp == TRIGGER) && (counter == 2);
initial begin
    pps10_d = 1;
    xfer_rd_sym = 0;
    xfer_update = 0;
    rng_a_r = 0;
end
always @(posedge clk240) begin
    if (rst_240_o) begin
        pps10_d <= 1;
        xfer_rd_sym <= 0;
        xfer_update <= 0;
        rng_a_r <= 0;
    end else begin
        pps10_d <= pps10_i;
        xfer_update <= symbol_start;
        if (symbol_start) begin
            rng_a_r <= rng_xfer_mem[xfer_rd_sym - RNG_XFER_LAG];
        end
        xfer_rd_sym <= (pps10_i && !pps10_d) ? 0 : xfer_rd_sym + symbol_start;
    end
end
assign rng_xfer_dbg = {xfer_update, xfer_rd_sym};

//Generate decoy signal
reg decoy_signal;
always @(posedge clk240) begin
    if (rst_240_o) begin
        decoy_signal <= 0;
    end else begin
        case(rng_a_r)
            2'b00: decoy_signal <= 0;
            2'b01: decoy_signal <= temp_signal1;
            2'b10: decoy_signal <= temp_signal2;
            2'b11: decoy_signal <= 1;
            default: decoy_signal <= 0;
        endcase
    end
end

//Tune delay of decoy signal
reg [7:0] decoy_signal_d;
always @(posedge clk240) begin
    decoy_signal_d <= {decoy_signal_d[6:0], decoy_signal};
end

wire decoy_signal_bufi;
assign decoy_signal_bufi = decoy_signal_d[tune_step_r];

//Instantiate fine delay module
fine_delay #(
    .DELAY_FORMAT(DELAY_FORMAT), // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    .DELAY_TYPE(DELAY_TYPE),
    .DELAY_VALUE(DELAY_VALUE),  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
    .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // 
    .UPDATE_MODE(UPDATE_MODE)
 ) fine_delay_de_inst (
    .clk_i(clk80),
    .clk_prim_i(clk80),
    .rst_i(rst_80_o),
    .pulse_delay_tune(decoy_signal_bufi),
    .pulse_p(decoy_signal_p),
    .pulse_n(decoy_signal_n),
    .params_i(decoy_params_80_r),
    .params_slv_i(decoy_params_slv_r),  
    .ttl_trigger_enstep_o(decoy_trigger_enstep_o),
    .ttl_trigger_enstep_slv1_o(decoy_trigger_enstep_slv1_o),
    .ttl_trigger_enstep_slv2_o(decoy_trigger_enstep_slv2_o)
);

endmodule
