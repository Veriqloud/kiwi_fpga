`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2023 10:25:49 AM
// Design Name: 
// Module Name: fastdac_pcietojesd204
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

`include "define.v"

module fastdac_pcietojesd204
    #(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface s_axil
		parameter integer C_s_axil_DATA_WIDTH	= 32,
		parameter integer C_s_axil_ADDR_WIDTH	= 12
	)
    (
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
		
        // Ports of AXI-s slave(alpha argument)
		input wire                                    s_axis_tclk,
		input wire                                    s_axis_tresetn,
		input wire [127 : 0]                          s_axis_tdata,
		input wire                                    s_axis_tvalid,
//		input wire s_axis_tlast,
		output wire                                   s_axis_tready,
		
        // Ports of control (synchronization) & status
		input                                         fastdac_sync_i,
		input [5:0]                                   fastdac_ddr_status_i,

        // Ports of AXI-s master(alpha argument)
		input                                         tx_core_clk,
		input                                         tx_core_reset,
		input                                         tx_reset_done_i,
		output reg [127 : 0]                          m_axis_tdata,
		input wire                                    m_axis_tready
		// For debug only
//		output reg tx_core_diclk_o,
//		output reg tx_sysref_diclk_o
    );
    
    // Instantiation of Axi Bus Interface s_axil
    // Includes registers and DPRAM
    wire               fastdac_en_jesd_int;
    wire               ld_ddr_status_int;
    reg [2:0]          fastdac_en_jesd_r;
    wire               fastdac_sequence_wen_int;
	wire  [8:0]        fastdac_sequence_addr_int; 
	wire  [31:0]       fastdac_sequence_din_int;
	wire               fastdac_alpha_pos_wen_int;
	wire  [7:0]        fastdac_alpha_pos_addr_int; 
	wire  [31:0]       fastdac_alpha_pos_din_int;
	wire [6:0]         fastdac_dpram_max_addr_seq_dac0_int;
	wire [6:0]         fastdac_dpram_max_addr_seq_dac1_int;
	wire [7:0]         fastdac_dpram_max_addr_pos_dac0_int;
	wire [7:0]         fastdac_dpram_max_addr_pos_dac1_int;
	wire [14:0]        fastdac_reg_alpha0_dac0_0_int;
	wire [14:0]        fastdac_reg_alpha0_dac0_1_int;
	wire [14:0]        fastdac_reg_alpha0_dac0_2_int;
	wire [14:0]        fastdac_reg_alpha1_dac0_0_int;
	wire [14:0]        fastdac_reg_alpha1_dac0_1_int;
	wire [14:0]        fastdac_reg_alpha1_dac0_2_int;
	wire [14:0]        fastdac_reg_alpha0_dac1_0_int;
	wire [14:0]        fastdac_reg_alpha0_dac1_1_int;
	wire [14:0]        fastdac_reg_alpha0_dac1_2_int;
	wire [14:0]        fastdac_reg_alpha1_dac1_0_int;
	wire [14:0]        fastdac_reg_alpha1_dac1_1_int;
	wire [14:0]        fastdac_reg_alpha1_dac1_2_int;
	
	fastdac_axil_mngt # ( 
		.C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
	) fastdac_axil_mngt_inst (
	    .fastdac_en_jesd_o(fastdac_en_jesd_int),
	    .ld_ddr_status_o(ld_ddr_status_int),
	    .fastdac_dpram_max_addr_seq_dac0_o(fastdac_dpram_max_addr_seq_dac0_int),
	    .fastdac_dpram_max_addr_seq_dac1_o(fastdac_dpram_max_addr_seq_dac1_int),
	    .fastdac_dpram_max_addr_pos_dac0_o(fastdac_dpram_max_addr_pos_dac0_int),
	    .fastdac_dpram_max_addr_pos_dac1_o(fastdac_dpram_max_addr_pos_dac1_int),
	    .fastdac_reg_alpha0_dac0_0_o(fastdac_reg_alpha0_dac0_0_int),
	    .fastdac_reg_alpha0_dac0_1_o(fastdac_reg_alpha0_dac0_1_int),
	    .fastdac_reg_alpha0_dac0_2_o(fastdac_reg_alpha0_dac0_2_int),
	    .fastdac_reg_alpha1_dac0_0_o(fastdac_reg_alpha1_dac0_0_int),
	    .fastdac_reg_alpha1_dac0_1_o(fastdac_reg_alpha1_dac0_1_int),
	    .fastdac_reg_alpha1_dac0_2_o(fastdac_reg_alpha1_dac0_2_int),
	    .fastdac_reg_alpha0_dac1_0_o(fastdac_reg_alpha0_dac1_0_int),
	    .fastdac_reg_alpha0_dac1_1_o(fastdac_reg_alpha0_dac1_1_int),
	    .fastdac_reg_alpha0_dac1_2_o(fastdac_reg_alpha0_dac1_2_int),
	    .fastdac_reg_alpha1_dac1_0_o(fastdac_reg_alpha1_dac1_0_int),
	    .fastdac_reg_alpha1_dac1_1_o(fastdac_reg_alpha1_dac1_1_int),
	    .fastdac_reg_alpha1_dac1_2_o(fastdac_reg_alpha1_dac1_2_int),
	    .fastdac_ddr_status_i(fastdac_ddr_status_r),
	    .fastdac_sequence_wen_o(fastdac_sequence_wen_int),
	    .fastdac_sequence_addr_o(fastdac_sequence_addr_int),
	    .fastdac_sequence_din_o(fastdac_sequence_din_int),
	    .fastdac_alpha_pos_wen_o(fastdac_alpha_pos_wen_int),
	    .fastdac_alpha_pos_addr_o(fastdac_alpha_pos_addr_int),
	    .fastdac_alpha_pos_din_o(fastdac_alpha_pos_din_int),
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
	
	wire           almost_full_dac0_int,almost_full_dac1_int;
	wire [7:0]     fastdac_dpram_alpha_dout_dac0_int;
	wire           fastdac_dpram_alpha_rden_dac0_int;
	wire [15:0]    fastdac_dpram_pos_data_dac0_int;
	wire [15:0]    fastdac_dpram_pos_data_dac1_int;
	
	assign s_axis_tready = !(almost_full_dac0_int | almost_full_dac1_int);
	
	fifo_64x8 fifo_alpha_64x8_dac0_inst (
        .rst(s_axis_tresetn),                           // input wire rst
        .wr_clk(s_axis_tclk),                           // input wire wr_clk
        .rd_clk(tx_core_clk),                           // input wire rd_clk
        .din(s_axis_tdata[63:0]),                       // input wire [63 : 0] din
        .wr_en(s_axis_tvalid),                          // input wire wr_en
        .rd_en(fastdac_dpram_alpha_rden_dac0_int),          // input wire rd_en
        .dout(fastdac_dpram_alpha_dout_dac0_int),           // output wire [7 : 0] dout
        .full(),                                        // output wire full
        .almost_full(almost_full_dac0_int),                 // output wire almost_full
        .empty(),                                       // output wire empty
        .wr_rst_busy(),                                 // output wire wr_rst_busy
        .rd_rst_busy()                                  // output wire rd_rst_busy
    );
    //assign fastdac_dpram_alpha_rden_dac0_int = m_axis_tready & fastdac_en_jesd_r[2];
    assign fastdac_dpram_alpha_rden_dac0_int =  (fastdac_dpram_pos_data_dac0_int[15:12] != 4'hF) & fastdac_en_jesd_r[2] ? 1 : 0;


	wire [7:0] fastdac_dpram_alpha_dout_dac1_int;
	wire fastdac_dpram_alpha_rden_dac1_int;
    fifo_64x8 fifo_alpha_64x8_dac1_inst (
        .rst(s_axis_tresetn),                           // input wire rst
        .wr_clk(s_axis_tclk),                           // input wire wr_clk
        .rd_clk(tx_core_clk),                           // input wire rd_clk
        .din(s_axis_tdata[127:64]),                     // input wire [63 : 0] din
        .wr_en(s_axis_tvalid),                          // input wire wr_en
        .rd_en(fastdac_dpram_alpha_rden_dac1_int),          // input wire rd_en
        .dout(fastdac_dpram_alpha_dout_dac1_int),           // output wire [7: 0] dout
        .full(),                                        // output wire full
        .almost_full(almost_full_dac1_int),                 // output wire almost_full
        .empty(),                                       // output wire empty
        .wr_rst_busy(),                                 // output wire wr_rst_busy
        .rd_rst_busy()                                  // output wire rd_rst_busy
    );
    //assign fastdac_dpram_alpha_rden_dac1_int = m_axis_tready & fastdac_en_jesd_r[2];
    assign fastdac_dpram_alpha_rden_dac1_int =  (fastdac_dpram_pos_data_dac1_int[15:12] != 4'hF) & fastdac_en_jesd_r[2] ? 1 : 0;
	//wire fastdac_dpram_seq_rden;
	
    reg [6:0] fastdac_dpram_seq_addr_dac0_r;
    wire [63:0] fastdac_dpram_seq_data_dac0_int;
    reg fastdac_dpram_alpha_rden_dac_r;
    dpram_out_wider_in #(
    .RAM_INIT("sin_sequence_dac0.mem"),
    .WIDTHA(16),
    .SIZEA(512),
    .ADDRWIDTHA(9),
    .WIDTHB(64),
    .SIZEB(128),
    .ADDRWIDTHB(7)) 
    dpram_seq_64x128_dac0_inst(
    .clkA(s_axil_aclk), 
    .clkB(tx_core_clk), 
    .enaA(fastdac_sequence_wen_int), 
    .weA(fastdac_sequence_wen_int), 
    .enaB(fastdac_dpram_alpha_rden_dac_r|m_axis_tready), 
    .addrA(fastdac_sequence_addr_int), 
    .addrB(fastdac_dpram_seq_addr_dac0_r), 
    .diA(fastdac_sequence_din_int[15:0]),
    .doB(fastdac_dpram_seq_data_dac0_int));
    //assign fastdac_dpram_seq_rden_dac0 = m_axis_tready & fastdac_en_jesd_r[2];
    
    reg [6:0] fastdac_dpram_seq_addr_dac1_r;
    wire [63:0] fastdac_dpram_seq_data_dac1_int;
    dpram_out_wider_in #(
    .RAM_INIT("sin_sequence_dac1.mem"),
    .WIDTHA(16),
    .SIZEA(512),
    .ADDRWIDTHA(9),
    .WIDTHB(64),
    .SIZEB(128),
    .ADDRWIDTHB(7)) 
    dpram_seq_64x128_dac1_inst(
    .clkA(s_axil_aclk), 
    .clkB(tx_core_clk), 
    .enaA(fastdac_sequence_wen_int), 
    .weA(fastdac_sequence_wen_int), 
    .enaB(fastdac_dpram_alpha_rden_dac_r|m_axis_tready), 
    .addrA(fastdac_sequence_addr_int), 
    .addrB(fastdac_dpram_seq_addr_dac1_r), 
    .diA(fastdac_sequence_din_int[31:16]),
    .doB(fastdac_dpram_seq_data_dac1_int));
 
    
    reg [7:0] fastdac_dpram_seq_addr_r,fastdac_dpram_seq_addr_2r;
    wire [15:0] fastdac_dpram_seq_data_temp;
 `ifdef c_simulation begin 
    dpram_in_wider_out #(
    .RAM_INIT("sin_sequence.init"),
    .WIDTHA(64),
    .SIZEA(64),
    .ADDRWIDTHA(8),
    .WIDTHB(16),
    .SIZEB(256),
    .ADDRWIDTHB(8)) 
    dpram_seq_64x16_inst(
    .clkA(tx_core_clk), 
    .clkB(tx_core_clk), 
    .enaA(1), 
    .weA(1), 
    .enaB(1), 
    .addrA(fastdac_dpram_seq_addr_r), 
    .addrB(fastdac_dpram_seq_addr_2r), 
//    .diA({m_axis_tdata[63:56],m_axis_tdata[31:24],m_axis_tdata[55:48],m_axis_tdata[23:16],m_axis_tdata[47:40],m_axis_tdata[15:8],m_axis_tdata[39:32],m_axis_tdata[7:0]}),
    .diA({m_axis_tdata[31:24],m_axis_tdata[63:56],m_axis_tdata[23:16],m_axis_tdata[55:48],m_axis_tdata[15:8],m_axis_tdata[47:40],m_axis_tdata[7:0],m_axis_tdata[39:32]}),
    .doB(fastdac_dpram_seq_data_temp));
    end
 `endif
 
 `ifdef c_simulation begin
    wire [15:0] fastdac_dpram_seq_data_temp2;
    dpram_in_wider_out #(
    .RAM_INIT("sin_sequence.init"),
    .WIDTHA(64),
    .SIZEA(64),
    .ADDRWIDTHA(8),
    .WIDTHB(16),
    .SIZEB(256),
    .ADDRWIDTHB(8)) 
    dpram_seq_64x16_inst2(
    .clkA(tx_core_clk), 
    .clkB(tx_core_clk), 
    .enaA(1), 
    .weA(1), 
    .enaB(1), 
    .addrA(fastdac_dpram_seq_addr_r), 
    .addrB(fastdac_dpram_seq_addr_2r), 
//    .diA({m_axis_tdata[63:56],m_axis_tdata[31:24],m_axis_tdata[55:48],m_axis_tdata[23:16],m_axis_tdata[47:40],m_axis_tdata[15:8],m_axis_tdata[39:32],m_axis_tdata[7:0]}),
    .diA({m_axis_tdata[95:88],m_axis_tdata[127:120],m_axis_tdata[87:80],m_axis_tdata[119:112],m_axis_tdata[79:72],m_axis_tdata[111:104],m_axis_tdata[71:64],m_axis_tdata[103:96]}),
    .doB(fastdac_dpram_seq_data_temp2));
    end
 `endif   
    //assign fastdac_dpram_seq_rden = m_axis_tready & fastdac_en_jesd_r[2];
    
	//wire fastdac_dpram_pos_rden;
    reg [7:0] fastdac_dpram_pos_addr_dac0_r;
    dpram_out_equal_in #(
        .RAM_INIT("alpha_pos_dac0.mem"),
        .WIDTH(16),
        .SIZE(256),
        .ADDRWIDTH(8))
    dpram_pos_16x256_dac0_inst (
        .clka(s_axil_aclk),                                     // input wire clka
        .ena(fastdac_alpha_pos_wen_int),                            // input wire ena
        .wea(fastdac_alpha_pos_wen_int),                            // input wire [0 : 0] wea
        .addra(fastdac_alpha_pos_addr_int),                         // input wire [7 : 0] addra
        .dia(fastdac_alpha_pos_din_int[15:0]),                      // input wire [15 : 0] dina
        .clkb(tx_core_clk),                                     // input wire clkb
        .enb(fastdac_dpram_alpha_rden_dac_r|m_axis_tready),       // input wire enb
        .addrb(fastdac_dpram_pos_addr_dac0_r),                    // input wire [7: 0] addrb
        .dob(fastdac_dpram_pos_data_dac0_int)                       // output wire [15 : 0] doutb 
    );
    
    reg [7:0] fastdac_dpram_pos_addr_dac1_r;
    dpram_out_equal_in #(
        .RAM_INIT("alpha_pos_dac1.mem"),
        .WIDTH(16),
        .SIZE(256),
        .ADDRWIDTH(8))
    dpram_pos_16x256_dac1_inst (
        .clka(s_axil_aclk),                                     // input wire clka
        .ena(fastdac_alpha_pos_wen_int),                            // input wire ena
        .wea(fastdac_alpha_pos_wen_int),                            // input wire [0 : 0] wea
        .addra(fastdac_alpha_pos_addr_int),                         // input wire [7 : 0] addra
        .dia(fastdac_alpha_pos_din_int[31:16]),                     // input wire [15 : 0] dina
        .clkb(tx_core_clk),                                     // input wire clkb
        .enb(fastdac_dpram_alpha_rden_dac_r|m_axis_tready),       // input wire enb
        .addrb(fastdac_dpram_pos_addr_dac1_r),                    // input wire [7: 0] addrb
        .dob(fastdac_dpram_pos_data_dac1_int)                       // output wire [15 : 0] doutb 
    );
    
    //assign fastdac_dpram_pos_rden = m_axis_tready & fastdac_en_jesd_r[2];
    
    // Handle the alpha instertion
    reg  end_of_seq_r;
