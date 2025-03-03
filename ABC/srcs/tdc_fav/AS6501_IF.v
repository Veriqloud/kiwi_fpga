module AS6501_IF (
    
    input           lclk_i,
    // input           lrstn_i,
    input 			lrst_i,
    input           linterrupt_i,
    // Control register
    input           enable,
    input           command_enable,
    input [2:0]		command_i,
    //input 			command_get_gc,
    // input  [6:0]    AS6501_BURST_SIZE_i,
    // input  [5:0]    index_bitwise_i,
    // input  [5:0]    stop_bitwise_i,
    input 			start_gc_i,
    input [15:0]	index_stop_bitwise_i,
    input [31:0]	gate0_i,
    input [31:0] 	gate1_i,
    input  [15:0]   shift_tdc_time_i,
    input  [15:0]	shift_gc_back_i,
    input 			reg_enable_tdc_i,
    input 			reg_enable200_i,


    // Stop A
    input           frame_i,
    input           sdi_i,

    // AXI-Stream to fifo
    input 			m_axis_clk,
    output [127:0]	m_axis_tdata,
    output 			m_axis_tvalid,
    output [3:0]	m_axis_tuser,
    input 			m_axis_tready,
    output			fifo_calib_rst,

    // AXI-Stream to fifo_gc
    // output[63:0]      m_axis_tdata_gc,
    // output[3:0]        m_axis_tuser_gc,
    // output             m_axis_tvalid_gc,
    // input              m_axis_tready_gc,
    // output 			   fifo_gc_rst,
    //Debug
    output wire [31:0] 	debug_tdc_data,
    output wire 		debug_tdc_valid,
    output wire [127:0] debug_m_axis_data,
    output wire 		debug_m_axis_valid,


    //Signals for global counter
    input clk200_i,
    input rd_en_4,
    input gc_rst,
    input pps_i,

    //Fifo flags
    // input fifo_calib_full,
    // input fifo_calib_empty,

    //Debug

    // input clk5,
    // input arstn,
    output tvalid200,
    output [31:0] tdata200,
    output [1:0] click_result,
    output start_gc_o,
    output [47:0] gc,
    output [47:0] gc_time_valid,
    output [2:0] command_enable_r,
    output [3:0] tvalid200_r,
    output [3:0] time_ref_gc,
    output [5:0] index_shift_gc,

    //Output ports to ddr_data module
    output wire [15:0] tdata200_mod,
    output wire [31:0] gate_pos0,
    output wire [31:0] gate_pos1,
    output wire [31:0] gate_pos2,
    output wire [31:0] gate_pos3,
    //Output ports
    output [31:0] total_count_o,
    output [31:0] click0_count_o,
    output [31:0] click1_count_o,
    output [31:0] total_count,
    output data_count_valid_o

);

