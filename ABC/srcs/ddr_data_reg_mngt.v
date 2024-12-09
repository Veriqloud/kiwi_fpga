`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2024 03:00:07 PM
// Design Name: 
// Module Name: ddr_data_reg_mngt
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


module ddr_data_reg_mngt #
    (
        // Users to add parameters here
        // User parameters ends
        // Do not modify the parameters beyond this line

        // Width of S_AXI data bus
        parameter integer C_s_axil_DATA_WIDTH    = 32,
        parameter integer C_s_axil_ADDR_WIDTH    = 12
    )
    (
        input clk200_i,
        output wire start_write_ddr_o,
        output wire command_enable_o,
        output wire command_alpha_enable_o,
        output wire command_gc_enable_o,
        output wire [2:0] command_o,
        output wire command_gc_o,
        output wire reg_enable_o,
        output wire [47:0] dq_gc_start_o,
        output wire [31:0] threshold_o,
        output wire [31:0] threshold_full_o,
        output wire [31:0] fiber_delay_o,
        output wire pair_delay_o,
        input wire [47:0] current_dq_gc_i,
        input wire        current_dq_gc_valid_i,
        input wire [8:0] ddr_fifos_status_i,
        input wire status_200_valid_i,
        input wire [2:0] fifos_status_i,
        input wire status_250_valid_i,
        // Ports of Axi Slave Bus Interface s_axil
        input wire  s_axil_aclk,
        input wire  s_axil_aresetn,
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
        input wire  s_axil_rready
    );

// //Change clock domain
// //Get value of current_gc -> host pc
// wire [47:0] current_dq_gc;
// // xpm_cdc_array_single: Single-bit Array Synchronizer
// // Xilinx Parameterized Macro, version 2024.1
// xpm_cdc_array_single #(
//    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
//    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
//    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//    .SRC_INPUT_REG(1),  // DECIMAL; 0=do not register input, 1=register input
//    .WIDTH(48)           // DECIMAL; range: 1-1024
// )
// current_dq_gc_inst (
//    .dest_out(current_dq_gc), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
//                         // output is registered.

//    .dest_clk(s_axil_aclk), // 1-bit input: Clock signal for the destination clock domain.
//    .src_clk(clk200_i),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
//    .src_in(current_dq_gc_i)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
//                         // domain. It is assumed that each bit of the array is unrelated to the others. This
//                         // is reflected in the constraints applied to this macro. To transfer a binary value
//                         // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
// );

// wire [31:0] current_dq_gc_lsb_i;
// wire [16:0] current_dq_gc_msb_i;
// assign current_dq_gc_lsb_i = current_dq_gc[31:0];
// assign current_dq_gc_msb_i = current_dq_gc[47:32];

wire [31:0] current_dq_gc_lsb_i;
wire [31:0] current_dq_gc_msb_i;
assign current_dq_gc_lsb_i = current_dq_gc_i[31:0];
assign current_dq_gc_msb_i = current_dq_gc_i[47:32];


// //Monitoring ddr_status
// wire [11:0] ddr_status;
// // xpm_cdc_array_single: Single-bit Array Synchronizer
// // Xilinx Parameterized Macro, version 2024.1
// xpm_cdc_array_single #(
//    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
//    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
//    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//    .SRC_INPUT_REG(1),  // DECIMAL; 0=do not register input, 1=register input
//    .WIDTH(12)           // DECIMAL; range: 1-1024
// )
// ddr_status_inst (
//    .dest_out(ddr_status), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
//                         // output is registered.

//    .dest_clk(s_axil_aclk), // 1-bit input: Clock signal for the destination clock domain.
//    .src_clk(clk200_i),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
//    .src_in(ddr_status_i)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
//                         // domain. It is assumed that each bit of the array is unrelated to the others. This
//                         // is reflected in the constraints applied to this macro. To transfer a binary value
//                         // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
// );

//Get value of dq_gc_start from host pc -> ddr_data
wire [31:0] dq_gc_start_lsb_o;
wire [15:0] dq_gc_start_msb_o;
assign dq_gc_start_o = {dq_gc_start_msb_o[15:0],dq_gc_start_lsb_o[31:0]};


// Instantiation of Axi Bus Interface s_axil
ddr_data_axil_mngt # ( 
    .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
  ) ddr_data_axil_mngt_inst (
    .start_write_ddr_o(start_write_ddr_o),
    .command_enable_o(command_enable_o),
    .command_alpha_enable_o(command_alpha_enable_o),
    .command_gc_enable_o(command_gc_enable_o),
    .command_o(command_o),
    .command_gc_o(command_gc_o),
    .reg_enable_o(reg_enable_o),
    .dq_gc_start_lsb_o(dq_gc_start_lsb_o),
    .dq_gc_start_msb_o(dq_gc_start_msb_o),
    .threshold_o(threshold_o),
    .threshold_full_o(threshold_full_o),
    .fiber_delay_o(fiber_delay_o),
    .pair_delay_o(pair_delay_o),
    .current_dq_gc_lsb_i(current_dq_gc_lsb_i),
    .current_dq_gc_msb_i(current_dq_gc_msb_i),
    .current_dq_gc_valid_i(current_dq_gc_valid_i),
    .ddr_fifos_status_i(ddr_fifos_status_i),
    .status_200_valid_i(status_200_valid_i),
    .fifos_status_i(fifos_status_i),
    .status_250_valid_i(status_250_valid_i),
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
endmodule
