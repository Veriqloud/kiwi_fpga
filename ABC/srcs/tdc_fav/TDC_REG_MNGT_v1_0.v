
`timescale 1 ns / 1 ps

	module TDC_REG_MNGT_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface s_axil
		parameter integer C_s_axil_DATA_WIDTH	= 32,
		parameter integer C_s_axil_ADDR_WIDTH	= 12
	)
	(
		// Users to add ports here
		//Clock
		// input clk200_i,
		// Control data output
		output wire mr_enable,
		output wire mr_command_enable,
		output wire [2:0] mr_command_i,
		output wire mr_command_count,
		// output wire command_get_gc_o,
		output wire mr_start_gc_i,
		// output wire [6:0] tdc_burst_size,
		// output wire [5:0] tdc_index_bitwise_o,
		// output wire [5:0] tdc_stop_bitwise_o,
		output wire [15:0] mr_index_stop_bitwise_i,
		output wire [31:0] stopa_sim_limit,
		output wire        stopa_sim_enable_o,

		output wire [31:0] mr_gate0_i,
		output wire [31:0] mr_gate1_i,
		output wire [15:0] mr_shift_tdc_time_i,
		output wire [15:0] mr_shift_gc_back_i,
		output wire        mr_reg_enable_tdc,
		output wire        mr_reg_enable200, 


		// input[1:0]        wr_fifo_full_i,
		// input[1:0]        rd_fifo_empty_i,
		// input[1:0]        fifo_idle_i,

		input[31:0]		  mr_total_count_o,
		input[31:0]		  mr_click0_count_o,
		input[31:0]	      mr_click1_count_o,
		input 			  mr_data_count_valid_o,

		input[31:0]		  mr_count_to,
		input[31:0]		  mr_count_c0,
		input[31:0]	      mr_count_c1,
		input 			  mr_command_count_valid_o,

		// User ports ends
		// User ports ends
		// Do not modify the ports beyond this line
		
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
// wire [31:0] total_count_sync_i;
// wire [31:0] click0_count_sync_i;
// wire [31:0] click1_count_sync_i;

// // xpm_cdc_array_single: Single-bit Array Synchronizer
// // Xilinx Parameterized Macro, version 2024.1
// xpm_cdc_array_single #(
//    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
//    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
//    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//    .SRC_INPUT_REG(1),  // DECIMAL; 0=do not register input, 1=register input
//    .WIDTH(32)           // DECIMAL; range: 1-1024
// )
// xpm_cdc_array_single_total_inst (
//    .dest_out(total_count_sync_i), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
//                         // output is registered.

//    .dest_clk(s_axil_aclk), // 1-bit input: Clock signal for the destination clock domain.
//    .src_clk(clk200_i),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
//    .src_in(total_count_i)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
//                         // domain. It is assumed that each bit of the array is unrelated to the others. This
//                         // is reflected in the constraints applied to this macro. To transfer a binary value
//                         // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
// );

// xpm_cdc_array_single #(
//    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
//    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
//    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//    .SRC_INPUT_REG(1),  // DECIMAL; 0=do not register input, 1=register input
//    .WIDTH(32)           // DECIMAL; range: 1-1024
// )
// xpm_cdc_array_single_click0_inst (
//    .dest_out(click0_count_sync_i), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
//                         // output is registered.

//    .dest_clk(s_axil_aclk), // 1-bit input: Clock signal for the destination clock domain.
//    .src_clk(clk200_i),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
//    .src_in(click0_count_i)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
//                         // domain. It is assumed that each bit of the array is unrelated to the others. This
//                         // is reflected in the constraints applied to this macro. To transfer a binary value
//                         // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
// );

// xpm_cdc_array_single #(
//    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
//    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
//    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//    .SRC_INPUT_REG(1),  // DECIMAL; 0=do not register input, 1=register input
//    .WIDTH(32)           // DECIMAL; range: 1-1024
// )
// xpm_cdc_array_single_click1_inst (
//    .dest_out(click1_count_sync_i), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
//                         // output is registered.

//    .dest_clk(s_axil_aclk), // 1-bit input: Clock signal for the destination clock domain.
//    .src_clk(clk200_i),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
//    .src_in(click1_count_i)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
//                         // domain. It is assumed that each bit of the array is unrelated to the others. This
//                         // is reflected in the constraints applied to this macro. To transfer a binary value
//                         // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
// );


// Instantiation of Axi Bus Interface s_axil
	TDC_REG_MNGT_v1_0_s_axil # ( 
		.C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
	) TDC_REG_MNGT_v1_0_s_axil_inst (
	    .tdc_enable(mr_enable),
	    .tdc_command_enable_o(mr_command_enable),
	    .tdc_command_o(mr_command_i),
		.tdc_command_count_o(mr_command_count),
	    .start_gc_o(mr_start_gc_i),
	    // .tdc_burst_size(tdc_burst_size),
	    // .tdc_index_bitwise_o(tdc_index_bitwise_o),
	    // .tdc_stop_bitwise_o(tdc_stop_bitwise_o),
	    .tdc_index_stop_bitwise_o(mr_index_stop_bitwise_i),
	    .stopa_sim_limit(stopa_sim_limit),
	    .stopa_sim_enable_o(stopa_sim_enable_o),
	    .gate0_o(mr_gate0_i),
	    .gate1_o(mr_gate1_i),
	    .shift_tdc_time_o(mr_shift_tdc_time_i),
	    .shift_gc_back_o(mr_shift_gc_back_i),
	    .tdc_reg_enable_o(mr_reg_enable_tdc),
	    .tdc_reg_enable200_o(mr_reg_enable200),
	    // .wr_fifo_full_i(wr_fifo_full_i),
	    // .rd_fifo_empty_i(rd_fifo_empty_i),
	    // .fifo_idle_i(fifo_idle_i),
	    // .total_count_i(total_count_sync_i),
	    // .click0_count_i(click0_count_sync_i),
	    // .click1_count_i(click1_count_sync_i),
	    .total_count_i(mr_total_count_o),
	    .click0_count_i(mr_click0_count_o),
	    .click1_count_i(mr_click1_count_o),
	    .data_count_valid_i(mr_data_count_valid_o),
		.count_to_i(mr_count_to),
		.count_c0_i(mr_count_c0),
		.count_c1_i(mr_count_c1),
		.command_count_valid_i(mr_command_count_valid_o),
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

	// Add user logic here

	// User logic ends

	endmodule
