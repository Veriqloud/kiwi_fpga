`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau
// 
// Create Date: 11.10.2023 12:39:27
// Design Name: Qline_turnkey
// Module Name: jesd204b_tx_wrapper
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2 
// Description: Wrapper of jesd204b protocol, link layer
// 
// Dependencies: 
//- jesd204b_tx.v
//- jesd204b_reg_mngt.v
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module jesd204b_tx_wrapper #(


		// Parameters of Axi Slave Bus Interface s_axil
		parameter integer C_s_axil_DATA_WIDTH	= 32,
		parameter integer C_s_axil_ADDR_WIDTH	= 12,
		parameter integer C_L	                = 4
	)
    (
        input wire                                    tx_core_clk,
        input wire                                    tx_core_reset,
        input wire                                    btx_sync_i,
        input wire                                    btx_sysref_i,
        // Ports of Axi Slave Bus Interface s_axil
		input wire                                    s_axil_aclk,
		input wire                                    s_axil_aresetn,
		input wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_awaddr,
		input wire [2 : 0]                            s_axil_awprot,
		input wire                                    s_axil_awvalid,
		output wire                                   s_axil_awready,
		input wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_wdata,
		input wire [(C_s_axil_DATA_WIDTH/8)-1 : 0]    s_axil_wstrb,
		input wire                                    s_axil_wvalid,
		output wire                                   s_axil_wready,
		output wire [1 : 0]                           s_axil_bresp,
		output wire                                   s_axil_bvalid,
		input wire                                    s_axil_bready,
		input wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_araddr,
		input wire [2 : 0]                            s_axil_arprot,
		input wire                                    s_axil_arvalid,
		output wire                                   s_axil_arready,
		output wire [C_s_axil_DATA_WIDTH-1 : 0]       s_axil_rdata,
		output wire [1 : 0]                           s_axil_rresp,
		output wire                                   s_axil_rvalid,
		input wire                                    s_axil_rready,
		input wire [C_L*32-1:0]                       vtx_tdata_i,
        output wire                                   btx_tready_o,
		// data bus output
        output wire [32-1:0]                          vgt0_tdata_o,
        output wire [4-1:0]                           vgt0_charisk_o,
        output wire [32-1:0]                          vgt1_tdata_o,
        output wire [4-1:0]                           vgt1_charisk_o,
        output wire [32-1:0]                          vgt2_tdata_o,
        output wire [4-1:0]                           vgt2_charisk_o,
        output wire [32-1:0]                          vgt3_tdata_o,
        output wire [4-1:0]                           vgt3_charisk_o,
        
        output wire                                   btx_reset_gt_o,
        input wire                                    btx_reset_done_i,
        
        //debug
        output wire blmfc_r
    );
 
wire [31:0]         vCTRL_ENABLE_int;
wire [31:0]         vCTRL_SUB_CLASS_int;
wire [31:0]         vCTRL_8B10B_CFG_int;
wire [31:0]         vCTRL_SYSREF_int;
wire [31:0]         vCTRL_TX_ILA_CFG0_int;
wire [31:0]         vCTRL_TX_ILA_CFG1_int;
wire [31:0]         vCTRL_TX_ILA_CFG2_int;
wire [31:0]         vCTRL_TX_ILA_CFG3_int;
wire [31:0]         vCTRL_TX_ILA_LID_int;
wire [C_L*32-1:0]   vgt_tdata_int;
wire [C_L*4-1:0]    vgt_charisk_int;
reg [11:0]          vtx_reset_done_r = 0;
reg [2:0]           vtx_enable_r = 0;
jesd204b_tx
    #(
        .p_L(C_L)       // number of physical lanes
    ) jesd204b_tx_inst
    (
        .tx_core_clk(tx_core_clk),
        .tx_core_reset(tx_core_reset),
        .btx_sync_i(btx_sync_i),
        .btx_sysref_i(btx_sysref_i),
        // Control parameters
        .btx_enable_i(vtx_enable_r[2]),
        .btx_reset_done_i(vtx_reset_done_r[11]),
        .bsysref_always_i(vCTRL_SYSREF_int[0]),
        .bsysref_required_i(vCTRL_SYSREF_int[1]),
        // Configurations parameters
        .vDID_i(vCTRL_TX_ILA_CFG0_int[7:0]),
        .vBID_i(vCTRL_TX_ILA_CFG0_int[11:8]),
        .vADJCNT_i(vCTRL_TX_ILA_CFG3_int[3:0]),
        .vLID_i(vCTRL_TX_ILA_LID_int[4:0]),
        .bPHADJ_i(vCTRL_TX_ILA_CFG3_int[8]),
        .bADJDIR_i(vCTRL_TX_ILA_CFG3_int[16]),
        .bSCR_i(vCTRL_8B10B_CFG_int[16]),
        .vF_i(vCTRL_8B10B_CFG_int[7:0]),
        .vK_i(vCTRL_8B10B_CFG_int[12:8]),
        .vM_i(vCTRL_TX_ILA_CFG1_int[7:0]),
        .vN_i(vCTRL_TX_ILA_CFG1_int[12:8]),
        .vCS_i(vCTRL_TX_ILA_CFG1_int[25:24]),
        .vNp_i(vCTRL_TX_ILA_CFG1_int[20:16]),
        .vSUBCLASSV_i(vCTRL_SUB_CLASS_int[1:0]),
        .vS_i(vCTRL_TX_ILA_CFG2_int[12:8]),
        .vJESDV_i(1),
        .vCF_i(vCTRL_TX_ILA_CFG2_int[28:24]),
        .bHD_i(vCTRL_TX_ILA_CFG2_int[16]),
//        input wire [7:0]            vFCHK_i,
        // Axi-s data bus input
        .vtx_tdata_i(vtx_tdata_i),
        .btx_tready_o(btx_tready_o),
        
        // data bus output
        .vgt_tdata_o(vgt_tdata_int),
        .vgt_charisk_o(vgt_charisk_int),
        //debug
        .blmfc_r(blmfc_r)
    );
    
    jesd204b_reg_mngt # ( 
		.C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
	) jesd204b_reg_mngt (
        .vCTRL_ENABLE_o(vCTRL_ENABLE_int),
        .vCTRL_SUB_CLASS_o(vCTRL_SUB_CLASS_int),
        .vCTRL_8B10B_CFG_o(vCTRL_8B10B_CFG_int),
        .vCTRL_SYSREF_o(vCTRL_SYSREF_int),
		.vCTRL_TX_ILA_CFG0_o(vCTRL_TX_ILA_CFG0_int),
		.vCTRL_TX_ILA_CFG1_o(vCTRL_TX_ILA_CFG1_int),
		.vCTRL_TX_ILA_CFG2_o(vCTRL_TX_ILA_CFG2_int),
		.vCTRL_TX_ILA_CFG3_o(vCTRL_TX_ILA_CFG3_int),
		.vCTRL_TX_ILA_LID_o(vCTRL_TX_ILA_LID_int),
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
	
	// Outputs assignment
	if (C_L == 4) begin
	   assign vgt0_tdata_o     = vgt_tdata_int[31:0];
	   assign vgt0_charisk_o   = vgt_charisk_int[3:0];
	   assign vgt1_tdata_o     = vgt_tdata_int[63:32];
	   assign vgt1_charisk_o   = vgt_charisk_int[7:4];
	   assign vgt2_tdata_o     = vgt_tdata_int[95:64];
	   assign vgt2_charisk_o   = vgt_charisk_int[11:8];
	   assign vgt3_tdata_o     = vgt_tdata_int[127:96];
	   assign vgt3_charisk_o   = vgt_charisk_int[15:12];
    end else if (C_L == 1) begin
       assign vgt0_tdata_o     = vgt_tdata_int[31:0];
	   assign vgt0_charisk_o   = vgt_charisk_int[3:0];
       assign vgt1_tdata_o     = 32'h00000000;
       assign vgt1_charisk_o   = 4'h0;
       assign vgt2_tdata_o     = 32'h00000000;
       assign vgt2_charisk_o   = 4'h0;
       assign vgt3_tdata_o     = 32'h00000000;
       assign vgt3_charisk_o   = 4'h0;      
    end 
    
    // Reset of GT transceiver
    (* ASYNC_REG = "TRUE" *) reg [11:0] vtx_reset_gt_r = 0;
    assign btx_reset_gt_o = vtx_reset_gt_r[11];
    always @(posedge s_axil_aclk, posedge tx_core_reset)
    begin
        if (tx_core_reset)
            vtx_reset_gt_r  <= 12'hFFF;
        else
            vtx_reset_gt_r <= {vtx_reset_gt_r[10:0],1'b0};
    end
    
    // Delay tx_reset_done && Synchronise tx_enable
    always @(posedge tx_core_clk)
    begin
        vtx_reset_done_r    <= {vtx_reset_done_r[10:0],btx_reset_done_i};
        vtx_enable_r        <= {vtx_enable_r[1:0],vCTRL_ENABLE_int[1]};
    end
endmodule