// Switch domain from aclk to lclk_i
	(* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable_r;
	reg [15:0] index_stop_bitwise_r;

	initial begin
		index_stop_bitwise_r <= 0;
	end

	always @(posedge lclk_i) begin
		reg_enable_r <= {reg_enable_r[1:0],reg_enable_tdc_i};
		if(reg_enable_r[2] == 0 && reg_enable_r[1] == 1) begin
			index_stop_bitwise_r <= index_stop_bitwise_i;
		end
	end
//Switch domain from aclk to clk200_i
	(* ASYNC_REG = "TRUE" *) reg [2:0] reg_enable200_r;
	reg [15:0] shift_tdc_time_r;
	reg [15:0] shift_gc_back_r;
	reg [31:0] gate0_r;
	reg [31:0] gate1_r;
	reg [2:0]  command_r;
	initial begin
		reg_enable200_r <= 0;
		shift_tdc_time_r <= 0;
		shift_gc_back_r <= 0;
		gate0_r <= 0;
		gate1_r <= 0;
		command_r <= 0;
	end

	always @(posedge clk200_i) begin
		reg_enable200_r <= {reg_enable200_r[1:0],reg_enable200_i};
		if(reg_enable200_r[2] == 0 && reg_enable200_r[1] == 1) begin
			shift_gc_back_r <= shift_gc_back_i;
			shift_tdc_time_r <= shift_tdc_time_i;
			gate0_r <= gate0_i;
			gate1_r <= gate1_i;
			command_r <= command_i;	
		end	
	end
//Assign internal reg/wire to external register	
	wire [5:0] index_bitwise_i;
	wire [5:0] stop_bitwise_i;
	assign index_bitwise_i = index_stop_bitwise_r[5:0];
	assign stop_bitwise_i = index_stop_bitwise_r[13:8];

        
     // AXI-Stream to fifo 
    reg[127:0]      m_axis_tdata;
    reg[3:0]        m_axis_tuser;
    reg             m_axis_tvalid;
    reg             m_axis_tlast;
    wire            m_axis_tready;

    //AXI-Stream to fifo_gc
    reg[63:0]      m_axis_tdata_gc;
    reg[3:0]        m_axis_tuser_gc;
    reg             m_axis_tvalid_gc;
    reg             m_axis_tlast_gc;
    wire            m_axis_tready_gc;
    
    // Resynchro
    reg [2:0]                      	linterrupt_r;
    // Internal register
    reg [31:0]                      index_stop;
    reg [5:0]                       index_stop_cpt;
    reg                             shift_rcv_sdi_en,shift_rcv_sdi_ld;
    reg                             sdi_r,sdi_2r,frame_r;

    reg[31:0] 	tdc_tdata;
    reg 		tdc_tvalid;

	assign debug_tdc_data = tdc_tdata;
	assign debug_tdc_valid = tdc_tvalid;

	assign debug_m_axis_data = m_axis_tdata;
	assign debug_m_axis_valid = m_axis_tvalid;
    

// State machine
	reg fifo_rst;
	// Declare states
	reg [2:0]	state;
	parameter S0_0 = 6,S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5;

	
	// Output depends only on the state
	always @ (state) begin
	   m_axis_tuser            <= 0;
	   m_axis_tlast            <= 1'b1;
	   tdc_tvalid           <= 1'b0;
	   shift_rcv_sdi_en        <= 1'b0;
	   shift_rcv_sdi_ld        <= 1'b0;
	   fifo_rst                <= 1'b0;
		case (state)
		    S0_0:
		      fifo_rst                <= 1'b1;
		    S1: 
		      shift_rcv_sdi_ld        <= 1'b1;
		    S2:
		      shift_rcv_sdi_en        <= 1'b1;
		    S3: begin
		      shift_rcv_sdi_en        <= 1'b1;
		      end
		    S4:
		      shift_rcv_sdi_en        <= 1'b1;
			S5: 
			  tdc_tvalid   <= 1'b1;
		    default:;              				
	   endcase
	 end
	//assign m_axis_tready       = 1'b1;
	(* ASYNC_REG = "TRUE" *) reg [2:0] enable_axi_r;
	reg [3:0] counter_stretch;

	initial begin
		state <= S0_0;
		counter_stretch <= 0;
	end
	
	// Determine the next state
	// always @ (posedge lclk_i or negedge lrstn_i) begin
	always @(posedge lclk_i or posedge lrst_i) begin	
		// if (!lrstn_i)
		if (lrst_i)
		begin
			state            <= S0_0;
			linterrupt_r     <= {3{1'b1}};
			tdc_tdata     <= 0;
		    index_stop_cpt   <= 0;
		    index_stop       <= 0;
		    frame_r          <= 0;
		    sdi_r            <= 0;
		    sdi_2r           <= 0;
		    enable_axi_r     <= 0;
		    counter_stretch <= 0;
		    
		end else begin
		    
		    linterrupt_r[2:0] <= {linterrupt_r[1:0],linterrupt_i};
		    enable_axi_r      <= {enable_axi_r[1:0],enable};
		    sdi_r             <= sdi_i;
		    sdi_2r            <= sdi_r;
            frame_r           <= frame_i;
            
            if (shift_rcv_sdi_ld)
                index_stop                    <= 0;
            else
                if (shift_rcv_sdi_en)
                    index_stop                    <= {index_stop[30:0],sdi_2r};
                
			
			case (state)
			
				S0_0:
				    if (enable_axi_r[2])
					   state <= S0;
			    S0:
					   state <= S1;
				S1:
					if (frame_r)
						state                     <= S2;
					else
						state                     <= S1;
						
			    S2: begin
			      state                           <= S3;
			      index_stop_cpt            <= index_bitwise_i-1;   
			    end 
			    
				S3:
				    begin
					   if (index_stop_cpt == 0)
					   begin
						  state                   <= S4;
						  index_stop_cpt          <= stop_bitwise_i-1;
					   end
					   else
					   begin
						  state                   <= S3;
						  index_stop_cpt           <= index_stop_cpt - 1;
				        end
				    end
				
				S4:
				    begin
					   if (index_stop_cpt == 0)
					   begin
						  state                   <= S5;
						  tdc_tdata            <= index_stop;
					   end
					   else
					   begin
						  state                   <= S4;
						  index_stop_cpt          <= index_stop_cpt - 1;
				        end
				    end
				
				S5:
					begin
						counter_stretch <= counter_stretch + 1;
						if (counter_stretch == 4) begin
					    //if (m_axis_tready)
					    	state                   <= S0;
					    	counter_stretch <= 0;
				    	end
			    	end
			endcase
        end
    end



//Change to domain lclk_i to clk200_i
(* ASYNC_REG = "TRUE" *) reg [2:0] tvalid_r;
reg tvalid200;
reg [31:0] tdata200;
reg [6:0] rd_en_4_r;
initial begin
	tvalid_r <= 0;
	tdata200 <= 32'd0;
	rd_en_4_r <= 7'd0;
end

always @(posedge clk200_i) begin
	if (rd_en_4 == 1) begin
		tvalid_r <= {tvalid_r[2:0],tdc_tvalid};	
		if (tvalid_r[2] == 0 && tvalid_r[1] == 1) begin
			// if (shift_tdc_time_r[15] == 0) //bit[15] == 1: backward | == 0 : forward
			// 	tdata200 <= tdc_tdata + shift_tdc_time_r[13:0];
			// else tdata200 <= tdc_tdata - shift_tdc_time_r[13:0];
			tdata200 <= tdc_tdata + shift_tdc_time_r[13:0]; //tdc_tdata[13:0] max is 0x2710, shift max is 0x39d, total not over 14 bits
			tvalid200 <= 1;
		end	else begin
			tdata200 <= tdata200;
			tvalid200 <= 0;
		end
	end
end


reg [47:0] gc; 
reg [47:0] gc_time_valid;
reg [1:0] click_result;
wire [47:0] gc_click;
// reg [2:0] counter_valid;


wire [31:0] gate_pos0,gate_pos1,gate_pos2,gate_pos3;
assign gate_pos0 = gate0_r[23:0];
assign gate_pos1 = gate_pos0 + gate0_r[31:24];
assign gate_pos2 = gate1_r[23:0];
assign gate_pos3 = gate_pos2 + gate1_r[31:24];
wire [15:0] tdata200_mod; 
wire [15:0] tdata200_mod_dq;
assign tdata200_mod = tdata200[13:0]%625;
assign tdata200_mod_dq = tdata200[13:0]%1250;
//convert to gc unit
wire [2:0] index_shift;
assign index_shift = tdata200[16:14] + 1; 
wire [5:0] index_shift_gc;
assign index_shift_gc = index_shift<<3; //multiply by 8, 5MHz = 8[gcs]
reg [3:0] time_ref_gc;
always @(*) begin
	if (tdata200[13:0] < 1250)
		time_ref_gc = 4'd1;
	else if (tdata200[13:0] < 2500)
		time_ref_gc = 4'd2;
	else if (tdata200[13:0] < 3750)
		time_ref_gc = 4'd3;
	else if (tdata200[13:0] < 5000)
		time_ref_gc = 4'd4;
	else if (tdata200[13:0] < 6250)
		time_ref_gc = 4'd5;
	else if (tdata200[13:0] < 7500)
		time_ref_gc = 4'd6;
	else if (tdata200[13:0] < 8750)
		time_ref_gc = 4'd7;
	else if (tdata200[13:0] < 10000)
		time_ref_gc = 4'd8;
	else 
		time_ref_gc = 4'd9;
end
wire [47:0] gc_div64;
assign gc_div64 = ((gc-12)>>6)<<6; //12 gcs is delay time from click to tvalid200
// reg [47:0] gc_time_valid;
// assign gc_time_valid = gc_div64 + index_shift_gc + time_ref_gc;
//State machine

reg [2:0] state_gc;
parameter IDLE = 0, WAIT_START = 1, DETECT_PPS = 2, START = 3;

(* ASYNC_REG = "TRUE" *) reg [2:0] start_gc_r;
reg start_gc_o;
reg [2:0] pps_r;
reg [3:0] tvalid200_r;
reg fifo_calib_rst;
//Axil command
(* ASYNC_REG = "TRUE" *) reg [2:0] command_enable_r;
// reg fifo_gc_rst;
initial begin
	start_gc_r <= 0;
	pps_r <= 0;
	command_enable_r <= 0;
	tvalid200_r <= 0;
end


//Axil registers
reg [31:0] total_count_o;
reg [31:0] total_count;
reg total_count_valid;
reg [31:0] click0_count_o;
reg [31:0] click0_count;
reg [31:0] click1_count_o;
reg [31:0] click1_count;

reg [31:0] counter_mon_en;
//Define the speed of monitoring
wire count_en;
assign count_en = (counter_mon_en > 0 && counter_mon_en <= 20000000)?1:0;

//Valid signal indicates the count value is valid, stretched to 2-3 cycle of axil_clk (15MHz)
// wire data_count_valid_o;
// assign data_count_valid_o = (counter_mon_en >= 1 && counter_mon_en <= 59) ? 1:0;
// Should not have combinational logic before CDC sync, put the source reg to source clock domain
reg data_count_valid_o;

wire tvalid200_en;
wire tvalid200_g0_en;
wire tvalid200_g1_en;
// assign tvalid200_en = (counter_valid == 1)?1:0; //detection one tvalid
assign tvalid200_en = (tvalid200_r[3] == 0 && tvalid200_r[2] == 1)?1:0; //detection one tvalid
assign tvalid200_g0_en = ((tvalid200_r[3] == 0 && tvalid200_r[2] == 1) && (tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1))?1:0;
assign tvalid200_g1_en = ((tvalid200_r[3] == 0 && tvalid200_r[2] == 1) && (tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3))?1:0;

always @(posedge clk200_i, posedge gc_rst) begin
	if (gc_rst) begin
		start_gc_r <= 0;
		start_gc_o <= 0;
		pps_r <=0;
		rd_en_4_r <= 0;
		tvalid200_r <= 0;
		gc <= 0;
		gc_time_valid <= 0;
		click_result <= 0;
		// counter_valid <= 0;


		m_axis_tvalid <= 0;
		m_axis_tdata <= 0;
		fifo_calib_rst <= 0;

		// m_axis_tdata_gc <= 0;
		// m_axis_tvalid_gc <= 0;
		// fifo_gc_rst <= 0;
		data_count_valid_o <= 0;
		counter_mon_en <= 0;
		total_count_o <= 0;
		total_count <= 0;
		total_count_valid <= 0;

		click0_count_o <= 0;
		click0_count <= 0;
		click1_count_o <= 0;
		click1_count <= 0;

		state_gc <= IDLE;
	end else begin
		case(state_gc)
			IDLE: begin  //Whenever have gc_rst, should come back to IDLE
				start_gc_r <= 0;
				start_gc_o <= 0;
				pps_r <=0;
				rd_en_4_r <= 0;
				tvalid200_r <= 0;
				gc <= 0;
				gc_time_valid <= 0;
				// counter_valid <= 0;

				counter_mon_en <= 0;
				total_count_o <= 0;
				total_count <= 0;
				total_count_valid <= 0;

				data_count_valid_o <= 0;
				click0_count_o <= 0;
				click0_count <= 0;
				click1_count_o <= 0;
				click1_count <= 0;

				click_result <= 0;
				m_axis_tvalid <= 0;
				m_axis_tdata <= 0;
				// m_axis_tvalid_gc <= 0;
				// m_axis_tdata_gc <= 0;
				state_gc <= WAIT_START;
			end
			WAIT_START: begin //Wait for the Start_gc commamd, put it to clk200 domain
				start_gc_r <= {start_gc_r[1:0],start_gc_i};
				// if (start_gc_r[2] == 0 && start_gc_r[1] == 1) begin
				// 	start_gc_o <= 1'b1;
				// 	state_gc <= DETECT_PPS;
				// end
				if (start_gc_r[2] == 1 && !pps_i) begin
					start_gc_o <= 1'b1;
					state_gc <= DETECT_PPS;
				end else state_gc <= WAIT_START;
			end
			DETECT_PPS: begin //Wait for the next PPS edge, detect this edge 
				pps_r <= pps_i;
				if (!pps_r && pps_i) begin
					state_gc <= START;
				end else state_gc <= DETECT_PPS;
			end
			START: begin //Start counting from the first PPS edge after receiving start_gc command
				tvalid200_r <= {tvalid200_r[2:0], tvalid200};
				rd_en_4_r <= {rd_en_4_r[5:0], rd_en_4};
				if (rd_en_4_r[5]) begin
					gc <= gc + 1;
				end else begin
					gc <= gc;
				end
				counter_mon_en <= counter_mon_en + 1; //Define the time for monitoring
				if (counter_mon_en > 19999999) begin //19999999 for 0.1s
					counter_mon_en <= 0;
				end
				if ((counter_mon_en >= 1) && (counter_mon_en <= 59)) begin
					data_count_valid_o <= 1;
				end else begin
					data_count_valid_o <= 0;
				end
				if (count_en && tvalid200_en) begin
					total_count <= total_count + 1;
					total_count_o <= total_count_o;
				end else if (count_en && ~tvalid200_en) begin
					total_count <= total_count;
					total_count_o <= total_count_o;
				end else begin
					total_count <= 0;
					total_count_o <= total_count;
					// total_count_valid <= 1;
				end
				if (count_en && tvalid200_g0_en) begin
					click0_count <= click0_count + 1;
					click0_count_o <= click0_count_o;
				end else if (count_en && ~tvalid200_g0_en) begin
					click0_count <= click0_count;
					click0_count_o <= click0_count_o;
				end else begin
					click0_count <= 0;
					click0_count_o <= click0_count;
				end
				if (count_en && tvalid200_g1_en) begin
					click1_count <= click1_count + 1;
					click1_count_o <= click1_count_o;
				end else if (count_en && ~tvalid200_g1_en) begin
					click1_count <= click1_count;
					click1_count_o <= click1_count_o;
				end else begin
					click1_count <= 0;
					click1_count_o <= click1_count;
				end
				if (tvalid200_r[2] == 0 && tvalid200_r[1] == 1) begin
					gc_time_valid <= gc_div64 + index_shift_gc + time_ref_gc;
				end else gc_time_valid <= gc_time_valid;
				if (tvalid200_r[3] == 0 && tvalid200_r[2] == 1) begin
					// gc_time_valid <= gc_div64 + index_shift_gc + time_ref_gc;
					// if (gc_time_valid > gc) begin
					// 	gc_time_valid <= gc_time_valid - 64;
					// end else gc_time_valid <= gc_time_valid;
					if (command_r == 3'b001) begin	//no gate
						fifo_calib_rst <= 0;
						click_result <= 2'b11;
						command_enable_r <= {command_enable_r[1:0],command_enable};
						if (command_enable_r[2]) begin
							fifo_calib_rst <= 1;
							// gc_time_valid <= gc_div64 + index_shift_gc + time_ref_gc;
							// m_axis_tdata <= {click_result,gc,tdata200};
							m_axis_tdata <= {click_result,gc_time_valid,tdata200};
							m_axis_tvalid <= 1'b1;
						end else begin
							m_axis_tdata <= m_axis_tdata;
							m_axis_tvalid <= 1'b0;
							fifo_calib_rst <= 0;
						end
					end else if (command_r == 3'b010) begin //with gate
						fifo_calib_rst <= 0;
						command_enable_r <= {command_enable_r[1:0],command_enable};
						if (command_enable_r[2]) begin
							fifo_calib_rst <= 1;
							if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625))begin
								m_axis_tdata <= {2'b00,gc_time_valid,tdata200}; //2'b00: click_result|q_pos
								m_axis_tvalid <= 1'b1;
							end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (tdata200_mod_dq >=625 && tdata200_mod_dq < 1250))begin
								m_axis_tdata <= {2'b01,gc_time_valid,tdata200}; 
								m_axis_tvalid <= 1'b1;
							end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq > 0 && tdata200_mod_dq < 625)) begin 
								m_axis_tdata <= {2'b10,gc_time_valid,tdata200};
								m_axis_tvalid <= 1'b1;
							end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (tdata200_mod_dq >=625 && tdata200_mod_dq < 1250)) begin 
								m_axis_tdata <= {2'b11,gc_time_valid,tdata200};
								m_axis_tvalid <= 1'b1;
							end else begin
								m_axis_tdata <= m_axis_tdata;
								m_axis_tvalid <= 1'b0;
							end
						end else begin
							m_axis_tdata <= m_axis_tdata;
							m_axis_tvalid <= 1'b0;
							fifo_calib_rst <= 0;
						end
					end
				end else begin
					// gc_time_valid <= gc_time_valid;
					click_result <= click_result;
					m_axis_tvalid <= 1'b0;
					m_axis_tdata <= m_axis_tdata;
					m_axis_tvalid_gc <= 1'b0;
					m_axis_tdata_gc <= m_axis_tdata_gc;
				end
				// if (tvalid200) begin
				// 	counter_valid <= counter_valid + 1;
				// 	if (counter_valid == 1) begin
				// 		gc_time_valid <= gc>>6 + index_shift_gc + time_ref_gc;
				// 		if (command_r == 3'b001) begin	//no gate
				// 			fifo_calib_rst <= 0;
				// 			click_result <= 2'b11;
				// 			command_enable_r <= {command_enable_r[1:0],command_enable};
				// 			if (command_enable_r[2]) begin
				// 				fifo_calib_rst <= 1;
				// 				// m_axis_tdata <= {click_result,gc,tdata200};
				// 				m_axis_tdata <= {click_result,gc_time_valid,tdata200};
				// 				m_axis_tvalid <= 1'b1;
				// 			end else begin
				// 				m_axis_tdata <= m_axis_tdata;
				// 				m_axis_tvalid <= 1'b0;
				// 				fifo_calib_rst <= 0;
				// 			end
				// 		end else if (command_r == 3'b010) begin //with gate
				// 			fifo_calib_rst <= 0;
				// 			command_enable_r <= {command_enable_r[1:0],command_enable};
				// 			if (command_enable_r[2]) begin
				// 				fifo_calib_rst <= 1;
				// 				if (tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) begin
				// 					//click_result <= 2'b00;
				// 					// m_axis_tdata <= {2'b00,gc,tdata200};
				// 					m_axis_tdata <= {2'b00,gc_time_valid,tdata200};
				// 					m_axis_tvalid <= 1'b1;
				// 				end else if (tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) begin 
				// 					//click_result <= 2'b01;
				// 					// m_axis_tdata <= {2'b01,gc,tdata200};
				// 					m_axis_tdata <= {2'b01,gc_time_valid,tdata200};
				// 					m_axis_tvalid <= 1'b1;
				// 				end else begin
				// 					//click_result <= 2'b11;
				// 					m_axis_tdata <= m_axis_tdata;
				// 					m_axis_tvalid <= 1'b0;
				// 				end
				// 			end else begin
				// 				m_axis_tdata <= m_axis_tdata;
				// 				m_axis_tvalid <= 1'b0;
				// 				fifo_calib_rst <= 0;
				// 			end
				// 		end
				// 	end else begin
				// 		gc_time_valid <= gc_time_valid;
				// 		click_result <= click_result;
				// 		m_axis_tvalid <= 1'b0;
				// 		m_axis_tdata <= m_axis_tdata;
				// 		m_axis_tvalid_gc <= 1'b0;
				// 		m_axis_tdata_gc <= m_axis_tdata_gc;
				// 	end
				// end else begin
				// 	counter_valid <= 0;
				// 	gc_time_valid <= gc_time_valid;
				// 	click_result <= click_result;
				// 	m_axis_tvalid <= 1'b0;
				// 	m_axis_tdata <= m_axis_tdata;			
				// 	m_axis_tvalid_gc <= 1'b0;
				// 	m_axis_tdata_gc <= m_axis_tdata_gc;
				// end				
			end
		endcase
	end
end

//CDC
//Stretch count_en


// reg [2:0] count_en_r;
// reg [31:0] slv_reg_total,slv_reg_0,slv_reg_1;
// initial begin
// 	count_en_r <= 0;
// end
// always @(posedge clk15) begin
// 	if (!arstn) begin
// 		count_en_r <= 0;
// 		slv_reg_total <= 0;
// 		slv_reg_0 <= 0;
// 		slv_reg_1 <= 0;
// 	end else begin
// 		count_en_r <= {count_en_r[1:0],count_valid};
// 		if (count_en_r[2] == 0 && count_en_r[1] == 1) begin
// 			slv_reg_total <= total_count_o;
// 			slv_reg_0 <= click0_count_o;
// 			slv_reg_1 <= click1_count_o;
// 		end else begin
// 			slv_reg_total <= slv_reg_total;
// 			slv_reg_0 <= slv_reg_0;
// 			slv_reg_1 <= slv_reg_1;
// 		end
// 	end
// end

    // // Change cock field
    // reg [2:0]           enable_r;
	// always @ (posedge m_axis_tclk or negedge m_axis_trstn) begin
	// 	if (!m_axis_trstn)
    //         enable_r              <= 0;
		    
	// 	else
	// 	    enable_r              <= {enable_r[1:0],enable};
	// end
    
    // // Output depends only on the m_axis_state
    // // Handle master axi stream output
	// always @ (m_axis_state) begin
    //     m_axis_tready_r                     <= 1'b0;
    //     m_axis_tvalid                       <= 1'b0;
    //     m_axis_tlast                        <= 1'b0;
	// 	case (m_axis_state)
		      
	// 	    S2:begin
		      
	// 	      m_axis_tvalid                 <= 1'b1;
	// 	      m_axis_tready_r               <= 1'b1;
	// 	      end
		      
	// 	    S3: begin
	// 	      m_axis_tlast                  <= 1'b1;
	// 	      m_axis_tvalid                 <= 1'b1;
	// 	      m_axis_tready_r               <= 1'b1;
	// 	      end
	// 	    S4: begin
	// 	      m_axis_tlast                  <= 1'b1;
	// 	      m_axis_tvalid                 <= 1'b1;
	// 	      m_axis_tready_r               <= 1'b1;
	// 	      end
	// 	    default:;              				
	//    endcase
	//  end
	  
	// // Handle master axi stream output
	// always @ (posedge m_axis_tclk or negedge m_axis_trstn) begin
		
	// 	if (!m_axis_trstn)
	// 	begin
    //         m_axis_state            <= 0;
    //         AS6501_BURST_SIZE_r     <= 0;
		    
	// 	end else begin    
			
			
	// 		 case (m_axis_state)
			
	// 			S0: 
    //                 if (enable_r[2]) begin
    //                     AS6501_BURST_SIZE_r    <=  AS6501_BURST_SIZE_i-1;
	// 				    m_axis_state <= S1;
	// 				end
					   		
	// 			S1:
	// 			    if (!enable_r[2])
	// 			        m_axis_state                         <= S0;
	// 			    else
	// 				   if (rd_data_count > AS6501_BURST_SIZE_r)
	// 				       if(AS6501_BURST_SIZE_i == 1)
	// 				           if (rd_data_count > 1)
    //                                m_axis_state               <= S5;
	// 			                else
	// 				               m_axis_state		          <= S1;
	// 			           else 
	// 					      m_axis_state               <= S2;
	// 				   else
	// 				       m_axis_state		              <= S1;
			    	
	// 			S2: begin
	// 			    if (m_axis_tready)
	// 			        if (AS6501_BURST_SIZE_r == 1)
	// 			            m_axis_state                        <= S3;
	// 			        else
	// 			            begin
	// 			                AS6501_BURST_SIZE_r             <= AS6501_BURST_SIZE_r-1;
	// 			                m_axis_state                    <= S2;
	// 			            end 
	// 			        end
				    
	// 			S3:
	// 			    if (m_axis_tready)
	// 			        m_axis_state                         <= S0;
				        
	// 			S4:
	// 			    if (m_axis_tready)
	// 			        m_axis_state                         <= S0;
				        
	// 			S5:
	// 			    m_axis_state                             <= S4;
				 
	// 			 default:;    
	// 		 endcase
    //     end
    // end
endmodule