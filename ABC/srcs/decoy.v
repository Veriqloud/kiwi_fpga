`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 03:42:53 PM
// Design Name: 
// Module Name: decoy
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


module decoy#(
    //ODELAY3 module parameters    
    parameter DELAY_FORMAT = "COUNT", // recommend COUNT & VAR_ MODE, TIME and FIXED mode
    parameter DELAY_TYPE = "VARIABLE",
    parameter DELAY_VALUE = 50,  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
    parameter REFCLK_FREQUENCY = 300, // 
    parameter UPDATE_MODE = "ASYNC",
    //AXIL parameters    
    parameter integer C_s_axil_DATA_WIDTH   = 32,
    parameter integer C_s_axil_ADDR_WIDTH   = 8
)
(
    //Ports of Axi Slave Bus interface
    input wire [C_s_axil_ADDR_WIDTH-1 : 0] s_axil_awaddr,
    input wire [2 : 0] s_axil_awprot,
    input wire  s_axil_awvalid,
    output wire  s_axil_awready,
    input wire [C_s_axil_DATA_WIDTH-1 : 0] s_axil_wdata,
    input wire [(C_s_axil_DATA_WIDTH/8)-1 : 0] s_axil_wstrb,
    input wire  s_axil_wvalid,
    output wire  s_axil_wready,
    output wire [1 : 0] s_axil_bresp,
    output wire  s_axil_bvalid,
    input wire  s_axil_bready,
    input wire [C_s_axil_ADDR_WIDTH-1 : 0] s_axil_araddr,
    input wire [2 : 0] s_axil_arprot,
    input wire  s_axil_arvalid,
    output wire  s_axil_arready,
    output wire [C_s_axil_DATA_WIDTH-1 : 0] s_axil_rdata,
    output wire [1 : 0] s_axil_rresp,
    output wire  s_axil_rvalid,
    input wire  s_axil_rready,
    input       s_axil_aclk,
    input       s_axil_aresetn,


    input clk240,
    input clk80,
    input pps_i,
    input decoy_rst,
    input rst_240,
    input wire [3:0]    rng_value, //rng temp from fastdac
    input wire          rd_en_4,
    input wire          pps_trigger,
    // output reg          decoy_signal,
    output decoy_signal_p,
    output decoy_signal_n,

    //debug signal
    output counter,
    output temp_signal2,
    output temp_signal1,
    output rd_en_4_r,
    output rng_a_r,
    output decoy_signal
    );


//Axil registers
    wire reg_enable_o; //enable writing to regs
    wire [3:0] tune_step_o; //tune step
    wire decoy_trigger_enstep_o; //trigger enable step
    wire decoy_trigger_enstep_slv1_o; //trigger enable step
    wire decoy_trigger_enstep_slv2_o; //trigger enable step  
    wire [31:0] decoy_params_80_o; //decoy params
    wire [31:0] decoy_params_slv_o; //decoy params
    decoy_reg_mngt_axil # ( 
            .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
            .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
    ) decoy_reg_mngt_axil_inst (
            .reg_enable_o(reg_enable_o),              //enable writing to regs
            .tune_step_o(tune_step_o),            //tune step
            .trigger_enstep_o(decoy_trigger_enstep_o), //trigger enable step
            .trigger_enstep_slv1_o(decoy_trigger_enstep_slv1_o), //trigger enable step
            .trigger_enstep_slv2_o(decoy_trigger_enstep_slv2_o), //trigger enable step
            .decoy_params_80_o(decoy_params_80_o), //decoy params
            .decoy_params_slv_o(decoy_params_slv_o), //decoy params
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

    //Regiters from axil clock domain to clk240 domain
    (* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable_240_r;
    reg [3:0] tune_step_r;
    initial begin
        reg_enable_240_r = 0;
        reg_enable_80_r = 0;
        tune_step_r = 0;
    end
    always @(posedge clk240) begin
        if (rst_240_o) begin
            reg_enable_240_r <= 0;
            tune_step_r <= 0;
        end else begin
            reg_enable_240_r <= {reg_enable_240_r[1:0], reg_enable_o};
            if (reg_enable_240_r[2] == 0 && reg_enable_240_r[1] == 1) begin
                tune_step_r <= tune_step_o;
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
    end
    always @(posedge clk80) begin
        if (rst_80_o) begin
            reg_enable_80_r <= 0;
            decoy_params_80_r <= 0;
            decoy_params_slv_r <= 0;
        end else begin
            reg_enable_80_r <= {reg_enable_80_r[1:0], reg_enable_o};
            if (reg_enable_80_r[2] == 0 && reg_enable_80_r[1] == 1) begin
                decoy_params_80_r <= decoy_params_80_o;
                decoy_params_slv_r <= decoy_params_slv_o;
            end            
        end
    end

    //Generate reset in clk240 domain
    (* ASYNC_REG = "TRUE" *) reg [2:0] rst_240_r;
    (* ASYNC_REG = "TRUE" *) reg [2:0] rst_80_r;
    initial begin
        rst_240_r <= 0;
        rst_80_r <= 0;
    end
    always @(posedge clk240) begin
        rst_240_r <= {rst_240_r[1:0],decoy_rst};
    end
    always @(posedge clk80) begin
        rst_80_r <= {rst_80_r[1:0],decoy_rst};
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
                    if (pps_i) begin
                        state_temp <= IDLE;
                    end else state_temp <= WAIT;
                end
                WAIT: begin
                    pps_r <= pps_i;
                    if (!pps_r && pps_i) begin
                        state_temp <= TRIGGER;
                    end else state_temp <= WAIT;
                end
                TRIGGER: begin
                    counter <= counter + 1;
                    if (counter == 6) begin counter <= 1; end
                    if (counter == 6 || counter == 1 || counter == 2) begin temp_signal2 <= 0; temp_signal1 <= 1; end
                    else begin temp_signal2 <= 1; temp_signal1 <= 0; end               
                end
                default: state_temp <= IDLE;
            endcase
        end
    end

    //Generate decoy signal
    reg [2:0] rd_en_4_r;
    reg [1:0] rng_a_r;
    initial begin
        rd_en_4_r = 0;
        rng_a_r = 0;
    end

    reg decoy_signal;
    always @(posedge clk240) begin
        if (rst_240_o) begin
        // if (rst_240) begin
            rd_en_4_r <= 0;
            rng_a_r <= 0;
            decoy_signal <= 0;
        end else begin
            rd_en_4_r <= {rd_en_4_r[1:0], rd_en_4};
            if (rd_en_4_r[2] == 0 && rd_en_4_r[1] == 1) begin
                // rng_a_r <= rng_a;
                rng_a_r <= rng_value[1:0];
            end
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
        // if (rst_240_o) begin
        //     decoy_signal_d <= 0;
        // end else decoy_signal_d <= {decoy_signal_d[6:0], decoy_signal};
        decoy_signal_d <= {decoy_signal_d[6:0], decoy_signal};
    end

    wire decoy_signal_bufi;
    assign decoy_signal_bufi = decoy_signal_d[tune_step_r];
    // OBUFDS #(
    //     .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
    //     .SLEW("SLOW")           // Specify the output slew rate
    // ) OBUFDS_decoy_signal (
    //     .O(decoy_signal_p),     // Diff_p output (connect directly to top-level port)
    //     .OB(decoy_signal_n),   // Diff_n output (connect directly to top-level port)
    //     .I(decoy_signal_bufi)      // Buffer input
    //  );

   //Instantiate fine delay module
    fine_delay #(
        .DELAY_FORMAT(DELAY_FORMAT), // recommend COUNT & VAR_ MODE, TIME and FIXED mode
        .DELAY_TYPE(DELAY_TYPE),
        .DELAY_VALUE(DELAY_VALUE),  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
        .REFCLK_FREQUENCY(REFCLK_FREQUENCY), // 
        .UPDATE_MODE(UPDATE_MODE)
     ) fine_delay_de_inst (
        .clk80(clk80),
        .ttl_rst80_o(rst_80_o),
        .pulse_delay_tune(decoy_signal_bufi),
        .pulse_p(decoy_signal_p),
        .pulse_n(decoy_signal_n),
        .ttl_params_80(decoy_params_80_r),
        .ttl_params_slv(decoy_params_slv_r),  
        .ttl_trigger_enstep_o(decoy_trigger_enstep_o),
        .ttl_trigger_enstep_slv1_o(decoy_trigger_enstep_slv1_o),
        .ttl_trigger_enstep_slv2_o(decoy_trigger_enstep_slv2_o)
    );

endmodule
