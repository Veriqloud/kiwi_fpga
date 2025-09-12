`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh, Fabrice Faveneau
// 
// Create Date: 06/23/2023 02:21:48 PM
// Design Name: Qline_turnkey
// Module Name: clk_rst_mngt
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2 
// Description: 
//- Instantiate buffers for differential signals, clocks. 
//- Generate resets in each clock domain
//- Generate SYNC signal for clockchip LTC6951
// 
// Dependencies: 
//- fpga_turnkey_reg_mngt.v
//- reset_register.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_rst_mngt #(
    parameter integer C_s_axil_DATA_WIDTH	= 32,
    parameter integer C_s_axil_ADDR_WIDTH	= 10)
(
    // Ports of Axi Slave Bus Interface s_axil
    input     wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_awaddr,
    input     wire [2 : 0]                            s_axil_awprot,
    input     wire                                    s_axil_awvalid,
    output    wire                                    s_axil_awready,
    input     wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_wdata,
    input     wire [(C_s_axil_DATA_WIDTH/8)-1 : 0]    s_axil_wstrb,
    input     wire                                    s_axil_wvalid,
    output    wire                                    s_axil_wready,
    output    wire [1 : 0]                            s_axil_bresp,
    output    wire                                    s_axil_bvalid,
    input     wire                                    s_axil_bready,
    input     wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_araddr,
    input     wire [2 : 0]                            s_axil_arprot,
    input     wire                                    s_axil_arvalid,
    output    wire                                    s_axil_arready,
    output    wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_rdata,
    output    wire [1 : 0]                            s_axil_rresp,
    output    wire                                    s_axil_rvalid,
    input     wire                                    s_axil_rready,
    //s_axil_aclk : 15MHz. Generate from MMCM of DDR4 MIG, reference clock : onboard-FPGA 100MHz 
    input                                             s_axil_aclk,
      
    //- sys_reset_n : sytem reset from pcie
    //- clk_ddr_axi_i : 300MHz, Genrate from MMCM of DDR4 MIG
    //- rst_ddr_axi_i : reset in domain clk_ddr_axi_i
    input         sys_reset_n,
    input         clk_ddr_axi_i,
    input         rst_ddr_axi_i,
      
    //- pps_i : PPS from WRS
    //- fastdac_gt_powergood_i :  status signal from JESDPHY
    //- lclk_i : clock 200MHz from TDC chip 
    input         pps_i,      
    input         fastdac_gt_powergood_i,
    input         lclk_i,

    //input differential clock pairs 
    // - refclk : 200MHz from LTC6951
    // - sysref : 3.125MHz from LTC6951
    // - syncout : signal to start ILAS for JESD204B, from fastdac
    // - clk10 : 10MHz from WRS
    // - clk100 : 100MHz from LTC6951
    input         fastdac_refclki_p,
    input         fastdac_refclki_n,
    input         fastdac_sysref_p,
    input         fastdac_sysref_n,
    input         fastdac_syncout_p,
    input         fastdac_syncout_n,
    input 		ext_clk10_p,
    input         ext_clk10_n,
    input         ext_clk100_p,
    input         ext_clk100_n,
     
    // - rstn_axil_o : reset LOW for AXIL interface with XDMA
    // - rstn_ddr_axi_o : reset LOW for AXI interface of DDR4 MIG
    output        rstn_axil_o,
    output        rstn_ddr_axi_o,
    
    //output single-ended clock from differential pairs       
    output        fastdac_refclk_o,
    output        fastdac_coreclk_o,
    output        fastdac_corerst_o,
    output        fastdac_sysref_o,
    output        fastdac_syncout_o,
    output		clk10_o,
    output		clk100_o,
    //output SYNC signal for clockchip LTC6951
    output reg	sync_ltc_o, 
    //output reset signals for other modules
    output        tdc_rst_o,
    output        lrst_o,
    output wire   ttl_rst,
    output wire   decoy_rst,
    output        gc_rst_o,
    output        ddr_data_rstn_o
);

fpga_turnkey_reg_mngt # ( 
    .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
) fpga_turnkey_reg_mngt_inst (
    .gc_rst_o(gc_rst),
    .clockchip_sync_o(clockchip_sync),
    .ttl_rst_o(ttl_rst),
    .decoy_rst_o(decoy_rst),
    .tdc_rst_o(tdc_rst),
    .lrst_o(lrst_i),
    .fpga_turnkey_fastdac_rst_o(fpga_turnkey_fastdac_rst),
    .ddr_data_rst_o(ddr_data_rst),
    .ltc_sync_rst_o(ltc_sync_rst),
    .S_AXI_ACLK(s_axil_aclk),
    .S_AXI_ARESETN(rstn_axil_o),
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
    .S_AXI_RREADY(s_axil_rready));

//Buffer for fastdac refclk, reference for QPLL of GT interface
wire fastdac_coreclk_int;
IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf_fastdac (
    .O(fastdac_refclk_o), 
    .ODIV2(fastdac_coreclk_int), 
    .I(fastdac_refclki_p), 
    .CEB(1'b0), 
    .IB(fastdac_refclki_n));
    
//Buffer for fastdac core clock, using for general logic
BUFG_GT #(.SIM_DEVICE("ULTRASCALE_PLUS")) BUFG_GT_inst (
    .O(fastdac_coreclk_o),
    .CE(fastdac_gt_powergood_i),
    .CEMASK(fastdac_gt_powergood_i),
    .CLR(!sys_reset_n),
    .CLRMASK(!sys_reset_n),
    .DIV(3'b0),
    .I(fastdac_coreclk_int));
    
//Input buffer for sysref
IBUFDS sysref_ibuf (
    .IB(fastdac_sysref_n),
    .O(fastdac_sysref_o),
    .I(fastdac_sysref_p));

//Input buffer for syncout
IBUFDS syncout_ibuf (
    .IB(fastdac_syncout_n),
    .O(fastdac_syncout_o),
    .I(fastdac_syncout_p));

//Generate reset for axil
wire clk_axil_o;
reset_register #(.RST_ACTIVE_LEVEL("LOW")) reset_reg_axil_inst (
    .clk_i(s_axil_aclk),
    .rstn_i(sys_reset_n),
    .clk_o(clk_axil_o),
    .rstn_o(rstn_axil_o));
    
//Genrate reset for DDR MIG AXI
wire rst_ddr_axi_o;
wire clk_ddr_axi_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_reg_ddr_axi_inst (
    .clk_i(clk_ddr_axi_i),
    .rst_i(rst_ddr_axi_i),
    .clk_o(clk_ddr_axi_o),
    .rstn_o(rstn_ddr_axi_o),
    .rst_o(rst_ddr_axi_o));

//Buffers for clock 10MHz and 100MHz
wire clk10_int;
wire clk100_int;
IBUFDS ibuf_clk10(.IB(ext_clk10_n),.O(clk10_int),.I(ext_clk10_p)); 
IBUFDS ibuf_clk100(.IB(ext_clk100_n),.O(clk100_int),.I(ext_clk100_p));
BUFGCE #(
   .CE_TYPE("ASYNC"),               // ASYNC, HARDSYNC, SYNC
   .IS_CE_INVERTED(1'b0),           // Programmable inversion on CE
   .IS_I_INVERTED(1'b0),            // Programmable inversion on I
   .SIM_DEVICE("ULTRASCALE_PLUS")   // ULTRASCALE, ULTRASCALE_PLUS
) BUFGCE_clk10 (
   .O(clk10_o),     // 1-bit output: Buffer
   .CE(1'b1),       // 1-bit input: Buffer enable
   .I(clk10_int)    // 1-bit input: Buffer
);

BUFGCE #(
   .CE_TYPE("ASYNC"),               // ASYNC, HARDSYNC, SYNC
   .IS_CE_INVERTED(1'b0),           // Programmable inversion on CE
   .IS_I_INVERTED(1'b0),            // Programmable inversion on I
   .SIM_DEVICE("ULTRASCALE_PLUS")   // ULTRASCALE, ULTRASCALE_PLUS
) BUFGCE_clk100 (
   .O(clk100_o),    // 1-bit output: Buffer
   .CE(1'b1),       // 1-bit input: Buffer enable
   .I(clk100_int)   // 1-bit input: Buffer
);
//---------------------------------------------------------------------
// Generate reset for ltc_sync counter
(* ASYNC_REG = "TRUE" *) reg [2:0] ltc_sync_rst_r;
initial begin
    ltc_sync_rst_r <= 0;
end
always @(posedge clk10_o) begin
    ltc_sync_rst_r <= {ltc_sync_rst_r[1:0],ltc_sync_rst};
end
wire ltc_rst_o;
wire ltc_rstn_o;
wire clk10_o_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_reg_clk10_inst (    
    .clk_i(clk10_o),
    .rst_i(ltc_sync_rst_r[1]),
    .clk_o(clk10_o_o),
    .rstn_o(ltc_rstn_o),
    .rst_o(ltc_rst_o));

//Generate resets for submodules
(* ASYNC_REG = "TRUE" *) reg [2:0] fpga_turnkey_fastdac_rst_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] tdc_rst_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] gc_rst_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] lrst_i_r;
(* ASYNC_REG = "TRUE" *) reg [2:0] ddr_data_rst_r;

initial begin
    fpga_turnkey_fastdac_rst_r <= 0;
    tdc_rst_r <= 0;
    gc_rst_r <= 0;
    lrst_i_r <= 0;
    ddr_data_rst_r <= 1;
end
always @(posedge fastdac_coreclk_o) begin
    fpga_turnkey_fastdac_rst_r <= {fpga_turnkey_fastdac_rst_r[1:0],fpga_turnkey_fastdac_rst};
    tdc_rst_r <= {tdc_rst_r[1:0],tdc_rst};
    gc_rst_r <= {gc_rst_r[1:0],gc_rst};
    lrst_i_r <= {lrst_i_r[1:0],lrst_i};
    ddr_data_rst_r <= {ddr_data_rst_r[1:0], ddr_data_rst};
end


wire fastdac_coreclk;
wire fastdac_corerstn_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) tx_core_reset_inst (
    .clk_i(fastdac_coreclk_o),
    .rst_i(fpga_turnkey_fastdac_rst_r[1]),
    .clk_o(fastdac_coreclk),
    .rstn_o(fastdac_corerstn_o),
    .rst_o(fastdac_corerst_o));

wire tdc_rstn_o;
wire tdc_rst_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) tdc_reset_inst (
    .clk_i(fastdac_coreclk_o),
    .rst_i(tdc_rst_r[1]),
    .clk_o(fastdac_coreclk),
    .rstn_o(tdc_rstn_o),
    .rst_o(tdc_rst_o));

wire lclk_o;
wire lrstn_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) lrstn_inst (
    .clk_i(lclk_i),
    .rst_i(lrst_i_r[1]),
    .clk_o(lclk_o),
    .rstn_o(lrstn_o),
    .rst_o(lrst_o));

wire gc_rstn_o;
wire gc_rst_o;
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) gc_reset_inst (
    .clk_i(fastdac_coreclk_o),
    .rst_i(gc_rst_r[1]),
    .clk_o(fastdac_coreclk),
    .rstn_o(gc_rstn_o),
    .rst_o(gc_rst_o));

wire ddr_data_rst_o;
wire ddr_data_rstn_o;
reset_register #(.RST_ACTIVE_LEVEL("LOW")) ddr_data_resetn_inst (
    .clk_i(fastdac_coreclk_o),
    .rstn_i(ddr_data_rst_r[1]),
    .clk_o(fastdac_coreclk),
    .rstn_o(ddr_data_rstn_o));

//Generate SYNC signal for clockchip LTC6951
reg sync_ltc_o;
(* ASYNC_REG = "TRUE" *) reg [2:0] clockchip_sync_r;
reg [15:0] counter_clk;
reg pps_clk_r;
reg pps_clk_trigger;
initial begin
    pps_clk_r <= 0;
    clockchip_sync_r <= 3'b0;
    counter_clk <= 0;
    pps_clk_trigger <= 0;
end

always @(posedge clk10_o) begin
   if (ltc_rst_o) begin
      clockchip_sync_r <= 0;
      sync_ltc_o <= 0;

      pps_clk_trigger <= 0;
      pps_clk_r = 0;

      counter_clk <= 0;
   end else begin
      clockchip_sync_r <= {clockchip_sync_r[1:0],clockchip_sync};
      pps_clk_r <= pps_i;
      //Detect rising edge of pps after receive the sync command from OS
      if ((!pps_clk_r && pps_i) && clockchip_sync_r[2]) begin
         pps_clk_trigger <= 1;
      end
      if (pps_clk_trigger) begin
         counter_clk <= counter_clk + 1;
         if ((counter_clk > 0) && (counter_clk <= 16'd20000)) begin //20000 = 2ms for sync pulse
            sync_ltc_o <= 1'b1;
         end else if (counter_clk > 16'd20000) begin
            counter_clk <= counter_clk;
            sync_ltc_o <= 1'b0;
         end else begin
            sync_ltc_o <= 1'b0;
         end
      end else begin
         sync_ltc_o <= 1'b0;
         counter_clk <= 0;
      end

   end
end

//ILA debug
ila_sync_ltc sync_ltc_ila_inst (
	.clk(fastdac_coreclk_o), // input wire clk
	.probe0(pps_i), // input wire [0:0]  probe0  
	.probe1(clk10_o), // input wire [0:0]  probe1 
	.probe2(sync_ltc_o), // input wire [0:0]  probe2 
	.probe3(clockchip_sync), // input wire [0:0]  probe3 
	.probe4(clockchip_sync_r), // input wire [2:0]  probe4 
	.probe5(counter_clk), // input wire [15:0]  probe5
	.probe6(pps_clk_trigger) // input wire [0:0]  probe6
);
endmodule