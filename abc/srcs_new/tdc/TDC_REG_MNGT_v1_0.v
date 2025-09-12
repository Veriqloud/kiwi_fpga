
module TDC_REG_MNGT_v1_0 #(
    // Parameters of Axi Slave Bus Interface s_axil
    parameter integer C_s_axil_DATA_WIDTH	= 32,
    parameter integer C_s_axil_ADDR_WIDTH	= 12
)(
    // Control data output
    output wire         mr_enable,
    output wire         mr_command_enable,
    output wire [2:0]   mr_command_i,
    output wire         mr_command_count,
    output wire         mr_start_gc_i,
    output wire [15:0]  mr_index_stop_bitwise_i,
    output wire [31:0]  stopa_sim_limit,
    output wire         stopa_sim_enable_o,

    output wire [31:0]  mr_gate0_i,
    output wire [31:0]  mr_gate1_i,
    output wire [15:0]  mr_shift_tdc_time_i,
    output wire [15:0]  mr_shift_gc_back_i,
    output wire         mr_reg_enable_tdc,
    output wire         mr_reg_enable200, 

    input[31:0]		   mr_total_count_o,
    input[31:0]		   mr_click0_count_o,
    input[31:0]	       mr_click1_count_o,
    input 			   mr_data_count_valid_o,

    input[31:0]		   mr_count_to,
    input[31:0]		   mr_count_c0,
    input[31:0]	       mr_count_c1,
    input 			   mr_command_count_valid_o,

    // User ports ends
    // Do not modify the ports beyond this line    
    // Ports of Axi Slave Bus Interface s_axil
    input   wire                                s_axil_aclk,
    input   wire                                s_axil_aresetn,
    input   wire [C_s_axil_ADDR_WIDTH-1 : 0]    s_axil_awaddr,
    input   wire [2 : 0]                        s_axil_awprot,
    input   wire                                s_axil_awvalid,
    output  wire                                s_axil_awready,
    input   wire [C_s_axil_DATA_WIDTH-1 : 0]    s_axil_wdata,
    input   wire [(C_s_axil_DATA_WIDTH/8)-1 : 0] s_axil_wstrb,
    input   wire                                s_axil_wvalid,
    output  wire                                s_axil_wready,
    output  wire [1 : 0]                        s_axil_bresp,
    output  wire                                s_axil_bvalid,
    input   wire                                s_axil_bready,
    input   wire [C_s_axil_ADDR_WIDTH-1 : 0]    s_axil_araddr,
    input   wire [2 : 0]                        s_axil_arprot,
    input   wire                                s_axil_arvalid,
    output  wire                                s_axil_arready,
    output  wire [C_s_axil_DATA_WIDTH-1 : 0]    s_axil_rdata,
    output  wire [1 : 0]                        s_axil_rresp,
    output  wire                                s_axil_rvalid,
    input   wire                                s_axil_rready
);

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
    .tdc_index_stop_bitwise_o(mr_index_stop_bitwise_i),
    .stopa_sim_limit(stopa_sim_limit),
    .stopa_sim_enable_o(stopa_sim_enable_o),
    .gate0_o(mr_gate0_i),
    .gate1_o(mr_gate1_i),
    .shift_tdc_time_o(mr_shift_tdc_time_i),
    .shift_gc_back_o(mr_shift_gc_back_i),
    .tdc_reg_enable_o(mr_reg_enable_tdc),
    .tdc_reg_enable200_o(mr_reg_enable200),
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
endmodule