//    reg [1:0] fastdac_sync_r;
    
    // Declare states
	localparam S0 = 0, S1 = 1, S2 = 2;
    reg [1:0] addr_state_r;
    always@(posedge tx_core_clk, posedge tx_core_reset)
    begin   
        if (tx_core_reset)
        begin
            fastdac_en_jesd_r                 <= 0;
            addr_state_r                      <= S0;
            fastdac_dpram_alpha_rden_dac_r    <= 0;
            fastdac_dpram_pos_addr_dac0_r     <= 0;
            fastdac_dpram_pos_addr_dac1_r     <= 0;
            fastdac_dpram_seq_addr_dac0_r     <= 0;
            fastdac_dpram_seq_addr_dac1_r     <= 0;
            fastdac_dpram_seq_addr_2r         <= 0;
            end_of_seq_r                      <= 0;
//            fastdac_sync_r                  <= 0;
            
        end else begin 
            fastdac_en_jesd_r   <= {fastdac_en_jesd_r[1:0],fastdac_en_jesd_int};
//            fastdac_sync_r      <= {fastdac_sync_r[0],fastdac_sync_i};
            fastdac_dpram_alpha_rden_dac_r   <= 0;
//            if (fastdac_en_jesd_r[2] && tx_reset_done_i && fastdac_sync_r[1])
            if (fastdac_en_jesd_r[2] && tx_reset_done_i && fastdac_sync_i)

            begin 

                // Handle adress bus
                case (addr_state_r)
                    S0:  begin
                        fastdac_dpram_pos_addr_dac0_r     <= 0;
                        fastdac_dpram_pos_addr_dac1_r     <= 0;
                        fastdac_dpram_seq_addr_dac0_r     <= 0;
                        fastdac_dpram_seq_addr_dac1_r     <= 0;
                        addr_state_r                      <= S1;
                        fastdac_dpram_alpha_rden_dac_r    <= 1;
                    end
                    S1: begin
                        if (fastdac_dpram_pos_addr_dac0_r == (fastdac_dpram_max_addr_pos_dac0_int-1)) begin
	                       end_of_seq_r <= 1;
	                       fastdac_dpram_pos_addr_dac0_r  <= 0;
	                    end else
	                       fastdac_dpram_pos_addr_dac0_r  <= fastdac_dpram_pos_addr_dac0_r + 1;
	               
	                   // Alpha pos DAC 1
	                   if (fastdac_dpram_pos_addr_dac1_r == (fastdac_dpram_max_addr_pos_dac1_int-1))
	                       fastdac_dpram_pos_addr_dac1_r  <= 0;
	                   else
	                       fastdac_dpram_pos_addr_dac1_r  <= fastdac_dpram_pos_addr_dac1_r + 1;
	           
	                   // Sequencer DAC 0
	                   if (fastdac_dpram_seq_addr_dac0_r == (fastdac_dpram_max_addr_seq_dac0_int-1))
	                       fastdac_dpram_seq_addr_dac0_r  <= 0;
	                   else
	                       fastdac_dpram_seq_addr_dac0_r  <= fastdac_dpram_seq_addr_dac0_r + 1;
	               
	                   // Sequencer DAC 1
	                   if (fastdac_dpram_seq_addr_dac1_r == (fastdac_dpram_max_addr_seq_dac1_int-1))
	                       fastdac_dpram_seq_addr_dac1_r  <= 0;
	                   else
	                       fastdac_dpram_seq_addr_dac1_r  <= fastdac_dpram_seq_addr_dac1_r + 1;
	                       
	                   addr_state_r                      <= S2;
                    end 
                    S2: begin
                        if (m_axis_tready) begin
                            // Handle adress bus
                            // Alpha pos DAC 0
                            if (fastdac_dpram_pos_addr_dac0_r == (fastdac_dpram_max_addr_pos_dac0_int-1)) begin
	                           end_of_seq_r <= 1;
	                           fastdac_dpram_pos_addr_dac0_r  <= 0;
	                       end else
	                           fastdac_dpram_pos_addr_dac0_r  <= fastdac_dpram_pos_addr_dac0_r + 1;
	               
	                       // Alpha pos DAC 1
	                       if (fastdac_dpram_pos_addr_dac1_r == (fastdac_dpram_max_addr_pos_dac1_int-1))
	                           fastdac_dpram_pos_addr_dac1_r  <= 0;
	                       else
	                           fastdac_dpram_pos_addr_dac1_r  <= fastdac_dpram_pos_addr_dac1_r + 1;
	           
	                       // Sequencer DAC 0
	                       if (fastdac_dpram_seq_addr_dac0_r == (fastdac_dpram_max_addr_seq_dac0_int-1))
	                           fastdac_dpram_seq_addr_dac0_r  <= 0;
	                       else
	                           fastdac_dpram_seq_addr_dac0_r  <= fastdac_dpram_seq_addr_dac0_r + 1;
	               
	                       // Sequencer DAC 1
	                       if (fastdac_dpram_seq_addr_dac1_r == (fastdac_dpram_max_addr_seq_dac1_int-1))
	                           fastdac_dpram_seq_addr_dac1_r  <= 0;
	                       else
	                           fastdac_dpram_seq_addr_dac1_r  <= fastdac_dpram_seq_addr_dac1_r + 1;
	                       
	                       addr_state_r                      <= S2;

                    end 
                    end 

                default : ;
            endcase     
