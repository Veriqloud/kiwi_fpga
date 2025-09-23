`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 04:31:05 PM
// Design Name: 
// Module Name: decoy_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for the decoy module
// 
// Dependencies: decoy.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module decoy_tb #(
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
)();

// module decoy#(
//     //ODELAY3 module parameters    
//     parameter DELAY_FORMAT = "COUNT", // recommend COUNT & VAR_ MODE, TIME and FIXED mode
//     parameter DELAY_TYPE = "VARIABLE",
//     parameter DELAY_VALUE = 50,  //need to be between 45-65 taps for IDELAY3 calibrates correctly/BISC process 
//     parameter REFCLK_FREQUENCY = 300, // 
//     parameter UPDATE_MODE = "ASYNC",
//     //AXIL parameters    
//     parameter integer C_s_axil_DATA_WIDTH   = 32,
//     parameter integer C_s_axil_ADDR_WIDTH   = 12
// )
// (
    //Ports of Axi Slave Bus interface
    reg   [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_awaddr;
    reg   [2 : 0]                            s_axil_awprot;
    reg                                      s_axil_awvalid;
    wire                                    s_axil_awready;
    reg  [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_wdata;
    reg  [(C_s_axil_DATA_WIDTH/8)-1 : 0]    s_axil_wstrb;
    reg                                     s_axil_wvalid;
    wire                                    s_axil_wready;
    wire [1 : 0]                            s_axil_bresp;
    wire                                    s_axil_bvalid;
    reg                                    s_axil_bready;
    reg [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_araddr;
    reg [2 : 0]                            s_axil_arprot;
    reg                                    s_axil_arvalid;
    wire                                    s_axil_arready;
    wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_rdata;
    wire [1 : 0]                            s_axil_rresp;
    wire                                    s_axil_rvalid;
    reg                                    s_axil_rready;
    reg   s_axil_aclk;
    reg   s_axil_aresetn;

    //clock and reset
    reg           clk240;
    reg           clk80;
    reg           clk200;
    reg           pps_i;
    reg           decoy_rst;
    //rng temp from fastdac
    reg [3:0]    rng_value; 
    reg          rd_en_4;
    reg          rng_value_valid;
    //output pulse
    wire          decoy_signal_p;
    wire          decoy_signal_n;

    //debug signal
    wire          counter;
    wire          temp_signal2;
    wire          temp_signal1;
    wire          rd_en_4_r;
    wire          rd_en_4_200_r;
    wire [1:0]    rng_a_r;
    wire [1:0]    rng_a;
    wire          decoy_signal;
    wire [3:0]    dpram_rng_dout;
    wire [2:0]    state_rng;
    wire          read_enable;
    wire [5:0]    sequence_rng_addr_r;
    wire [5:0]    decoy_dpram_max_addr_rng_r;
    wire [2:0]    decoy_rng_addr_int;
    wire [31:0]   decoy_rng_din_int;

    // Instantiate the Unit Under Test (UUT)
    decoy #(
        .DELAY_FORMAT(DELAY_FORMAT),
        .DELAY_TYPE(DELAY_TYPE),
        .DELAY_VALUE(DELAY_VALUE),
        .REFCLK_FREQUENCY(REFCLK_FREQUENCY),
        .UPDATE_MODE(UPDATE_MODE),
        .C_s_axil_DATA_WIDTH(C_s_axil_DATA_WIDTH),
        .C_s_axil_ADDR_WIDTH(C_s_axil_ADDR_WIDTH),
        .SIMULATION(SIMULATION)
    ) uut (
        // .clk200(clk200), 
        .pps_i(pps_i),
        .clk240(clk240),
        .clk80(clk80),
        .clk200(clk200),
        .decoy_rst(decoy_rst),
        .rng_value(rng_value), 
        .rd_en_4(rd_en_4), 
        .rng_value_valid(rng_value_valid),
        .decoy_signal(decoy_signal_p)
    );

    initial begin
        // Initialize Inputs
        // clk200 = 0;
        clk240 = 0; 
        clk80 = 0;
        clk200 = 0;
        decoy_rst = 1; // Added missing semicolon
        // tx_core_rst = 1;
        // Wait for global reset to finish
        #100
         decoy_rst = 0;
        #50400 
        decoy_rst = 1;
        #100 
        decoy_rst = 0;
    end
    initial begin
        rd_en_4 = 0;
        // rng_a = 1;
        #215 rd_en_4 = 0;
        forever begin
            #20 rd_en_4 = 1;
            #5 rd_en_4 = 0;
        end
    end

    initial begin
        rng_value_valid = 0;
        #225 rng_value_valid = 0;
        forever begin
            #20 rng_value_valid = 1;
            #5 rng_value_valid = 0;
        end
    end
    initial begin
        rng_value = 1;
        #220 rng_value = 1;
        forever begin
            #25 rng_value = 1;
            #25 rng_value = 2;
            #25 rng_value = 3;
        end
    end
    initial begin
        pps_i = 0;
        #230 pps_i = 1;
        forever begin
            #1000 pps_i = 0;
            #9000 pps_i = 1;
        end
    end

    // always #2.5 clk200 = ~clk200; // Generate clock with 5ns period (250MHz)
    initial begin
        #2.55 clk240 = 1;
        forever begin 
            #2.083333333 clk240 = ~clk240; // Generate clock with 4.166ns period (240MHz)
        end
    end
    initial begin
        #2.55 clk80 = 1;
        forever begin 
            #6.25 clk80 = ~clk80; // Generate clock with 4.166ns period (240MHz)
        end
    end
    initial begin
        #2.55 clk200 = 1;
        forever begin 
            #5 clk200 = ~clk200; // Generate clock with 4.166ns period (240MHz)
        end
    end
endmodule
