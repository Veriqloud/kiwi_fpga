`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh, Fabrice Faveneau
// 
// Create Date: 06/23/2023 02:21:48 PM
// Design Name: 
// Module Name: clk_rst_mngt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Buffers for differential signals, clocks. Generate resets and sync clockchip
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_rst_mngt
    #(
      parameter TDC_REFCLK_DIVISOR = 20, //Number of 200MHz clk every tdc_refclk
      parameter N_TDC_REFCLK = 8, //Number of tdc clk every RSTIDX
      parameter integer C_s_axil_DATA_WIDTH	= 32,
      parameter integer C_s_axil_ADDR_WIDTH	= 10)
    (
      // Ports of Axi Slave Bus Interface s_axil
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

      input       sys_reset_n,
      input       clk_ddr_axi_i,
      input       rst_ddr_axi_i,
      output      clk_axil_o,
      output      rstn_axil_o,
      output      clk_ddr_axi_o,
      output      rstn_ddr_axi_o,
      output      rst_ddr_axi_o,
      input       fastdac_refclkp_i,
      input       fastdac_refclkn_i,
      input       fastdac_gt_powergood_i,
      input       fastdac_sysrefp_i,
      input       fastdac_sysrefn_i,
      input       fastdac_syncoutp_i,
      input       fastdac_syncoutn_i,

      input       pps_i,
      output      fastdac_refclk_o,
      output      fastdac_coreclk_o,
      output      fastdac_corerst_o,
      output      fastdac_sysref_o,
      output      fastdac_syncout_o,

      input 		ext_clk10_p,
      input		ext_clk10_n,
      input		ext_clk100_p,
      input		ext_clk100_n,
      input       lclk_i,
      output		clk10_o,
      output		clk100_o,
      output reg	sync_ltc_o, 
      output      tdc_rst_o,
      output      lrst_o,

      output wire ttl_rst,
      output      gc_rst_o,
      output      gc_rstn_o,
      output      ddr_data_rst_o,
      output      ddr_data_rstn_o

    );

fpga_turnkey_reg_mngt # ( 
		.C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
	) fpga_turnkey_reg_mngt_inst (
      .gc_rst_o(gc_rst),
      .clockchip_sync_o(clockchip_sync),
      .ttl_rst_o(ttl_rst),
      .tdc_rst_o(tdc_rst),
      .lrst_o(lrst_i),
      .fpga_turnkey_fastdac_rst_o(fpga_turnkey_fastdac_rst),
      .ddr_data_rst_o(ddr_data_rst),
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
      .S_AXI_RREADY(s_axil_rready)
	);

wire fastdac_coreclk_int;
// FAST DAC Ref clock buffer
IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf_fastdac (.O(fastdac_refclk_o), .ODIV2(fastdac_coreclk_int), .I(fastdac_refclkp_i), .CEB(1'b0), .IB(fastdac_refclkn_i));
//BUFG_GT     #(.SIM_DEVICE("ULTRASCALE_PLUS")) BUFG_GT_inst (.O(fastdac_coreclk_o),.CE(fpga_turnkey_fastdac_pgood),.CEMASK(fpga_turnkey_fastdac_pgood),.CLR(!sys_reset_n),.CLRMASK(!sys_reset_n),.DIV(3'b0),.I(fastdac_coreclk_int));
BUFG_GT     #(.SIM_DEVICE("ULTRASCALE_PLUS")) BUFG_GT_inst (.O(fastdac_coreclk_o),.CE(fastdac_gt_powergood_i),.CEMASK(fastdac_gt_powergood_i),.CLR(!sys_reset_n),.CLRMASK(!sys_reset_n),.DIV(3'b0),.I(fastdac_coreclk_int));
IBUFDS sysref_ibuf    (.IB(fastdac_sysrefn_i),.O(fastdac_sysref_o),.I(fastdac_sysrefp_i));
//reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_reg_fastdac_corerst_inst (.clk_i(fastdac_coreclk_o),.rstn_i(sys_reset_n),.rst_o(fastdac_corerst_o));
IBUFDS syncout_ibuf    (.IB(fastdac_syncoutn_i),.O(fastdac_syncout_o),.I(fastdac_syncoutp_i));


reset_register #(.RST_ACTIVE_LEVEL("LOW")) reset_reg_axil_inst (.clk_i(s_axil_aclk),.rstn_i(sys_reset_n),.clk_o(clk_axil_o),.rstn_o(rstn_axil_o));
reset_register #(.RST_ACTIVE_LEVEL("HIGH")) reset_reg_ddr_axi_inst (.clk_i(clk_ddr_axi_i),.rst_i(rst_ddr_axi_i),.clk_o(clk_ddr_axi_o),.rstn_o(rstn_ddr_axi_o),.rst_o(rst_ddr_axi_o));
wire rstn_syncc_o;
reset_register #(.RST_ACTIVE_LEVEL("LOW")) reset_reg_clk10_inst (.clk_i(clk10_o),.rstn_i(sys_reset_n),.clk_o(clk10_o_o),.rstn_o(rstn_syncc_o));



wire clk10_int;
wire clk100_int;
IBUFDS ibuf_clk10(.IB(ext_clk10_n),.O(clk10_int),.I(ext_clk10_p)); // swap _p and _n, board design error
IBUFDS ibuf_clk100(.IB(ext_clk100_n),.O(clk100_int),.I(ext_clk100_p));
BUFGCE #(
   .CE_TYPE("ASYNC"),               // ASYNC, HARDSYNC, SYNC
   .IS_CE_INVERTED(1'b0),          // Programmable inversion on CE
   .IS_I_INVERTED(1'b0),           // Programmable inversion on I
   .SIM_DEVICE("ULTRASCALE_PLUS")  // ULTRASCALE, ULTRASCALE_PLUS
)
BUFGCE_clk10 (
   .O(clk10_o),   // 1-bit output: Buffer
   .CE(1'b1), // 1-bit input: Buffer enable
   .I(clk10_int)    // 1-bit input: Buffer
);

BUFGCE #(
   .CE_TYPE("ASYNC"),               // ASYNC, HARDSYNC, SYNC
   .IS_CE_INVERTED(1'b0),          // Programmable inversion on CE
   .IS_I_INVERTED(1'b0),           // Programmable inversion on I
   .SIM_DEVICE("ULTRASCALE_PLUS")  // ULTRASCALE, ULTRASCALE_PLUS
)
BUFGCE_clk100 (
   .O(clk100_o),   // 1-bit output: Buffer
   .CE(1'b1), // 1-bit input: Buffer enable
   .I(clk100_int)    // 1-bit input: Buffer
);
//---------------------------------------------------------------------


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


//Testing Reset signals 
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

// localparam c_PERIOD_CLK = 5;
// localparam c_DELAY_SYNC  = 2000000;
// localparam c_NR_CYCLES_SYNC = c_DELAY_SYNC / c_PERIOD_CLK;
// localparam c_NR_CYCLES_JESD_RST = c_NR_CYCLES_SYNC;
// reg [31:0]    cnt_sync_r;
// reg [2:0]     fpga_turnkey_fastdac_rst_r;

// reg [31:0]    cnt_tdc_rst;
// reg [2:0]     tdc_rst_r;

// reg [31:0]    cnt_ttl_rst;
// reg [2:0]     ttl_rst_r;

// reg [31:0]    cnt_gc_rst;
// reg [2:0]     gc_rst_r;
// // Declare state register
// reg [2:0]   state;

// // Declare states
// localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5;

// initial
// begin
//     gc_rst_o <= 1;
//     gc_rst_r <= 0;
//     cnt_gc_rst <= 0;

//     ttl_rst_o <= 1;
//     ttl_rst_r <= 0;
//     cnt_ttl_rst <= 0;

//     tdc_rst_o <= 1;
//     tdc_rst_r <= 0; //register receive rst from axil
//     cnt_tdc_rst <= 0;
	
//     fastdac_corerst_o	                   <= 1;
// 	fpga_turnkey_fastdac_rst_r             <= 0;
// 	cnt_sync_r			                   = 0;
// 	state                                  <= S0;
// end

// // State machine
// // Output depends only on the state
// always @ (state) begin
//     // Output depends only on the state
//     fastdac_corerst_o                   <= 0;
//     tdc_rst_o <= 0;
//     ttl_rst_o <= 0;
//     gc_rst_o <= 0;
//     case (state)
//         S2:
//             fastdac_corerst_o           <= 1;
//         S3:
//             tdc_rst_o <= 1;
//         S4:
//             ttl_rst_o <= 1; 
//         S5:
//             gc_rst_o <= 1;

//         default:;              				
//     endcase
// end

// always @(posedge fastdac_coreclk_o)
// begin

// 	fpga_turnkey_fastdac_rst_r     <= {fpga_turnkey_fastdac_rst_r[1:0],fpga_turnkey_fastdac_rst};
//     tdc_rst_r <= {tdc_rst_r[1:0],tdc_rst};
//     ttl_rst_r <= {ttl_rst_r[1:0],ttl_rst};
//     gc_rst_r <= {gc_rst_r[1:0],gc_rst};   
	
	   
// 	// Determine the next state
//     case (state)			
//         S0:
//             // IDLE state
//             state <= S1;
//         S1:
//             // Waiting for JESD IP reset request
//             // Waiting for LTC 6951 sync request
//             begin
//                 cnt_sync_r  = 0;
//                 cnt_tdc_rst = 0;
//                 cnt_ttl_rst = 0;
//                 if (fpga_turnkey_fastdac_rst_r[2] == 0 && fpga_turnkey_fastdac_rst_r[1] == 1) 
//                     state <= S2;
//                 if (tdc_rst_r[2] == 0 && tdc_rst_r[1] == 1)
//                     state <= S3;
//                 if (ttl_rst_r[2] == 0 && ttl_rst_r[1] == 1)
//                     state <= S4;
//                 if (gc_rst_r[2] == 0 && gc_rst_r[1] == 1)
//                     state <= S5;
//             end
//         S2: 
//             // Length of JESD reset
//             begin
//                 cnt_sync_r		 = cnt_sync_r + 1; 
//                 if (cnt_sync_r == c_NR_CYCLES_JESD_RST)
//                     state           <= S0;
// 	       end 
//         S3:
//             begin
//                 cnt_tdc_rst = cnt_tdc_rst + 1;
//                 if (cnt_tdc_rst == c_NR_CYCLES_JESD_RST)
//                     state <= S0;
//             end           
//     	S4:
//             begin
//                 cnt_ttl_rst = cnt_ttl_rst + 1;
//                 if (cnt_ttl_rst == c_NR_CYCLES_JESD_RST)
//                     state <= S0;
//             end
//         S5:
//             begin
//                 cnt_gc_rst = cnt_gc_rst + 1;
//                 if (cnt_gc_rst == c_NR_CYCLES_JESD_RST)
//                     state <= S0;        
//             end	
//     endcase
// end



// Old version
// reg [31:0] counter;
// wire trigger_pps; //trigger align to pps
// reg [1:0] shift_sync_ltc;


// always @(posedge pps_i) begin
//     shift_sync_ltc <= {shift_sync_ltc[0],clockchip_sync}; //sync clockchip aligned to pps
// end


// assign trigger_pps = shift_sync_ltc[0];

//  always @(posedge clk10_o) begin
//      if (!sys_reset_n) begin
//          counter <= 0;
//          sync_ltc_o <= 1'b0;
//      end else begin
//          if (trigger_pps) begin
//              counter <= counter + 1;
//              if (counter <= 20000) begin //1ms 
//                  sync_ltc_o <= 1'b1;
//              end else begin
//                  sync_ltc_o <= 1'b0;
//              end
//          end else begin
//             counter <= 0;
//          end
//      end
//  end


reg sync_ltc_o;
(* ASYNC_REG = "TRUE" *) reg [2:0] clockchip_sync_r;
reg [15:0] counter_clk;

reg pps_clk_r;
reg pps_clk_trigger;
initial begin
    pps_clk_r <= 0;
    clockchip_sync_r <= 3'b0;
end

always @(posedge clk10_o) begin
   if (!rstn_syncc_o) begin
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


endmodule