`ifdef c_simulation begin   
	        if (end_of_seq_r == 0)
	           fastdac_dpram_seq_addr_r <= fastdac_dpram_seq_addr_dac0_r;
	        else
	           fastdac_dpram_seq_addr_r <= 255;
	               
	        if (fastdac_dpram_seq_addr_2r == (4*fastdac_dpram_max_addr_seq_dac0_int-1))
               fastdac_dpram_seq_addr_2r <= 0;
            else
               fastdac_dpram_seq_addr_2r <= fastdac_dpram_seq_addr_2r+1;
`endif	           
        end else begin
            addr_state_r                      <= S0;
            fastdac_dpram_pos_addr_dac0_r     <= 0;
            fastdac_dpram_pos_addr_dac1_r     <= 0;
            fastdac_dpram_seq_addr_dac0_r     <= 0;
            fastdac_dpram_seq_addr_dac1_r     <= 0;
        end    
        end

    end
    
    reg [5:0] fastdac_ddr_status_r;
    reg [2:0] ld_ddr_status_r;      
    always@(posedge tx_core_clk, posedge tx_core_reset)
    begin   
        if (tx_core_reset)
        begin
            fastdac_ddr_status_r    <= 0;
            ld_ddr_status_r         <= 0;
        end else
        begin
            ld_ddr_status_r    <= {ld_ddr_status_r[1:0],ld_ddr_status_int};
            if (ld_ddr_status_r[2]  == 0 && ld_ddr_status_r[1]  == 1)
                fastdac_ddr_status_r    <= fastdac_ddr_status_i;

        end
    end
    //reg alpha_selected_dac0,alpha_selected_dac1;
    //integer	 byte_index_dac1,word_index_dac1,alpha_index_dac1;

    /*******************************************************/
    /*                    FUNCTIONS                        */
    /*******************************************************/

    function [63:0] format_data_to_jesd204;
        
        input [3*15-1:0] reg_alpha0_dac,reg_alpha1_dac;
        input [3:0] dpram_alpha;
        input [63:0] dpram_seq;
        input [15:0] dpram_pos_alpha;
    
        integer	 byte_index_dac,word_index_dac,alpha_index_dac;
        reg [30:0] fastdac_dpram_alpha_dac;
        reg [15:0] fastdac_dpram_alpha0_dac;
        reg [15:0] fastdac_dpram_minusalpha0_dac;
        reg [15:0] fastdac_dpram_alpha1_dac;
        reg [15:0] fastdac_dpram_minusalpha1_dac;
        reg alpha_selected_dac;
        
    begin
        
        case (dpram_alpha[1:0])
            0:  fastdac_dpram_alpha_dac[14:0]    =  reg_alpha0_dac[14:0];
            1:  fastdac_dpram_alpha_dac[14:0]    =  reg_alpha0_dac[29:15];
            2:  fastdac_dpram_alpha_dac[14:0]    =  reg_alpha0_dac[44:30];
            default : 
                fastdac_dpram_alpha_dac[14:0]    =  reg_alpha0_dac[14:0];
        endcase
        
        case (dpram_alpha[3:2])
            0:  fastdac_dpram_alpha_dac[30:16]    =  reg_alpha1_dac[14:0];
            1:  fastdac_dpram_alpha_dac[30:16]    =  reg_alpha1_dac[29:15];
            2:  fastdac_dpram_alpha_dac[30:16]    =  reg_alpha1_dac[44:30];
            default : 
                fastdac_dpram_alpha_dac[30:16]    =  reg_alpha1_dac[14:0];
        endcase
        
        fastdac_dpram_alpha0_dac            = 16'h8000 + fastdac_dpram_alpha_dac[14:0];
        fastdac_dpram_minusalpha0_dac       = 16'h8000 - fastdac_dpram_alpha_dac[14:0];
        fastdac_dpram_alpha1_dac            = 16'h8000 + fastdac_dpram_alpha_dac[30:16];
        fastdac_dpram_minusalpha1_dac       = 16'h8000 - fastdac_dpram_alpha_dac[30:16];
        
        // DAC 0
        for ( byte_index_dac = 0; byte_index_dac <= 4-1; byte_index_dac = byte_index_dac+1 )
        begin
            for ( word_index_dac = 0; word_index_dac <= 2-1; word_index_dac = word_index_dac+1 )
            begin
                alpha_selected_dac = 0;
                for (alpha_index_dac = 0; alpha_index_dac <= 4-1; alpha_index_dac = alpha_index_dac+1 )
                begin
                    if (alpha_selected_dac == 0)
	                 if (byte_index_dac == dpram_pos_alpha[alpha_index_dac*4+:4])  // Alpha insertion
	                       begin
	                           if (alpha_selected_dac == 0)
	                           alpha_selected_dac = 1;
	                           case (alpha_index_dac) 
	                               0 : // Q and I have the same alpha
	                                   format_data_to_jesd204[(byte_index_dac*8) + (word_index_dac*32) +: 8]  = fastdac_dpram_alpha0_dac[((1-word_index_dac)*8) +: 8];
	                               1 : // Q and I have the same alpha
	                                   format_data_to_jesd204[(byte_index_dac*8) + (word_index_dac*32) +: 8]  = fastdac_dpram_minusalpha0_dac[((1-word_index_dac)*8) +: 8];
	                               2 : // Q and I have the same alpha
	                                   format_data_to_jesd204[(byte_index_dac*8) + (word_index_dac*32) +: 8]  = fastdac_dpram_alpha1_dac[((1-word_index_dac)*8) +: 8];
	                               3 : // Q and I have the same alpha
	                                   format_data_to_jesd204[(byte_index_dac*8) + (word_index_dac*32) +: 8]  = fastdac_dpram_minusalpha1_dac[((1-word_index_dac)*8) +: 8];
	                           endcase  
	                 end else // Format output
	                       format_data_to_jesd204[(byte_index_dac*8) + ((word_index_dac*32)) +: 8]  = dpram_seq[(byte_index_dac*16)  + ((1-word_index_dac)*8) +: 8];
	           end
	       end
        end
     end
 endfunction
 
