`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau, Hop Dinh
// 
// Create Date: 07/17/2024 03:00:07 PM
// Design Name: 
// Module Name: ddr_data_reg_mngt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Manage axil registers for ddr_data module 
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
        input pps_i,
        output wire mr_start_write_ddr_i,
        output wire mr_command_enable,
        output wire mr_command_alpha_enable,
        output wire mr_command_gc_enable,
        output wire [2:0] mr_command_i,
        output wire mr_command_gc_i,
        output wire mr_reg_enable_i,
        output wire [47:0] mr_dq_gc_start_i,
        output wire [31:0] mr_threshold_i,
        output wire [31:0] mr_threshold_full_i,
        output wire [31:0] mr_fiber_delay_i,
        output wire mr_pair_delay_i,
        output wire [15:0] mr_ab_fiber_delay_i,
        input wire [47:0] mr_current_dq_gc,
        input wire        mr_current_dq_gc_valid,
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
assign current_dq_gc_lsb_i = mr_current_dq_gc[31:0];
assign current_dq_gc_msb_i = mr_current_dq_gc[47:32];


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
    .start_write_ddr_o(mr_start_write_ddr_i),
    .command_enable_o(mr_command_enable),
    .command_alpha_enable_o(mr_command_alpha_enable),
    .command_gc_enable_o(mr_command_gc_enable),
    .command_o(mr_command_i),
    .command_gc_o(mr_command_gc_i),
    .reg_enable_o(mr_reg_enable_i),
    .dq_gc_start_lsb_o(dq_gc_start_lsb_o),
    .dq_gc_start_msb_o(dq_gc_start_msb_o),
    .threshold_o(mr_threshold_i),
    .threshold_full_o(mr_threshold_full_i),
    .fiber_delay_o(mr_fiber_delay_i),
    .pair_delay_o(mr_pair_delay_i),
    .ab_fiber_delay_o(mr_ab_fiber_delay_i),
    .current_dq_gc_lsb_i(current_dq_gc_lsb_i),
    .current_dq_gc_msb_i(current_dq_gc_msb_i),
    .current_dq_gc_valid_i(mr_current_dq_gc_valid),
    .ddr_fifos_status_i(ddr_fifos_status_i),
    .status_200_valid_i(status_200_valid_i),
    .fifos_status_i(fifos_status_i),
    .status_250_valid_i(status_250_valid_i),
    .pps_i(pps_i),
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
