`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/21/2024 02:17:01 PM
// Design Name: 
// Module Name: jesd_transport_tb
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


module jesd_transport_tb();

reg         SAXI_aclk;
reg         SAXI_aresetn = 0;

reg [31:0]  SAXI_awaddr = 0;    //Write channel address
reg         SAXI_awvalid = 0;   //
wire        SAXI_awready;       //

reg [31:0]  SAXI_wdata = 0;     //Write channel date
reg         SAXI_wvalid = 0;    //
wire        SAXI_wready;        //

wire        SAXI_bresp;         //Write channel response
wire        SAXI_bvalid;        //
reg         SAXI_bready = 0;    //

reg [31:0]  SAXI_araddr   = 0;    // Read Channel  : Address
reg         SAXI_arvalid  = 0;    //
wire        SAXI_arready;         //

wire [31:0] SAXI_rdata;           // Read Channel : Data
wire        SAXI_rvalid;          //
reg         SAXI_rready   = 0;    //
wire [ 1:0] SAXI_rresp;           // Read Channel  : Response

//Porst AXISTREAM
reg         SAXIS_tclk;
reg         SAXIS_tresetn;
reg [127:0] SAXIS_tdata;
reg         SAXIS_tvalid;
wire        SAXIS_tready;

//Others ports
reg         tx_core_clk;
reg         tx_core_reset;
reg         tx_tready;
wire[127:0] tx_tdata;
reg         pps_i;

jesd_transport jesd_transport_inst(
    .s_axil_aclk(SAXI_aclk),
    .s_axil_aresetn(SAXI_aresetn),
    .s_axil_awaddr(SAXI_awaddr),
    .s_axil_awprot(3'b0),
    .s_axil_awvalid(SAXI_awvalid),
    .s_axil_awready(SAXI_awready),
    .s_axil_wdata(SAXI_wdata),
    .s_axil_wstrb(4'hF),
    .s_axil_wvalid(SAXI_wvalid),
    .s_axil_wready(SAXI_wready),
    .s_axil_bresp(SAXI_bresp),
    .s_axil_bvalid(SAXI_bvalid),
    .s_axil_bready(SAXI_bready),
    .s_axil_araddr(SAXI_araddr),
    .s_axil_arprot(3'b0),
    .s_axil_arvalid(SAXI_arvalid),
    .s_axil_arready(SAXI_arready),
    .s_axil_rdata(SAXI_rdata),
    .s_axil_rresp(SAXI_rresp),
    .s_axil_rvalid(SAXI_rvalid),
    .s_axil_rready(SAXI_rready),
    //For axistream
    .s_axis_clk(SAXIS_tclk),
    .s_axis_tresetn(SAXIS_tresetn),
    .s_axis_tdata(SAXIS_tdata),
    .s_axis_tvalid(SAXIS_tvalid),
    .s_axis_tready(SAXIS_tready),
    // dout4_test,
    // rd_en_16,
    // rd_en_4,
    // dpram_rng_dout,
    // rd_en_4_shift,
    // counter40,
    // counter10,
    // sam0,
    // addr_state_dac0,
    // seq_state_dac1,
    // state_rng,
    // full,
    // almost_full,
    // empty,
    // almost_empty,
    // wr_ack,
    // valid,
    // rd_data_count,
    // wr_data_count,
    // clk_pps,
    // fastdac_sync_i,
    // fastdac_ddr_status_i,
    .tx_core_clk(tx_core_clk),
    .tx_core_reset(tx_core_reset),
    .tx_tdata(tx_tdata),
    .tx_tready(tx_tready),
    .pps_i(pps_i)
    );

//AXIL clock
localparam PERIOD_AXI = 50;
always begin
    SAXI_aclk = 1'b1;
    #(PERIOD_AXI/2) SAXI_aclk = 1'b0;
    #(PERIOD_AXI/2);
end
//AXIS clock
localparam PERIOD_AXIS = 4;
always begin
    SAXIS_tclk = 1'b1;
    #(PERIOD_AXIS/2) SAXIS_tclk = 1'b0;
    #(PERIOD_AXIS/2);
end
//Atx_core_clk
localparam PERIOD_tx_core = 5;
always begin
    tx_core_clk = 1'b1;
    #(PERIOD_tx_core/2) tx_core_clk = 1'b0;
    #(PERIOD_tx_core/2);
end
//PPS clock
localparam PERIOD_pps = 1000000;
initial begin
  pps_i = 1'b0;
  #15 pps_i = 1'b0;
  forever begin
      pps_i = 1'b1;
      #(PERIOD_pps/10) pps_i = 1'b0;
      #(PERIOD_pps - PERIOD_pps/10);
  end
end
// always begin
//     pps_i = 1'b1;
//     #(PERIOD_pps/10) pps_i = 1'b0;
//     #(PERIOD_pps - PERIOD_pps/10);
// end

initial begin
    $display("Start simulation");
    $display("Reset sysem");
    SAXI_aresetn <= 0;
    tx_core_reset <= 1;
    #2000000
    SAXI_aresetn <= 1;
    tx_core_reset <= 0;
    // #4000000
    //Wite to axil
end

initial begin
    tx_tready = 0;
    #4000000
    tx_tready = 1;
end

//Axil_write task
  task axi_write;
    input [31:0] offset;
    input [31:0] data;
    reg   [31:0] addr;
    reg    [1:0] resp;
    begin
      // Use address as in datasheet
      addr = offset;
      // Drive Address & Data valid
      @(posedge SAXI_aclk);
      #1;
      SAXI_awaddr  = addr;
      SAXI_awvalid = 1;
      SAXI_wdata   = data;
      SAXI_wvalid  = 1;
      SAXI_bready  = 0;
      // Address Response Phase
      @(negedge SAXI_aclk);
      while (SAXI_awready == 1'b0 && SAXI_wready == 1'b0)
        @(negedge SAXI_aclk);
      @(posedge SAXI_aclk);
      #1;
      SAXI_awaddr  = 0;
      SAXI_awvalid = 0;
      // Data Response Phase
//      @(negedge SAXI_aclk);
//      while (SAXI_wready == 1'b0)
//        @(negedge SAXI_aclk);
      @(posedge SAXI_aclk);
      #1;
      SAXI_wdata   = 0;
      SAXI_wvalid  = 0;
      // BRESP phase
      //@(negedge SAXI_aclk);
      while (SAXI_bvalid == 1'b0)
        @(negedge SAXI_aclk);
      @(posedge SAXI_aclk);
      resp = SAXI_bresp;
      if (resp != 0) $display ("Error AXI BRESP not equal 0");
      #1;
      SAXI_bready = 1;
      @(posedge SAXI_aclk);
      #1;
      SAXI_bready = 0;
    end
  endtask // axi_write
//Axil read task
  task axi_read;
    input  [31:0] offset;
    output [31:0] data;
    reg    [31:0] addr;
    reg     [1:0] resp;
    begin
      // Use address as in datasheet
      addr = offset;
      // Drive Address valid
      @(posedge SAXI_aclk);
      #1;
      SAXI_araddr  = addr;
      SAXI_arvalid = 1;
      SAXI_rready  = 0;
      // Address Response Phase
      @(negedge SAXI_aclk);
      while (SAXI_arready == 1'b0)
        @(negedge SAXI_aclk);
      @(posedge SAXI_aclk);
      #1;
      SAXI_araddr  = 0;
      SAXI_arvalid = 0;
      SAXI_rready  = 1;
      // Read Data Phase
      @(negedge SAXI_aclk);
      while (SAXI_rvalid == 1'b0)
        @(negedge SAXI_aclk);
      @(posedge SAXI_aclk);
      data = SAXI_rdata;
      resp = SAXI_rresp;
      if (resp != 0) $display ("Error AXI RRESP not equal 0");
      #1;
      SAXI_rready  = 0;
    end
  endtask // axi_read
endmodule