reg [63:0]    m_axis_tdata_temp1;
reg [63:0]    m_axis_tdata_temp2;
 always @(*) 
 begin
    // DAC 0
    m_axis_tdata_temp1  = format_data_to_jesd204(  {fastdac_reg_alpha0_dac0_2_int,fastdac_reg_alpha0_dac0_1_int,fastdac_reg_alpha0_dac0_0_int},
                                                    {fastdac_reg_alpha1_dac0_2_int,fastdac_reg_alpha1_dac0_1_int,fastdac_reg_alpha1_dac0_0_int},
                                                    fastdac_dpram_alpha_dout_dac0_int,fastdac_dpram_seq_data_dac0_int,fastdac_dpram_pos_data_dac0_int);
    // DAC 1
    m_axis_tdata_temp2 =  format_data_to_jesd204(   {fastdac_reg_alpha0_dac1_2_int,fastdac_reg_alpha0_dac1_1_int,fastdac_reg_alpha0_dac1_0_int},
                                                    {fastdac_reg_alpha1_dac1_2_int,fastdac_reg_alpha1_dac1_1_int,fastdac_reg_alpha1_dac1_0_int},
                                                    fastdac_dpram_alpha_dout_dac1_int,fastdac_dpram_seq_data_dac1_int,fastdac_dpram_pos_data_dac1_int);
    m_axis_tdata[127:0]  <= {m_axis_tdata_temp2,m_axis_tdata_temp1};

 end

// function [63:0] format_data_to_jesd204;
//     input [63:0] dpram_seq;
//     integer byte_index_dac,word_index_dac;

//     for ( byte_index_dac = 0; byte_index_dac <= 4-1; byte_index_dac = byte_index_dac+1 ) begin
//         for ( word_index_dac = 0; word_index_dac <= 2-1; word_index_dac = word_index_dac+1 ) begin
//             format_data_to_jesd204[(byte_index_dac*8) + ((word_index_dac*32)) +: 8]  = dpram_seq[(byte_index_dac*16)  + ((1-word_index_dac)*8) +: 8];
//         end
//     end
// endfunction

// reg [63:0] m_axis_tdata0;
// reg [63:0] m_axis_tdata1;

// always @(*) begin
//     m_axis_tdata0 = format_data_to_jesd204 (seq0);
//     m_axis_tdata1 = format_data_to_jesd204 (seq1);
//     m_axis_tdata [127:0] <= {m_axis_tdata1,m_axis_tdata0};
// end
        
endmodule    