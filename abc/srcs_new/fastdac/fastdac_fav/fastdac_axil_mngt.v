`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau, Hop DINH
// 
// Create Date: 07/07/2023 10:39:02 AM
// Design Name: Qline_turnkey
// Module Name: fastdac_axil_mngt
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Manage AXIL interface, assign jesd_transport registers to AXIL registers
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

	module fastdac_axil_mngt #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
        // Control data output
        // Control register
        output fastdac_en_jesd_o,
        output ld_ddr_status_o,
        output fastdac_reg_en_o,
        // output slv_reg_wren,
        output [7:0] fastdac_dpram_max_addr_seq_dac0_o,
        output [7:0] fastdac_dpram_max_addr_seq_dac1_o,
        output [14:0] fastdac_dpram_max_addr_rng_dac1_o,
        output fastdac_rng_mode_o,
        output fastdac_dac1_mode_o,
        output fastdac_dac0_mode_o,
        // output [7:0] fastdac_dpram_max_addr_pos_dac0_o,
        // output [7:0] fastdac_dpram_max_addr_pos_dac1_o,
        output [3:0]  fastdac_amp_dac1_shift_o,
        output [31:0] fastdac_amp_dac1_o,
        output [31:0] fastdac_amp_dac2_o,
        output fastdac_fb_mode_o,
        output fastdac_zero_mode_o,
        output [15:0] fastdac_up_offset_o,
        output [31:0] division_sp_o,
		output [3:0] fastdac_zero_pos_o,


        // output [14:0] fastdac_reg_alpha0_dac0_0_o,
        // output [14:0] fastdac_reg_alpha0_dac0_1_o,
        // output [14:0] fastdac_reg_alpha0_dac0_2_o,
        // output [14:0] fastdac_reg_alpha1_dac0_0_o,
        // output [14:0] fastdac_reg_alpha1_dac0_1_o,
        // output [14:0] fastdac_reg_alpha1_dac0_2_o,
        output [14:0] fastdac_reg_alpha0_dac1_0_o,
        output [14:0] fastdac_reg_alpha0_dac1_1_o,
        output [14:0] fastdac_reg_alpha0_dac1_2_o,
        output [14:0] fastdac_reg_alpha1_dac1_0_o,
        output [14:0] fastdac_reg_alpha1_dac1_1_o,
        // output [14:0] fastdac_reg_alpha1_dac1_2_o,
        // input [5:0]   fastdac_ddr_status_i,
        // Sequence Read memory
        output reg  fastdac_sequence_wen_o,
        output reg [9:0] fastdac_sequence_addr_o,
        output reg [31:0] fastdac_sequence_din_o,

        //Rng read memory
        output reg fastdac_rng_wen_o,
        output reg [11:0] fastdac_rng_addr_o,
        output reg [31:0] fastdac_rng_din_o,
        
        // Alpha position read memory
        output reg  fastdac_alpha_pos_wen_o,
        output reg [7:0] fastdac_alpha_pos_addr_o,
        output reg [31:0] fastdac_alpha_pos_din_o,
        
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg16;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;
	// 
	// Registers connections to output signal
	assign fastdac_en_jesd_o = slv_reg0[0];
	assign ld_ddr_status_o = slv_reg0[1];
	// assign fastdac_dpram_max_addr_seq_dac0_o = slv_reg1[6:0];
	// assign fastdac_dpram_max_addr_seq_dac1_o = slv_reg1[22:16];
	// assign fastdac_dpram_max_addr_pos_dac0_o = slv_reg2[7:0];
	// assign fastdac_dpram_max_addr_pos_dac1_o = slv_reg2[23:16];
	// assign amp_high_dac1_o = slv_reg2[15:0];
	assign fastdac_amp_dac1_shift_o = slv_reg1[3:0];
	assign fastdac_amp_dac1_o = slv_reg2[31:0];
	assign fastdac_amp_dac2_o = slv_reg6[31:0];

	// assign fastdac_reg_alpha0_dac0_0_o = slv_reg3[14:0];
	// assign fastdac_reg_alpha0_dac0_1_o = slv_reg3[30:16];
	assign fastdac_reg_en_o = slv_reg3[0]; 
	// assign fastdac_reg_alpha0_dac0_2_o = slv_reg4[14:0];
	// assign fastdac_reg_alpha1_dac0_0_o = slv_reg4[30:16];
	assign fastdac_dpram_max_addr_seq_dac0_o = slv_reg4[7:0];
	assign fastdac_dpram_max_addr_seq_dac1_o = slv_reg4[15:8];
	assign fastdac_dpram_max_addr_rng_dac1_o = slv_reg7[14:0];
	assign fastdac_rng_mode_o = slv_reg5[0];
	assign fastdac_dac1_mode_o = slv_reg5[1];
	assign fastdac_fb_mode_o = slv_reg5[2];
	assign fastdac_zero_mode_o = slv_reg5[3];
	assign fastdac_dac0_mode_o =slv_reg5[4];
	assign fastdac_up_offset_o = slv_reg1[31:16];
	assign division_sp_o = slv_reg8[31:0];
	assign fastdac_zero_pos_o = slv_reg1[7:4];
	// assign fastdac_reg_alpha1_dac0_1_o = slv_reg5[14:0];
	// assign fastdac_reg_alpha1_dac0_2_o = slv_reg5[30:16];
	// assign fastdac_reg_alpha0_dac1_0_o = slv_reg6[14:0];
	// assign fastdac_reg_alpha0_dac1_1_o = slv_reg6[30:16];
	// assign fastdac_reg_alpha0_dac1_2_o = slv_reg7[14:0];
	// assign fastdac_reg_alpha1_dac1_0_o = slv_reg7[30:16];
	// assign fastdac_reg_alpha1_dac1_1_o = slv_reg8[14:0];
	// assign fastdac_reg_alpha1_dac1_2_o = slv_reg8[30:16];
	// assign slv_reg16[5:0] = fastdac_ddr_status_i;
	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
		
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    reg access_ok;
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	      slv_reg8 <= 0;
	      fastdac_sequence_wen_o     <= 0;
	      fastdac_alpha_pos_wen_o    <= 0;
	      fastdac_rng_wen_o <= 0;
	      access_ok = 0;
	    end 
	  else begin
	    fastdac_sequence_wen_o     <= 0;
	    fastdac_alpha_pos_wen_o    <= 0;
	    fastdac_rng_wen_o <= 0;
	    if (slv_reg_wren)
	      begin
	        if (axi_awaddr < 4096)     // Write register access
	        begin
	           case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	               4'h0:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 0
	                   slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end  
	               4'h1:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 1
	                   slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end  
	               4'h2:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 2
	                   slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end  
	               4'h3:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 3
	                   slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end
	               4'h4:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 3
	                   slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end
	               4'h5:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 3
	                   slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end
	               4'h6:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 3
	                   slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end
	               4'h7:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 3
	                   slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end
	                4'h8:
	                   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                   // Respective byte enables are asserted as per write strobes 
	                   // Slave register 3
	                   slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                   end
	               default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                    end
	           endcase
	      end else begin  // Write sequence memory access
	           if (axi_awaddr < 8192)     // Write sequence memory access
	           begin

	               access_ok = 1;
	               fastdac_sequence_wen_o        <= 1'b1;
	               // fastdac_sequence_addr_o       <= {1'b0,axi_awaddr[10:2]};
	               fastdac_sequence_addr_o       <= {axi_awaddr[11:2]};
	               for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	               // Respective byte enables are asserted as per write strobes 
	               // Slave register 3
	                   fastdac_sequence_din_o[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	               end
	           end else begin // Write alpha position memory access
	               // fastdac_alpha_pos_wen_o       <= 1'b1;	               
	               // fastdac_alpha_pos_addr_o      <= {1'b0,axi_awaddr[9:2]};
	               // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	               // if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	               // // Respective byte enables are asserted as per write strobes 
	               // // Slave register 3
	               //     fastdac_alpha_pos_din_o[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	               access_ok = 1;
	               fastdac_rng_wen_o       <= 1'b1;	               
	               fastdac_rng_addr_o      <= {1'b0,axi_awaddr[12:2]};
	               for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	               // Respective byte enables are asserted as per write strobes 
	               // Slave register 3
	                   fastdac_rng_din_o[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];

	               end	               
	           end
	      end   
	  end
    end
  end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        4'h0   : reg_data_out <= slv_reg0;
	        4'h1   : reg_data_out <= slv_reg1;
	        4'h2   : reg_data_out <= slv_reg2;
	        4'h3   : reg_data_out <= slv_reg3;
	        4'h4   : reg_data_out <= slv_reg4;
	        4'h5   : reg_data_out <= slv_reg5;
	        4'h6   : reg_data_out <= slv_reg6;
	        4'h7   : reg_data_out <= slv_reg7;
	        4'h8   : reg_data_out <= slv_reg8;
	        default : reg_data_out <= slv_reg16;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here

	// User logic ends

endmodule
