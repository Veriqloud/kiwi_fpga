`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2023 12:20:47 PM
// Design Name: 
// Module Name: jesd_transport
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


module sample_dac1
    (
        
        // Ports of AXI-s slave(RNG stream)
        input wire                                    s_axis_clk,
        input wire                                    s_axis_tresetn,
        input wire [127 : 0]                          s_axis_tdata,
        input wire                                    s_axis_tvalid,
        output wire                                   s_axis_tready,
    
        // Ports of AXI-s master(alpha argument)
        input                                         tx_core_clk,
        input                                         tx_core_reset,
        output reg [127 : 0]                          tx_tdata,
        input wire                                    tx_tready,
        input pps_i,

        input wire               dac1_shift_en_o,
        input wire               fastdac_sequence_wen_int,
        input wire [9:0]         fastdac_sequence_addr_int,
        input wire [31:0]        fastdac_sequence_din_int,
        input wire               fastdac_rng_wen_int,
        input wire [11:0]         fastdac_rng_addr_int,
        input wire [31:0]        fastdac_rng_din_int,
        input wire [3:0]         shift1_i,
        input wire [31:0]        fastdac_amp_dac1_i,
        input wire [31:0]        fastdac_amp_dac2_i,
        input wire [7:0]         fastdac_dpram_max_addr_seq_dac0_int,
        input wire [7:0]         fastdac_dpram_max_addr_seq_dac1_int,
        input wire [14:0]         fastdac_dpram_max_addr_rng_dac1_int,
        input wire               fastdac_rng_mode_i,
        input wire               fastdac_dac1_mode_i,
        input wire               fastdac_dac0_mode_i,
        input wire               fb_mode_i,
        input wire [14:0]        up_offset_i,
        input wire               insert_zero,

        //Inputs from Tdc fr feedback
        input  tvalid200,
        input [15:0] tdata200_mod,
        input [31:0] gate_pos0,
        input [31:0] gate_pos1,
        input [31:0] gate_pos2,
        input [31:0] gate_pos3

    );
    
    // Instantiation of Axi Bus Interface s_axil
    // Includes registers and DPRAM
    // wire               dac1_shift_en_o;
    // wire               fastdac_sequence_wen_int;
    // wire [9:0]         fastdac_sequence_addr_int; 
    // wire [31:0]        fastdac_sequence_din_int;
    // wire               fastdac_rng_wen_int;
    // wire [11:0]         fastdac_rng_addr_int; 
    // wire [31:0]        fastdac_rng_din_int;


    // wire [3:0]         shift1_i;
    // wire [31:0]        fastdac_amp_dac1_i;
    // wire [31:0]        fastdac_amp_dac2_i;
    // wire [7:0]         fastdac_dpram_max_addr_seq_dac0_int;
    // wire [7:0]         fastdac_dpram_max_addr_seq_dac1_int;
    // wire [14:0]         fastdac_dpram_max_addr_rng_dac1_int;
    // wire               fastdac_rng_mode_i;
    // wire               fastdac_dac1_mode_i;
    
    // fastdac_axil_mngt # ( 
    //     .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
    //     .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
    // ) fastdac_axil_mngt_inst (
    //     .fastdac_en_jesd_o(fastdac_en_jesd_int),
    //     .dac1_shift_en_o(dac1_shift_en_o),
    //     .fastdac_dpram_max_addr_seq_dac0_o(fastdac_dpram_max_addr_seq_dac0_int),
    //     .fastdac_dpram_max_addr_seq_dac1_o(fastdac_dpram_max_addr_seq_dac1_int),
    //     .fastdac_dpram_max_addr_rng_dac1_o(fastdac_dpram_max_addr_rng_dac1_int),
    //     .fastdac_rng_mode_o(fastdac_rng_mode_i),
    //     .fastdac_dac1_mode_o(fastdac_dac1_mode_i),
    //     .fastdac_amp_dac1_shift_o(shift1_i),
    //     .fastdac_amp_dac1_o(fastdac_amp_dac1_i),
    //     .fastdac_amp_dac2_o(fastdac_amp_dac2_i),
    //     .fastdac_sequence_wen_o(fastdac_sequence_wen_int),
    //     .fastdac_sequence_addr_o(fastdac_sequence_addr_int),
    //     .fastdac_sequence_din_o(fastdac_sequence_din_int),
    //     .fastdac_rng_wen_o(fastdac_rng_wen_int),
    //     .fastdac_rng_addr_o(fastdac_rng_addr_int),
    //     .fastdac_rng_din_o(fastdac_rng_din_int),
    //     .S_AXI_ACLK(s_axil_aclk),
    //     .S_AXI_ARESETN(s_axil_aresetn),
    //     .S_AXI_AWADDR(s_axil_awaddr),
    //     .S_AXI_AWPROT(s_axil_awprot),
    //     .S_AXI_AWVALID(s_axil_awvalid),
    //     .S_AXI_AWREADY(s_axil_awready),
    //     .S_AXI_WDATA(s_axil_wdata),
    //     .S_AXI_WSTRB(s_axil_wstrb),
    //     .S_AXI_WVALID(s_axil_wvalid),
    //     .S_AXI_WREADY(s_axil_wready),
    //     .S_AXI_BRESP(s_axil_bresp),
    //     .S_AXI_BVALID(s_axil_bvalid),
    //     .S_AXI_BREADY(s_axil_bready),
    //     .S_AXI_ARADDR(s_axil_araddr),
    //     .S_AXI_ARPROT(s_axil_arprot),
    //     .S_AXI_ARVALID(s_axil_arvalid),
    //     .S_AXI_ARREADY(s_axil_arready),
    //     .S_AXI_RDATA(s_axil_rdata),
    //     .S_AXI_RRESP(s_axil_rresp),
    //     .S_AXI_RVALID(s_axil_rvalid),
    //     .S_AXI_RREADY(s_axil_rready)
    // );


    //------ and shift_r need to be put to clk200 domaine---------------------------
    reg [31:0] fastdac_amp_dac1_r;
    reg [31:0] fastdac_amp_dac2_r;
    reg [2:0] shift_shift1_r;
    reg [3:0] shift1_r;
    reg rng_mode_r;
    reg dac1_mode_r;
    reg dac0_mode_r;
    reg fb_mode_r;
    reg [14:0] up_offset_r;
    initial begin
        fastdac_amp_dac1_r <= 0;
        fastdac_amp_dac2_r <= 0;
        shift_shift1_r <= 0;
        shift1_r <= 0;
        rng_mode_r <= 0;
        dac1_mode_r <= 0;
        dac0_mode_r <= 0;
        fb_mode_r <= 0;
        up_offset_r <= 0;
    end
    always @(posedge tx_core_clk) begin
            shift_shift1_r <= {shift_shift1_r[1:0],dac1_shift_en_o};
            if ((shift_shift1_r[2] == 0) && (shift_shift1_r[0] == 1)) begin
                shift1_r <= shift1_i;
                rng_mode_r <= fastdac_rng_mode_i;
                dac1_mode_r <= fastdac_dac1_mode_i;
                dac0_mode_r <= fastdac_dac0_mode_i;
                fastdac_amp_dac1_r <= fastdac_amp_dac1_i;
                fastdac_amp_dac2_r <= fastdac_amp_dac2_i;
                fb_mode_r <= fb_mode_i;
                up_offset_r <= up_offset_i;
            end
    end

    //RNG fifos. Get stream data from axis to fifo 128x16 and 16x4.
    //to get 4 bits of RNG at 40MHz ~ 20 samples 16 bits for dac1
    wire rd_en_16;
    wire [15:0] dout16;
    assign s_axis_tready = 1'b1;

    //Test fifo with deth smaller for resource optimize
    fifo_128x16 fifo_rng_128x16_inst (
      .rst(!s_axis_tresetn),                              // input wire rst
      .wr_clk(s_axis_clk),                        // input wire wr_clk
      .rd_clk(tx_core_clk),                        // input wire rd_clk
      .din(s_axis_tdata),                              // input wire [127 : 0] din
      .wr_en(s_axis_tvalid),                          // input wire wr_en
      .rd_en(rd_en_16),                          // input wire rd_en
      .dout(dout16),                            // output wire [15 : 0] dout
      .full(),                            // output wire full
      .almost_full(),              // output wire almost_full
      .empty(),                  // output wire empty
      .almost_empty(),    // output wire almost_empty
      .rd_data_count(),  // output wire [15: 0] rd_data_count
      .wr_data_count(),  // output wire [12 : 0] wr_data_count
      .wr_rst_busy(),              // output wire wr_rst_busy
      .rd_rst_busy()              // output wire rd_rst_busy
    );

    wire rd_en_4;
    wire [3:0] rng_dout4;
    assign dout4_test = rng_dout4;

    fifo_16x4 fifo_rng_16x4_inst (
      .rst(!s_axis_tresetn),                      // input wire rst
      // .rst(tx_core_reset),                      // input wire rst
      .wr_clk(tx_core_clk),                // input wire wr_clk
      .rd_clk(tx_core_clk),                // input wire rd_clk
      .din(dout16),                      // input wire [15 : 0] din
      .wr_en(rd_en_16),                  // input wire wr_en
      .rd_en(rd_en_4),                  // input wire rd_en
      .dout(rng_dout4),                    // output wire [3 : 0] dout
      .full(full),                            // output wire full
      .almost_full(almost_full),              // output wire almost_full
      .wr_ack(wr_ack),                // output wire wr_ack
      .empty(empty),                  // output wire empty
      .almost_empty(almost_empty),    // output wire almost_empty
      .valid(valid),                  // output wire valid
      .rd_data_count(rd_data_count),  // output wire [8 : 0] rd_data_count
      .wr_data_count(wr_data_count),  // output wire [6 : 0] wr_data_count
      .wr_rst_busy(),      // output wire wr_rst_busy
      .rd_rst_busy()      // output wire rd_rst_busy
    );

    //Port ram data_write from axil and data_read is 4 samples for DACs    
    reg [7:0] fastdac_dpram_seq_addr_dac0_r;
    wire [63:0] fastdac_dpram_seq_data_dac0_int;
    //reg fastdac_dpram_alpha_rden_dac_r;
    dpram_out_wider_in #(
    .RAM_INIT("sin_sequence_dac0.mem"),
    .WIDTHA(16),
    .SIZEA(1024),
    .ADDRWIDTHA(10),
    .WIDTHB(64),
    .SIZEB(256),
    .ADDRWIDTHB(8)) 
    dpram_seq_64x128_dac0_inst(
    .clkA(s_axil_aclk), 
    .clkB(tx_core_clk), 
    .enaA(fastdac_sequence_wen_int), 
    .weA(fastdac_sequence_wen_int), 
//    .enaB(fastdac_dpram_alpha_rden_dac_r|tx_tready), 
    .enaB(tx_tready), 
    .addrA(fastdac_sequence_addr_int), 
    .addrB(fastdac_dpram_seq_addr_dac0_r), 
    .diA(fastdac_sequence_din_int[15:0]),
    .doB(fastdac_dpram_seq_data_dac0_int));

    
    reg [7:0] fastdac_dpram_seq_addr_dac1_r;
    wire [63:0] fastdac_dpram_seq_data_dac1_int_calib;
    dpram_out_wider_in #(
    .RAM_INIT("sin_sequence_dac1.mem"),
    .WIDTHA(16),
    .SIZEA(1024),
    .ADDRWIDTHA(10),
    .WIDTHB(64),
    .SIZEB(256),
    .ADDRWIDTHB(8)) 
    dpram_seq_64x128_dac1_inst(
    .clkA(s_axil_aclk), 
    .clkB(tx_core_clk), 
    .enaA(fastdac_sequence_wen_int), 
    .weA(fastdac_sequence_wen_int), 
//    .enaB(fastdac_dpram_alpha_rden_dac_r|tx_tready), 
    .enaB(tx_tready), 
    .addrA(fastdac_sequence_addr_int), 
    .addrB(fastdac_dpram_seq_addr_dac1_r), 
    .diA(fastdac_sequence_din_int[31:16]),
    .doB(fastdac_dpram_seq_data_dac1_int_calib));


    reg [14:0] sequence_rng_addr_r;
    wire [3:0] dpram_rng_dout;
    dpram_in_wider_out #(
        .RAM_INIT("rng_sequence_dac1.mem"),
        .WIDTHB(4),
        .SIZEB(32768),
        .ADDRWIDTHB(15),
        .WIDTHA(32),
        .SIZEA(4096),
        .ADDRWIDTHA(12))
    dpram_seq_rng_16x4_inst(
        .clkA(s_axil_aclk), 
        .clkB(tx_core_clk), 
        .enaA(fastdac_rng_wen_int), 
        .weA(fastdac_rng_wen_int), 
        .enaB(tx_tready), 
        .addrA(fastdac_rng_addr_int), 
        .addrB(sequence_rng_addr_r), 
        .diA(fastdac_rng_din_int[31:0]), 
        .doB(dpram_rng_dout)    
        );
    // Control rd_en and wr_en of rng fifos
    reg [5:0] counter10; //counter for pulse 10MHz
    reg [3:0] counter40; //counter for pulse 40MHz
    wire rd_en_4;
    wire rd_en_16; 

    //State machine to readout the rng_test from dpram
    reg [2:0] state_rng;
    localparam SR0 = 0, SR1 = 1, SR2 = 2, SR3 = 3, SR4 = 4;
    always @(posedge tx_core_clk, posedge tx_core_reset) begin
        if(tx_core_reset) begin
            sequence_rng_addr_r <= 0;
            state_rng <= SR0;
        end else begin
            if (tx_tready) begin
                case (state_rng)
                SR0: begin
                    sequence_rng_addr_r <= 0;
                    if (rd_en_4 == 1) begin
                        state_rng <= SR1;
                    end
                end
                SR1: begin
                    if (rd_en_4 == 1) begin
                        if (sequence_rng_addr_r == (fastdac_dpram_max_addr_rng_dac1_int-1)) begin //Max_addr=40
                            sequence_rng_addr_r <= 0;
                        end else 
                            sequence_rng_addr_r <= sequence_rng_addr_r+1;                    
                        state_rng <= SR1;
                    end
                end
                default: ;
                endcase
            end else begin
                sequence_rng_addr_r <= 0;
                state_rng <= SR0;
            end
        end
    end  
    
    //Choose rng_mode
    //Mode 1: take real rng from usb device
    //Mode 0: take period rng from dpram
    wire [3:0] rng_value;
    assign rng_value = rng_mode_r?rng_dout4:dpram_rng_dout;




    //Mapping amplitude to rng_value
    reg [15:0] amp1;
    reg [15:0] minus_amp1;
    reg [15:0] amp2;
    reg [15:0] minus_amp2;

    reg [15:0] amp1_old;
    reg [15:0] minus_amp1_old;
    reg [15:0] amp2_old;
    reg [15:0] minus_amp2_old;

    reg [15:0] amp0_r;
    reg [15:0] minus_amp0_r;
    reg [15:0] amp1_r;
    reg [15:0] minus_amp1_r;
    reg [15:0] amp2_r;
    reg [15:0] minus_amp2_r;
    reg [15:0] amp3_r;
    reg [15:0] minus_amp3_r;
    reg [15:0] amp_zero_r;
    reg [15:0] minus_amp_zero_r;

    wire [63:0] sam0,sam1,sam2,sam3,sam4;
    wire [63:0] sam0_0,sam1_0,sam2_0,sam3_0,sam4_0;
    wire [63:0] sam0_1,sam1_1,sam2_1,sam3_1,sam4_1;
    wire [63:0] sam0_2,sam1_2,sam2_2,sam3_2,sam4_2;
    wire [63:0] sam0_3,sam1_3,sam2_3,sam3_3,sam4_3;
    wire [63:0] sam0_4,sam1_4,sam2_4,sam3_4,sam4_4;
    wire [63:0] sam0_5,sam1_5,sam2_5,sam3_5,sam4_5;
    wire [63:0] sam0_6,sam1_6,sam2_6,sam3_6,sam4_6;
    wire [63:0] sam0_7,sam1_7,sam2_7,sam3_7,sam4_7;
    wire [63:0] sam0_8,sam1_8,sam2_8,sam3_8,sam4_8;
    wire [63:0] sam0_9,sam1_9,sam2_9,sam3_9,sam4_9;
    wire [63:0] sam0_a,sam1_a,sam2_a,sam3_a,sam4_a;


//Feedback
reg [15:0] offset_val;
reg [3:0] counter_valid;
wire [15:0] down_offset_r;


assign down_offset_r = 17'h10000 - up_offset_r;
always @(posedge tx_core_clk) begin
    if (tx_core_reset) begin
        offset_val <= 0;
        counter_valid <= 0;
    end else begin
        if (tvalid200) begin
            counter_valid <= counter_valid + 1;
            if (counter_valid == 1) begin
                if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (offset_val >= down_offset_r)) begin
                    offset_val <= offset_val - 15'h1000;
                    if (offset_val == down_offset_r) begin
                        offset_val <= up_offset_r;
                    end
                end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (offset_val <= up_offset_r)) begin
                    offset_val <= offset_val - 15'h1000;
                    if (offset_val == 16'h01000) begin
                        offset_val <= 0;
                    end
                end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (offset_val <= up_offset_r)) begin
                    offset_val <= offset_val + 15'h1000;
                    if (offset_val == up_offset_r) begin
                        offset_val <= down_offset_r;
                    end
                end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (offset_val >= down_offset_r)) begin
                    offset_val <= offset_val + 15'h1000;
                    if (offset_val == 16'hf000) begin
                        offset_val <= 0;
                    end
                end      
            end else begin
                offset_val <= offset_val;
            end
        end else begin
            offset_val <= offset_val;
            counter_valid <= 0;
        end
    end
end

wire [15:0] offset;
assign offset = fb_mode_r ? offset_val:0;

//  Input 4 amplitude for PM signal 
    wire [15:0] ext_amp0;
    wire [15:0] ext_amp1;
    wire [15:0] ext_amp2;
    wire [15:0] ext_amp3;
    wire [15:0] zero_amp;

    assign ext_amp0 = fastdac_amp_dac1_r[15:0] + offset;
    assign ext_amp1 = fastdac_amp_dac1_r[31:16] + offset;
    assign ext_amp2 = fastdac_amp_dac2_r[15:0] + offset;
    assign ext_amp3 = fastdac_amp_dac2_r[31:16] + offset;
    assign zero_amp = offset;

    always @(ext_amp0,ext_amp1,ext_amp2,ext_amp3) begin
    // always @(*) begin
        amp0_r       = 16'h8000 + ext_amp0;
        minus_amp0_r = 16'h8000 - ext_amp0; //16'h4000
        amp1_r       = 16'h8000 + ext_amp1; //16'hffff
        minus_amp1_r = 16'h8000 - ext_amp1; //16'h0000         
        amp2_r       = 16'h8000 + ext_amp2;
        minus_amp2_r = 16'h8000 - ext_amp2; //16'h4000
        amp3_r       = 16'h8000 + ext_amp3; //16'hffff
        minus_amp3_r = 16'h8000 - ext_amp3; //16'h0000         
        amp_zero_r   = 16'h8000 + zero_amp;
        minus_amp_zero_r = 16'h8000 - zero_amp; 
    end


    reg [2:0] counter_3b;
    wire insert_zero;
    assign insert_zero = 1;
    wire pos;
    assign pos = 0;
    wire [3:0] zero_pos_r;
    assign zero_pos_r = 4'd14;
    reg [2:0] rd_en_4_shift;

    // always @(posedge tx_core_clk) begin
    //     if (tx_core_reset) begin
    //         counter_3b <= 3'd7;
    //         rd_en_4_shift <= 0;
    //     end else begin
    //         rd_en_4_shift <= {rd_en_4_shift[1:0],rd_en_4};
    //         if (rd_en_4_shift[0] == 1) begin
    //             counter_3b <= counter_3b + 1;
    //         end                    
    //     end
    // end

    always @(posedge tx_core_clk) begin
        if (tx_core_reset) begin
            amp1 <= 0;
            minus_amp1 <= 0;
            amp2 <= 0;
            minus_amp2 <= 0;
            amp1_old <= 0;
            minus_amp1_old <= 0;
            amp2_old <= 0;
            minus_amp2_old <= 0;
            rd_en_4_shift <= 0;
            counter_3b <= 3'd7;
        end else begin
            rd_en_4_shift <= {rd_en_4_shift[1:0],rd_en_4};
            if (rd_en_4_shift[0] == 1) begin
                counter_3b <= counter_3b + 1;
            end
            if (rd_en_4_shift[0] == 1 && insert_zero == 0) begin
                case (rng_value)
                    4'h0: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end            
                    4'h1: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                    4'h2: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                    4'h3: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                    4'h4: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                    4'h5: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                    4'h6: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                    4'h7: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                    4'h8: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                    4'h9: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                    4'ha: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                    4'hb: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                    4'hc: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                    4'hd: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                    4'he: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                    4'hf: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                endcase 
                amp1_old <= amp1;
                minus_amp1_old <= minus_amp1;
                amp2_old <= amp2;
                minus_amp2_old <= minus_amp2;                     
                
            end else if (rd_en_4_shift[0] == 1 && insert_zero == 1) begin
                // counter_3b <= counter_3b + 1;
                if (counter_3b == zero_pos_r[3:1] && zero_pos_r[0] == 1) begin
                    case(rng_value[3:2])
                        2'h0: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp_zero_r; minus_amp2 <= minus_amp_zero_r; end
                        2'h1: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp_zero_r; minus_amp2 <= minus_amp_zero_r; end
                        2'h2: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp_zero_r; minus_amp2 <= minus_amp_zero_r; end
                        2'h3: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp_zero_r; minus_amp2 <= minus_amp_zero_r; end

                endcase
                    amp1_old <= amp1;
                    minus_amp1_old <= minus_amp1;
                    amp2_old <= amp2;
                    minus_amp2_old <= minus_amp2;                                            
                end else if (counter_3b == zero_pos_r[3:1] && zero_pos_r[0] == 0) begin
                    case(rng_value[1:0])
                        2'h0: begin amp1 <= amp_zero_r; minus_amp1 <= minus_amp_zero_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                        2'h1: begin amp1 <= amp_zero_r; minus_amp1 <= minus_amp_zero_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                        2'h2: begin amp1 <= amp_zero_r; minus_amp1 <= minus_amp_zero_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                        2'h3: begin amp1 <= amp_zero_r; minus_amp1 <= minus_amp_zero_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end

                endcase
                    amp1_old <= amp1;
                    minus_amp1_old <= minus_amp1;
                    amp2_old <= amp2;
                    minus_amp2_old <= minus_amp2;                                            
                end else begin
                    case (rng_value)
                        4'h0: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end            
                        4'h1: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                        4'h2: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                        4'h3: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                        4'h4: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                        4'h5: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                        4'h6: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                        4'h7: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                        4'h8: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                        4'h9: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                        4'ha: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                        4'hb: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                        4'hc: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
                        4'hd: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
                        4'he: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
                        4'hf: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
                    endcase 
                    amp1_old <= amp1;
                    minus_amp1_old <= minus_amp1;
                    amp2_old <= amp2;
                    minus_amp2_old <= minus_amp2;                                         
                end
            end
            // if (rd_en_4_shift[0]) begin
            //     counter_3b <= counter_3b + 1;
            //     if (counter_3b >= 6 && counter_3b < 7 && insert_zero == 1) begin
            //         state_rng_fb <= ZERO;

            //         case(rng_value[3:2])
            //             2'h0: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= 16'h8000; minus_amp2 <= 16'h8000; end
            //             2'h1: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= 16'h8000; minus_amp2 <= 16'h8000; end
            //             2'h2: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= 16'h8000; minus_amp2 <= 16'h8000; end
            //             2'h3: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= 16'h8000; minus_amp2 <= 16'h8000; end
            //         endcase
            //         amp1_old <= amp1;
            //         minus_amp1_old <= minus_amp1;
            //         amp2_old <= amp2;
            //         minus_amp2_old <= minus_amp2;                        

            //     end else  begin
            //         state_rng_fb <= COM;
            //         case (rng_value)
            //             4'h0: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end            
            //             4'h1: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
            //             4'h2: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
            //             4'h3: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
            //             4'h4: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
            //             4'h5: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
            //             4'h6: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
            //             4'h7: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
            //             4'h8: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
            //             4'h9: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
            //             4'ha: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
            //             4'hb: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
            //             4'hc: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
            //             4'hd: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
            //             4'he: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
            //             4'hf: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
            //         endcase 
            //         amp1_old <= amp1;
            //         minus_amp1_old <= minus_amp1;
            //         amp2_old <= amp2;
            //         minus_amp2_old <= minus_amp2;                     
            //     end

        end
    end







    // if (fastdac_amp_dac1_i == 0) begin
        assign sam0_0 = {16'h8000,16'h8000,amp1,amp1};
        assign sam1_0 = {16'h8000,16'h8000,minus_amp1,minus_amp1};
        assign sam2_0 = {amp2,amp2,16'h8000,16'h8000};
        assign sam3_0 = {minus_amp2,minus_amp2,16'h8000,16'h8000};
        assign sam4_0 = {16'h8000,16'h8000,16'h8000,16'h8000};
    // end else if (fastdac_amp_dac1_i == 1) begin
        assign sam0_1 = {16'h8000,amp1,amp1,16'h8000};
        assign sam1_1 = {16'h8000,minus_amp1,minus_amp1,16'h8000};
        assign sam2_1 = {amp2,16'h8000,16'h8000,16'h8000};
        assign sam3_1 = {minus_amp2,16'h8000,16'h8000,amp2};
        assign sam4_1 = {16'h8000,16'h8000,16'h8000,minus_amp2};
    // end else if (fastdac_amp_dac1_i == 2) begin
        assign sam0_2 = {amp1,amp1,16'h8000,16'h8000};
        assign sam1_2 = {minus_amp1,minus_amp1,16'h8000,16'h8000};
        assign sam2_2 = {16'h8000,16'h8000,16'h8000,16'h8000};
        assign sam3_2 = {16'h8000,16'h8000,amp2,amp2};
        assign sam4_2 = {16'h8000,16'h8000,minus_amp2,minus_amp2};
    // end else if (fastdac_amp_dac1_i == 3) begin
        assign sam0_3 = {amp1,16'h8000,16'h8000,16'h8000};
        assign sam1_3 = {minus_amp1,16'h8000,16'h8000,amp1};
        assign sam2_3 = {16'h8000,16'h8000,16'h8000,minus_amp1};
        assign sam3_3 = {16'h8000,amp2,amp2,16'h8000};
        assign sam4_3 = {16'h8000,minus_amp2,minus_amp2,16'h8000};        
    // end else if (fastdac_amp_dac1_i == 4) begin
        assign sam0_4 = {16'h8000,16'h8000,16'h8000,16'h8000};
        assign sam1_4 = {16'h8000,16'h8000,amp1,amp1};
        assign sam2_4 = {16'h8000,16'h8000,minus_amp1,minus_amp1};
        assign sam3_4 = {amp2,amp2,16'h8000,16'h8000};
        assign sam4_4 = {minus_amp2,minus_amp2,16'h8000,16'h8000};
    // end else if (fastdac_amp_dac1_i == 5) begin
        assign sam0_5 = {16'h8000,16'h8000,16'h8000,minus_amp2_old};
        assign sam1_5 = {16'h8000,amp1,amp1,16'h8000};
        assign sam2_5 = {16'h8000,minus_amp1,minus_amp1,16'h8000};
        assign sam3_5 = {amp2,16'h8000,16'h8000,16'h8000};
        assign sam4_5 = {minus_amp2,16'h8000,16'h8000,amp2};
    // end else if (fastdac_amp_dac1_i == 6) begin
        assign sam0_6 = {16'h8000,16'h8000,minus_amp2_old,minus_amp2_old};
        assign sam1_6 = {amp1,amp1,16'h8000,16'h8000};
        assign sam2_6 = {minus_amp1,minus_amp1,16'h8000,16'h8000};
        assign sam3_6 = {16'h8000,16'h8000,16'h8000,16'h8000};
        assign sam4_6 = {16'h8000,16'h8000,amp2,amp2};
    // end else if (fastdac_amp_dac1_i == 7) begin
        assign sam0_7 = {16'h8000,minus_amp2_old,minus_amp2_old,16'h8000};
        assign sam1_7 = {amp1,16'h8000,16'h8000,16'h8000};
        assign sam2_7 = {minus_amp1,16'h8000,16'h8000,amp1};
        assign sam3_7 = {16'h8000,16'h8000,16'h8000,minus_amp1};
        assign sam4_7 = {16'h8000,amp2,amp2,16'h8000};
    // end else if (fastdac_amp_dac1_i == 8) begin
        assign sam0_8 = {minus_amp2_old,minus_amp2_old,16'h8000,16'h8000};
        assign sam1_8 = {16'h8000,16'h8000,16'h8000,16'h8000};
        assign sam2_8 = {16'h8000,16'h8000,amp1,amp1};
        assign sam3_8 = {16'h8000,16'h8000,minus_amp1,minus_amp1};
        assign sam4_8 = {amp2,amp2,16'h8000,16'h8000};
    // end else if (fastdac_amp_dac1_i == 9) begin
        assign sam0_9 = {minus_amp2_old,16'h8000,16'h8000,amp2_old};
        assign sam1_9 = {16'h8000,16'h8000,16'h8000,minus_amp2_old};
        assign sam2_9 = {16'h8000,amp1,amp1,16'h8000};
        assign sam3_9 = {16'h8000,minus_amp1,minus_amp1,16'h8000};
        assign sam4_9 = {amp2,16'h8000,16'h8000,16'h8000};
    // end else if (fastdac_amp_dac1_i == 10) begin
        assign sam0_a = {16'h8000,16'h8000,amp2_old,amp2_old};
        assign sam1_a = {16'h8000,16'h8000,minus_amp2_old,minus_amp2_old};
        assign sam2_a = {amp1,amp1,16'h8000,16'h8000};
        assign sam3_a = {minus_amp1,minus_amp1,16'h8000,16'h8000};
        assign sam4_a = {16'h8000,16'h8000,16'h8000,16'h8000};
                            


    assign sam0 = shift1_r[3]? (shift1_r[1]? sam0_a : (shift1_r[0]? sam0_9 : sam0_8)) 
    : (shift1_r[2] ? (shift1_r[1]? (shift1_r[0]? sam0_7 : sam0_6) : (shift1_r[0]? sam0_5 : sam0_4)) 
        : (shift1_r[1]? (shift1_r[0]? sam0_3 : sam0_2) : (shift1_r[0]? sam0_1 : sam0_0)));

    assign sam1 = shift1_r[3]? (shift1_r[1]? sam1_a : (shift1_r[0]? sam1_9 : sam1_8)) 
    : (shift1_r[2] ? (shift1_r[1]? (shift1_r[0]? sam1_7 : sam1_6) : (shift1_r[0]? sam1_5 : sam1_4)) 
        : (shift1_r[1]? (shift1_r[0]? sam1_3 : sam1_2) : (shift1_r[0]? sam1_1 : sam1_0)));

    assign sam2 = shift1_r[3]? (shift1_r[1]? sam2_a : (shift1_r[0]? sam2_9 : sam2_8)) 
    : (shift1_r[2] ? (shift1_r[1]? (shift1_r[0]? sam2_7 : sam2_6) : (shift1_r[0]? sam2_5 : sam2_4)) 
        : (shift1_r[1]? (shift1_r[0]? sam2_3 : sam2_2) : (shift1_r[0]? sam2_1 : sam2_0)));

    assign sam3 = shift1_r[3]? (shift1_r[1]? sam3_a : (shift1_r[0]? sam3_9 : sam3_8)) 
    : (shift1_r[2] ? (shift1_r[1]? (shift1_r[0]? sam3_7 : sam3_6) : (shift1_r[0]? sam3_5 : sam3_4)) 
        : (shift1_r[1]? (shift1_r[0]? sam3_3 : sam3_2) : (shift1_r[0]? sam3_1 : sam3_0)));

    assign sam4 = shift1_r[3]? (shift1_r[1]? sam4_a : (shift1_r[0]? sam4_9 : sam4_8)) 
    : (shift1_r[2] ? (shift1_r[1]? (shift1_r[0]? sam4_7 : sam4_6) : (shift1_r[0]? sam4_5 : sam4_4)) 
        : (shift1_r[1]? (shift1_r[0]? sam4_3 : sam4_2) : (shift1_r[0]? sam4_1 : sam4_0)));

    //Control dpram addr reading dac0 and samples of dac1
    //Control dpram addr reading dac0 and samples of dac1
    reg [63:0] fastdac_dpram_seq_data_dac1_int; 
    reg [63:0] fastdac_one_pulse_data_dac0_int;
    reg [3:0] counter_wait1;
    reg [3:0] counter_wait0;
    reg [3:0] counter_wait2;
    reg [31:0] counter_loop;
    // Declare states
    localparam S0 = 0, S1 = 1, S2 = 2, S3 =3, S4 = 4, S5 = 5, S6 = 6;
    localparam T0 = 0, T1 = 1, T2 = 2, T3 = 3, T4 = 4, T5 = 5;;
    localparam R0 = 0, R1 = 1, R2 = 2, R3 = 3, R4 = 4, R5 = 5, R6 = 6, R7 = 7;
    reg [2:0] addr_state_dac0;
    reg [2:0] single_addr_state_dac0;
    reg [2:0] seq_state_dac1;

    assign rd_en_16 = (counter10 == 0)?1:0;
    assign rd_en_4 = (counter40 == 0)?1:0;


    always@(posedge tx_core_clk, posedge tx_core_reset)
    begin   
        if (tx_core_reset)
        begin
            counter10 <= 1<<6 - 1;
            counter40 <= 1<<4 - 1;
            counter_wait1 <= 0;
            counter_wait0 <= 0;
            counter_wait2 <= 0;
            counter_loop <= 0;
            fastdac_dpram_seq_addr_dac0_r <= 0;
            fastdac_dpram_seq_addr_dac1_r <= 0;
            fastdac_dpram_seq_data_dac1_int <= 0;
            fastdac_one_pulse_data_dac0_int <= 0;      
            addr_state_dac0 <= S0;
            single_addr_state_dac0 <= T0;
            seq_state_dac1 <= R0;
      
        end else begin 
            if (tx_tready) begin
                counter10 <= counter10 + 1;
                counter40 <= counter40+ 1;
                if (counter10 >= 19) begin // work with 20 div, missing dataout with 5 div
                    counter10 <= 0;
                end 
                if (counter40 >= 4) begin
                    counter40 <= 0;
                end 
                //Handle address bus dpram dac0
                case (addr_state_dac0)
                    S0 : begin
                        fastdac_dpram_seq_addr_dac0_r <= 0;
                        fastdac_dpram_seq_addr_dac1_r <= 0;
                        counter_wait0 <= 0;
                        addr_state_dac0 <= S1;
                    end
                    S1:  begin
                        fastdac_dpram_seq_addr_dac0_r <= 0;
                        fastdac_dpram_seq_addr_dac1_r <= 0;
                        counter_wait0 <= counter_wait0 + 1;
                        if (counter_wait0 == 0) begin
                            addr_state_dac0 <= S2;
                        end
                    end
                    S2 : begin
                        fastdac_dpram_seq_addr_dac0_r <= 0;
                        fastdac_dpram_seq_addr_dac1_r <= 0;
                        addr_state_dac0 <= S3;
                    end
                    S3: begin
                        if (fastdac_dpram_seq_addr_dac0_r == (fastdac_dpram_max_addr_seq_dac0_int-1)) begin
                            fastdac_dpram_seq_addr_dac0_r <= 0;
                        end else 
                            fastdac_dpram_seq_addr_dac0_r <= fastdac_dpram_seq_addr_dac0_r+1;

                        if (fastdac_dpram_seq_addr_dac1_r == (fastdac_dpram_max_addr_seq_dac1_int-1)) begin
                            fastdac_dpram_seq_addr_dac1_r <= 0;
                        end else 
                            fastdac_dpram_seq_addr_dac1_r <= fastdac_dpram_seq_addr_dac1_r+1;
                        addr_state_dac0 <= S3;
                    end
                    default : ;
                endcase

                case (single_addr_state_dac0)
                    T0 : begin
                        fastdac_one_pulse_data_dac0_int <= 64'hffffffffffffffff;
                        counter_wait2 <= 0;
                        single_addr_state_dac0 <= T1;
                    end
                    T1 : begin
                        counter_wait2 <= counter_wait2 + 1;
                        if (counter_wait2 == 0) begin
                            single_addr_state_dac0 <= T2;
                        end
                    end
                    T2 : begin
                        fastdac_one_pulse_data_dac0_int <= 64'he000d000c000b000; //4 samples
                        single_addr_state_dac0 <= T3;
                    end
                    T3 : begin
                        fastdac_one_pulse_data_dac0_int <= 64'ha000900080003267; //4 samples
                        single_addr_state_dac0 <= T4;
                    end
                    T4 : begin
                        fastdac_one_pulse_data_dac0_int <= 64'h3267ffffffffffff;
                        single_addr_state_dac0 <= T5;
                    end
                    T5 : begin
                        counter_loop <= counter_loop + 1;
                        if (counter_loop <= 20 - 6) begin
                            fastdac_one_pulse_data_dac0_int <= 64'hffffffffffffffff;
                            single_addr_state_dac0 <= T5;
                            counter_wait2 <= 0;
                        end else begin
                            counter_loop <= 0;
                            single_addr_state_dac0 <= T1;
                        end
                    end
                    default : ;
                endcase

                case (seq_state_dac1)
                    R0 : begin
                        fastdac_dpram_seq_data_dac1_int <= 0;
                        counter_wait1 <= 0;
                        seq_state_dac1 <= R1;
                    end
                    R1 : begin
                        fastdac_dpram_seq_data_dac1_int <= 0;
                        counter_wait1 <= counter_wait1 + 1;
                        // if (counter_wait1 == 1) begin
                        if (rd_en_4_shift[0]) begin  
                            seq_state_dac1 <= R2;
                            counter_wait1 <= 0;
                        end 
                    end
                    R2:  begin
                        fastdac_dpram_seq_data_dac1_int <= sam0;
                        seq_state_dac1 <= R3;
                    end
                    R3 :  begin
                        fastdac_dpram_seq_data_dac1_int <= sam1;
                        seq_state_dac1 <= R4;
                    end
                    R4 :  begin
                        fastdac_dpram_seq_data_dac1_int <= sam2;
                        seq_state_dac1 <= R5;
                    end
                    R5 :  begin
                        fastdac_dpram_seq_data_dac1_int <= sam3;
                        seq_state_dac1 <= R6;
                    end
                    R6 :  begin
                        fastdac_dpram_seq_data_dac1_int <= sam4;
                        seq_state_dac1 <= R2;
                    end
                    default : ;
                endcase
        
            end else begin
                addr_state_dac0 <= S0;
                seq_state_dac1 <= R0;
                fastdac_dpram_seq_addr_dac0_r <= 0;
                fastdac_dpram_seq_addr_dac1_r <= 0;
                fastdac_dpram_seq_data_dac1_int <= 0;
                fastdac_one_pulse_data_dac0_int <= 0;
                counter10 <= 1<<6 -1;
                counter40 <= 1<<4 -1;
                counter_wait1 <= 0;
                counter_wait0 <= 0;
                counter_wait2 <= 0;
                counter_loop <= 0;
            end    
        end

    end
 
 

function [63:0] format_data_to_jesd204;
    input [63:0] dpram_seq;
    integer byte_index_dac,word_index_dac;

    for ( byte_index_dac = 0; byte_index_dac <= 4-1; byte_index_dac = byte_index_dac+1 ) begin
        for ( word_index_dac = 0; word_index_dac <= 2-1; word_index_dac = word_index_dac+1 ) begin
            format_data_to_jesd204[(byte_index_dac*8) + ((word_index_dac*32)) +: 8]  = dpram_seq[(byte_index_dac*16)  + ((1-word_index_dac)*8) +: 8];
        end
    end
endfunction

//Choose mode for dac1
//dac1_mode_r control if dac1 take fix sequence or sequence with random phase
//0: taking fix sequence, data input directly to dpram
//1: ramdom amplitude control by rng
//rng_mode_r control source of randomness
//0: fake rng, read rng from dpram
//1: true rng. read rng from USB 
wire [63:0] fastdac_seq_data_dac1_int;
wire [63:0] fastdac_seq_data_dac0_int;
assign fastdac_seq_data_dac1_int = dac1_mode_r ? fastdac_dpram_seq_data_dac1_int:fastdac_dpram_seq_data_dac1_int_calib;
assign fastdac_seq_data_dac0_int = dac0_mode_r ? fastdac_one_pulse_data_dac0_int:fastdac_dpram_seq_data_dac0_int;



reg [63:0] tx_tdata0;
reg [63:0] tx_tdata1;

always @(*) begin
    tx_tdata0 = format_data_to_jesd204 (fastdac_seq_data_dac0_int);
    tx_tdata1 = format_data_to_jesd204 (fastdac_seq_data_dac1_int);
    tx_tdata [127:0] <= {tx_tdata1,tx_tdata0};
end

endmodule    



