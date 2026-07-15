`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 11/15/2023 12:20:47 PM
// Design Name: Qline_turnkey
// Module Name: jesd_transport
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Manage transport layer of jesd204 protocol
// 
// Dependencies: 
//- fastdac_axil_mngt.v
//- dpram_*.v
//- fifo_*.v
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module jesd_transport #(
    // Parameters of Axi Slave Bus Interface s_axil
    parameter integer C_s_axil_DATA_WIDTH   = 32,
    parameter integer C_s_axil_ADDR_WIDTH   = 16
)(
    // Ports of Axi Slave Bus Interface s_axil
    input   wire                                    s_axil_aclk,
    input   wire                                    s_axil_aresetn,
    input   wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_awaddr,
    input   wire [2 : 0]                            s_axil_awprot,
    input   wire                                    s_axil_awvalid,
    output  wire                                    s_axil_awready,
    input   wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_wdata,
    input   wire [(C_s_axil_DATA_WIDTH/8)-1 : 0]    s_axil_wstrb,
    input   wire                                    s_axil_wvalid,
    output  wire                                    s_axil_wready,
    output  wire [1 : 0]                            s_axil_bresp,
    output  wire                                    s_axil_bvalid,
    input   wire                                    s_axil_bready,
    input   wire [C_s_axil_ADDR_WIDTH-1 : 0]        s_axil_araddr,
    input   wire [2 : 0]                            s_axil_arprot,
    input   wire                                    s_axil_arvalid,
    output  wire                                    s_axil_arready,
    output  wire [C_s_axil_DATA_WIDTH-1 : 0]        s_axil_rdata,
    output  wire [1 : 0]                            s_axil_rresp,
    output  wire                                    s_axil_rvalid,
    input   wire                                    s_axil_rready,
    
    // Ports of AXI-s slave(RNG stream)
    input   wire                                    s_axis_clk,
    input   wire                                    s_axis_tresetn,
    input   wire [127 : 0]                          s_axis_tdata,
    input   wire                                    s_axis_tvalid,
    output  wire                                    s_axis_tready,

    // Ports RNG test out
    output wire         tx_tready_sync,
    output wire [3:0]   dout4_test,
    output              rd_en_16,
    output              rd_en_16_de,
    output              rd_en_4,
    output [3:0]        dpram_rng_dout,
    output [3:0]        rng_value,
    output [14:0]       sequence_rng_addr_r,
    output [31:0]       fastdac_rng_din_int,
    output [11:0]       fastdac_rng_addr_int,
    output              rd_en_4_shift,
    output [3:0]        counter40,
    output [5:0]        counter10,
    output              amp2,
    output [2:0]        counter_3b,
    output reg [2:0]    addr_state_dac0,
    output reg [2:0]    seq_state_dac1,
    output reg [2:0]    state_rng,
    output              fastdac_seq_data_dac0_int,
    output              pps_trigger,
    output              pps_r,
    // output              tready_flag,
    output              almost_full_16,
    output              [9:0]rng_fifo_status,
    output              command_rng_status_r,
    // Ports of control (synchronization) & status
    input           tvalid200,
    input [15:0]    tdata200_mod,
    input [31:0]    gate_pos0,
    input [31:0]    gate_pos1,
    input [31:0]    gate_pos2,
    input [31:0]    gate_pos3,
    input [3:0]     q_gc_time_valid_mod16,
    input [3:0]     de_rng_flags,

    // Ports of AXI-s master(alpha argument)
    input                                         tx_core_clk,
    input                                         clk80,          // 80 MHz basis-processing clock (range decoder)
    input                                         tx_core_reset,
    input                                         rng_rst_clk200,
    input                                         rng_rst_clk80,
    input                                         rng_rst_clk250,
    output  reg [127 : 0]                         tx_tdata,
    input   wire                                  tx_tready,
    input                                         pps_i

    );
    
wire               fastdac_en_jesd_int;
wire               reg_en_o;
reg  [2:0]         fastdac_en_jesd_r;
wire               fastdac_sequence_wen_int;
wire [9:0]         fastdac_sequence_addr_int; 
wire [31:0]        fastdac_sequence_din_int;
wire               fastdac_rng_wen_int;
wire [11:0]        fastdac_rng_addr_int; 
wire [31:0]        fastdac_rng_din_int;
wire [3:0]         shift1_i;
wire [31:0]        fastdac_amp_dac1_i;
wire [31:0]        fastdac_amp_dac2_i;
wire [7:0]         fastdac_dpram_max_addr_seq_dac0_int;
wire [7:0]         fastdac_dpram_max_addr_seq_dac1_int;
wire [14:0]        fastdac_dpram_max_addr_rng_dac1_int;
wire               fastdac_rng_mode_i;
wire [15:0]        rdec_p0_o;     // range-decoder P0 (raw AXIL value, s_axil_aclk domain)
wire               fastdac_dac1_mode_i;
wire               fastdac_dac0_mode_i;
wire               fastdac_fb_mode_i;
wire [15:0]        fastdac_up_offset_i;
wire [31:0]        division_sp_i;
wire [3:0]         fastdac_zero_pos_i;
    
fastdac_axil_mngt # ( 
    .C_S_AXI_DATA_WIDTH(C_s_axil_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_s_axil_ADDR_WIDTH)
) fastdac_axil_mngt_inst (
    .fastdac_en_jesd_o(fastdac_en_jesd_int),
    .fastdac_reg_en_o(reg_en_o),
    .command_rng_fifo_status_o(command_rng_fifo_status_int),
    .rng_fifo_status_i(rng_fifo_status),
    .rng_fifo_status_valid_i(rng_fifo_status_valid),
    .fastdac_dpram_max_addr_seq_dac0_o(fastdac_dpram_max_addr_seq_dac0_int),
    .fastdac_dpram_max_addr_seq_dac1_o(fastdac_dpram_max_addr_seq_dac1_int),
    .fastdac_dpram_max_addr_rng_dac1_o(fastdac_dpram_max_addr_rng_dac1_int),
    .fastdac_rng_mode_o(fastdac_rng_mode_i),
    .rdec_p0_o(rdec_p0_o),
    .fastdac_dac1_mode_o(fastdac_dac1_mode_i),
    .fastdac_amp_dac1_shift_o(shift1_i),
    .fastdac_amp_dac1_o(fastdac_amp_dac1_i),
    .fastdac_amp_dac2_o(fastdac_amp_dac2_i),
    .fastdac_fb_mode_o(fastdac_fb_mode_i),
    .fastdac_zero_mode_o(fastdac_zero_mode_i),
    .fastdac_dac0_mode_o(fastdac_dac0_mode_i),
    .fastdac_up_offset_o(fastdac_up_offset_i),
    .division_sp_o(division_sp_i),
    .fastdac_zero_pos_o(fastdac_zero_pos_i),
    .fastdac_sequence_wen_o(fastdac_sequence_wen_int),
    .fastdac_sequence_addr_o(fastdac_sequence_addr_int),
    .fastdac_sequence_din_o(fastdac_sequence_din_int),
    .fastdac_rng_wen_o(fastdac_rng_wen_int),
    .fastdac_rng_addr_o(fastdac_rng_addr_int),
    .fastdac_rng_din_o(fastdac_rng_din_int),
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


//------ and shift_r need to be put to clk200 domaine---------------------------
(* ASYNC_REG = "TRUE" *) reg [2:0] reg_en_r;
reg [7:0]         fastdac_dpram_max_addr_seq_dac0_r;
reg [7:0]         fastdac_dpram_max_addr_seq_dac1_r;
reg [14:0]         fastdac_dpram_max_addr_rng_dac1_r;


reg [31:0] fastdac_amp_dac1_r;
reg [31:0] fastdac_amp_dac2_r;
reg [3:0] shift1_r;
reg rng_mode_r;
reg dac1_mode_r;    
reg dac0_mode_r;
reg fb_mode_r;
reg insert_zero_mode_r;
reg [15:0] up_offset_r;
reg [31:0] division_sp_r;
reg [3:0] zero_pos_r;
initial begin
    fastdac_dpram_max_addr_seq_dac0_r <= 0;
    fastdac_dpram_max_addr_seq_dac1_r <= 0;
    fastdac_dpram_max_addr_rng_dac1_r <= 0;
    fastdac_amp_dac1_r <= 0;
    fastdac_amp_dac2_r <= 0;
    reg_en_r <= 0;
    shift1_r <= 0;
    rng_mode_r <= 0;
    dac1_mode_r <= 0;
    dac0_mode_r <= 0;
    fb_mode_r <= 0;
    insert_zero_mode_r <= 0;
    up_offset_r <= 0;
    division_sp_r <= 200000000;
    zero_pos_r <= 0;
end
always @(posedge tx_core_clk) begin
        reg_en_r <= {reg_en_r[1:0],reg_en_o};
        if ((reg_en_r[2] == 0) && (reg_en_r[0] == 1)) begin
            fastdac_dpram_max_addr_seq_dac0_r <= fastdac_dpram_max_addr_seq_dac0_int;
            fastdac_dpram_max_addr_seq_dac1_r <= fastdac_dpram_max_addr_seq_dac1_int;
            fastdac_dpram_max_addr_rng_dac1_r <= fastdac_dpram_max_addr_rng_dac1_int;
            shift1_r <= shift1_i;
            rng_mode_r <= fastdac_rng_mode_i;
            dac1_mode_r <= fastdac_dac1_mode_i;
            dac0_mode_r <= fastdac_dac0_mode_i;
            fastdac_amp_dac1_r <= fastdac_amp_dac1_i;
            fastdac_amp_dac2_r <= fastdac_amp_dac2_i;
            fb_mode_r <= fastdac_fb_mode_i;
            insert_zero_mode_r <= fastdac_zero_mode_i;
            up_offset_r <= fastdac_up_offset_i;
            division_sp_r <= division_sp_i;
            zero_pos_r <= fastdac_zero_pos_i;
        end
end

//------ range-decoder P0 into the clk80 domain -------------------------------
// Latch the AXIL P0 value (rdec_p0_o, held stable in s_axil_aclk) into clk80 on
// the synchronized reg_en rising edge. Live-safe multi-bit CDC: stable source +
// synced load-enable (same pattern as the tx_core_clk handshake above). Write
// P0 (slv_reg10) first, then pulse reg_en (slv_reg3[0]) for it to take effect.
(* ASYNC_REG = "TRUE" *) reg [2:0] reg_en_80_r;
// DONT_TOUCH: CDC landing register. Must stay in fabric so the XDC false path
// (-to rdec_p0_r_reg[*]/D) keeps matching; without it synthesis absorbs this
// register into the DSP48 B input register of u_rdec/bound and the exception
// silently matches nothing (WNS -5.1ns mmcm_clkout1 -> clk_out2).
(* DONT_TOUCH = "TRUE" *) reg [15:0] rdec_p0_r;
initial begin
    reg_en_80_r = 0;
    rdec_p0_r   = 0;
end
always @(posedge clk80) begin
    reg_en_80_r <= {reg_en_80_r[1:0], reg_en_o};
    if ((reg_en_80_r[2] == 0) && (reg_en_80_r[1] == 1)) begin
        rdec_p0_r <= rdec_p0_o;
    end
end

//Synchronize tx_tready to pps
wire tx_tready_sync;
sync_tx_tready sync_tx_tready_inst (
    .tx_core_clk(tx_core_clk),
    .tx_core_rst(tx_core_reset),
    .pps_i(pps_i),
    .tx_tready(tx_tready),
    .tx_tready_o(tx_tready_sync)
);

//Generate rd_en_4 
reg rd_en_4;
reg rd_en_16;
reg rd_en_16_de;
reg [3:0] counter40;
reg [5:0] counter10;
reg [6:0] counter5;
reg pps_r;
reg pps_trigger;
always @(posedge tx_core_clk) begin
    if(tx_core_reset) begin
        rd_en_4 <= 0;
        rd_en_16 <= 0;
        rd_en_16_de <= 0;
        counter40 <= 0;
        counter10 <= 0;
        counter5 <= 0;
        pps_trigger <= 0;
    end else begin
        pps_r <= pps_i;
        if (!pps_r && pps_i) begin
            pps_trigger <= 1;
        end
        if (pps_trigger) begin
            counter40 <= counter40 + 1;
            counter10 <= counter10 + 1;
            counter5 <= counter5 + 1;
            if (counter40 == 4) begin
                counter40 <= 0;
            end
            if (counter40 == 0) begin
                rd_en_4 <= 1;
            end else begin
                rd_en_4 <= 0;
            end
            if (counter10 == 19) begin
                counter10 <= 0;
            end
            if (counter10 == 0) begin
                rd_en_16 <= 1;
            end else begin
                rd_en_16 <= 0;
            end
            if (counter5 == 39) begin
                counter5 <= 0;
            end
            if (counter5 == 0) begin
                rd_en_16_de <= 1;
            end else begin
                rd_en_16_de <= 0;
            end
        end
    end
end


// ======================= OLD RNG datapath (replaced by angles_top_wrapper) ===
// //RNG fifos. Get stream data from axis to fifo 128x16 and 16x4.
// //to get 4 bits of RNG at 40MHz ~ 20 samples 16 bits for dac1
// wire [15:0] dout16;
// wire almost_full_16;
// assign s_axis_tready = tready_flag;
// reg tready_flag;
// initial begin
//     tready_flag <= 1;
// end
// always @(posedge s_axis_clk) begin
//     if (almost_full_16) begin
//         tready_flag <= 0;
//     end else begin
//         tready_flag <= 1;
//     end
//
// end
//
// //Test fifo with deth smaller for resource optimize
// fifo_128x16 fifo_rng_128x16_inst (
//     .rst(rng_reset),                              // input wire rst
//     .wr_clk(s_axis_clk),                        // input wire wr_clk
//     .rd_clk(tx_core_clk),                        // input wire rd_clk
//     .din(s_axis_tdata),                              // input wire [127 : 0] din
//     .wr_en(s_axis_tvalid && s_axis_tready),                          // input wire wr_en
//     .rd_en(rd_en_16),                          // input wire rd_en
//     .dout(dout16),                            // output wire [15 : 0] dout
//     .full(full_16),                            // output wire full
//     .almost_full(almost_full_16),              // output wire almost_full
//     .empty(empty_16),                  // output wire empty
//     .rd_data_count(),  // output wire [15: 0] rd_data_count
//     .wr_data_count(),  // output wire [12 : 0] wr_data_count
//     .wr_rst_busy(),              // output wire wr_rst_busy
//     .rd_rst_busy()              // output wire rd_rst_busy
// );
//
// wire [3:0] rng_dout4;
// assign dout4_test = rng_dout4;
//
// fifo_16x4 fifo_rng_16x4_inst (
//     // .rst(tx_core_reset),                      // input wire rst
//     .rst(rng_reset),                      // input wire rst
//     .wr_clk(tx_core_clk),                // input wire wr_clk
//     .rd_clk(tx_core_clk),                // input wire rd_clk
//     .din(dout16),                      // input wire [15 : 0] din
//     .wr_en(rd_en_16),                  // input wire wr_en
//     .rd_en(rd_en_4),                  // input wire rd_en
//     .dout(rng_dout4),                    // output wire [3 : 0] dout
//     .full(full_4),                            // output wire full
//     .almost_full(almost_full),              // output wire almost_full
//     .wr_ack(wr_ack),                // output wire wr_ack
//     .empty(empty_4),                  // output wire empty
//     .almost_empty(almost_empty),    // output wire almost_empty
//     .valid(valid),                  // output wire valid
//     .rd_data_count(rd_data_count),  // output wire [8 : 0] rd_data_count
//     .wr_data_count(wr_data_count),  // output wire [6 : 0] wr_data_count
//     .wr_rst_busy(),      // output wire wr_rst_busy
//     .rd_rst_busy()      // output wire rd_rst_busy
// );
// =============================================================================

//RNG datapath: angles_top_wrapper adds range-decode to the RNG stream.
//Replaces the former fifo_128x16 + fifo_16x4 pair. It splits the 128-bit
//AXIS entropy into an even/true path (fifo_up_true, 128->16) and an
//uneven/basis path (range decoder), then recombines to 4 RNG bits
//{E,U,E,U} drained at 40MHz (rd_en_4) in the tx_core_clk (200MHz) domain.
//s_axis_tready is now driven by the wrapper (deasserts when both branches full).
wire almost_full_16;   // even/true-path FIFO almost_full (feeds rng_fifo_status)
wire empty_16;         // even/true-path FIFO empty      (feeds rng_fifo_status)

wire uv_almost_full_16;  // uneven/basis-path FIFO almost_full (feeds rng_fifo_status)
wire uv_empty_16;      // uneven/basis-path FIFO empty      (feeds rng_fifo_status)
wire uv_almost_full_2;  // uneven/basis-path FIFO almost_full (feeds rng_fifo_status)
wire uv_empty_2;      // uneven/basis-path FIFO empty      (feeds rng_fifo_status)

wire [3:0] rng_dout4;
assign dout4_test = rng_dout4;

angles_top_wrapper #(
    .PREC (15)
) angles_rng_inst (
    // per-domain resets, pre-synchronized in clk_rst_mngt
    .rst_clk200    (rng_rst_clk200),
    .rst_clk80     (rng_rst_clk80),
    .rst_clk250    (rng_rst_clk250),
    // entropy producer: AXI4-Stream slave (s_axis_clk); wrapper drives tready
    .s_axis_aclk   (s_axis_clk),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .s_axis_tkeep  (16'hFFFF),                 // ignored (always full 128-bit beats)
    .s_axis_tlast  (1'b0),                     // ignored (continuous entropy stream)
    // basis-processing clock (80 MHz)
    .clk80         (clk80),
    .rdec_p0_i     (rdec_p0_r),                // P(bit==0), AXIL slv_reg10 synced to clk80
    // output / consumer domain (200 MHz)
    .clk200        (tx_core_clk),
    .rd_en_4       (rd_en_4),
    .dout          (rng_dout4),                // {E,U,E,U} @ 40 MHz
    .dout_empty    (/* unused */),
    // even/true 128->16 FIFO status -> keep legacy fifo_status signal names
    .even_almost_full (almost_full_16),
    .even_empty       (empty_16),
    .up_almost_full   (uv_almost_full_16),
    .up_empty         (uv_empty_16),
    .uneven_almost_full (uv_almost_full_2),
    .uneven_empty       (uv_empty_2)
);

//Sync rng_reset to tx_core_clk domain

// (* ASYNC_REG = "TRUE" *) reg [2:0] rng_rst_r;
// initial begin rng_rst_r <= 0; end
// always @(posedge tx_core_clk) begin
//     rng_rst_r <= {rng_rst_r[1:0], rng_reset};
// end
// wire rng_rst_clk200;
// reset_register #(.RST_ACTIVE_LEVEL("HIGH")) rng_reset_inst (
//     .clk_i(tx_core_clk),
//     .rst_i(rng_rst_r[1]),
//     .clk_o(/*unused*/),
//     .rstn_o(/*unused*/),
//     .rst_o(rng_rst_clk200)); 

// tready_flag is a status/debug output that historically mirrored s_axis_tready
// (old: assign s_axis_tready = tready_flag). The wrapper now drives s_axis_tready
// directly, so mirror it back out to keep the port's meaning.
// assign tready_flag = s_axis_tready;

reg [2:0] command_rng_status_r;
reg [9:0] rng_fifo_status;
wire rng_fifo_status_valid;
wire [5:0] rng_flags;
assign rng_fifo_status_valid = command_rng_status_r[2];

// ---- CDC: sync the cross-domain FIFO flags into tx_core_clk (200 MHz) ----
// almost_full_16 / uv_almost_full_16 originate in s_axis_aclk (250 MHz, FIFO
// write side); uv_empty_16 / uv_almost_full_2 originate in clk80 (80 MHz).
// empty_16 and uv_empty_2 are already in the clk200/tx_core_clk domain and are
// used directly. (de_rng_flags is concatenated separately below.)
wire almost_full_16_sync;
wire uv_almost_full_16_sync;
wire uv_empty_16_sync;
wire uv_almost_full_2_sync;

//usecase for timing analysis on reset
always @(posedge tx_core_clk) begin
    rng_fifo_status <= 10'd1;
end

//Monitoring flags from different fifos 

// cdc_sync_single #(.STAGES(2)) u_sync_af16 (
//     .clk_i (tx_core_clk), .d_i (almost_full_16),    .q_o (almost_full_16_sync));
// cdc_sync_single #(.STAGES(2)) u_sync_uv_af16 (
//     .clk_i (tx_core_clk), .d_i (uv_almost_full_16), .q_o (uv_almost_full_16_sync));
// cdc_sync_single #(.STAGES(2)) u_sync_uv_e16 (
//     .clk_i (tx_core_clk), .d_i (uv_empty_16),       .q_o (uv_empty_16_sync));
// cdc_sync_single #(.STAGES(2)) u_sync_uv_af2 (
//     .clk_i (tx_core_clk), .d_i (uv_almost_full_2),  .q_o (uv_almost_full_2_sync));

// assign rng_flags = {almost_full_16_sync, empty_16, uv_almost_full_16_sync,
//                     uv_empty_16_sync, uv_almost_full_2_sync, uv_empty_2};
// initial begin
//     command_rng_status_r <= 0;
//     rng_fifo_status <= 0;
// end
// always @(posedge tx_core_clk) begin
//     if (rng_rst_clk200) begin
//         rng_fifo_status <= 0;
//     end else begin
//         command_rng_status_r <= {command_rng_status_r[1:0],command_rng_fifo_status_int};
//         if (command_rng_status_r[2] == 0 && command_rng_status_r[0] == 1) begin
//             rng_fifo_status <= {rng_flags,de_rng_flags};
//         end else begin
//             rng_fifo_status <= rng_fifo_status;
//         end   
//     end
// end

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
    //    .enaB(fastdac_dpram_alpha_rden_dac_r|tx_tready_sync), 
    .enaB(tx_tready_sync), 
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
    //    .enaB(fastdac_dpram_alpha_rden_dac_r|tx_tready_sync), 
    .enaB(tx_tready_sync), 
    .addrA(fastdac_sequence_addr_int), 
    .addrB(fastdac_dpram_seq_addr_dac1_r), 
    .diA(fastdac_sequence_din_int[31:16]),
    .doB(fastdac_dpram_seq_data_dac1_int_calib));

//Create dpram data write is from axil, data read is 4bit rng
// reg [9:0] sequence_rng_addr_r;
// wire [3:0] dpram_rng_dout;
// dpram_in_wider_out #(
//     .RAM_INIT("rng_sequence_dac1.mem"),
//     .WIDTHB(4),
//     .SIZEB(1024),
//     .ADDRWIDTHB(10),
//     .WIDTHA(32),
//     .SIZEA(128),
//     .ADDRWIDTHA(7))
// dpram_seq_rng_16x4_inst(
//     .clkA(s_axil_aclk), 
//     .clkB(tx_core_clk), 
//     .enaA(fastdac_rng_wen_int), 
//     .weA(fastdac_rng_wen_int), 
//     .enaB(tx_tready_sync), 
//     .addrA(fastdac_rng_addr_int), 
//     .addrB(sequence_rng_addr_r), 
//     .diA(fastdac_rng_din_int[31:0]), 
//     .doB(dpram_rng_dout)    
//     );

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
    .enaB(tx_tready_sync), 
    .addrA(fastdac_rng_addr_int), 
    .addrB(sequence_rng_addr_r), 
    .diA(fastdac_rng_din_int[31:0]), 
    .doB(dpram_rng_dout)    
    );
    // Control rd_en and wr_en of rng fifos
    // reg [5:0] counter10; //counter for pulse 10MHz
    // reg [3:0] counter40; //counter for pulse 40MHz
    // wire rd_en_4;
    // wire rd_en_16; 

//State machine to readout the rng_test from dpram
reg [2:0] state_rng;
localparam SR0 = 0, SR1 = 1, SR2 = 2, SR3 = 3, SR4 = 4;
always @(posedge tx_core_clk, posedge tx_core_reset) begin
    if(tx_core_reset) begin
        sequence_rng_addr_r <= 0;
        state_rng <= SR0;
    end else begin
        if (tx_tready_sync) begin
            case (state_rng)
            SR0: begin
                sequence_rng_addr_r <= 0;
                if (rd_en_4 == 1) begin
                    state_rng <= SR1;
                end
            end
            SR1: begin
                if (rd_en_4 == 1) begin
                    if (sequence_rng_addr_r == (fastdac_dpram_max_addr_rng_dac1_r-1)) begin //Max_addr=40
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
reg [4:0] tvalid200_r;


assign down_offset_r = 17'h10000 - up_offset_r;
always @(posedge tx_core_clk) begin
    if (tx_core_reset) begin
        offset_val <= 0;
        counter_valid <= 0;
    end else begin
        tvalid200_r <= {tvalid200_r[3:0],tvalid200};
        if (tvalid200_r[4] == 0 && tvalid200_r[3] == 1) begin
            // counter_valid <= counter_valid + 1;
            // if (counter_valid == 1) begin
            if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (offset_val >= down_offset_r) && (q_gc_time_valid_mod16 == 4'h0)) begin
                offset_val <= offset_val - 15'h20;
                if (offset_val == down_offset_r) begin
                    offset_val <= up_offset_r;
                end
            end else if ((tdata200_mod >= gate_pos2 && tdata200_mod < gate_pos3) && (offset_val <= up_offset_r) && (q_gc_time_valid_mod16 == 4'h0)) begin
                offset_val <= offset_val - 15'h20;
                if (offset_val == 16'h0020) begin
                    offset_val <= 0;
                end
            end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (offset_val <= up_offset_r) && (q_gc_time_valid_mod16 == 4'h0)) begin
                offset_val <= offset_val + 15'h20;
                if (offset_val == up_offset_r) begin
                    offset_val <= down_offset_r;
                end
            end else if ((tdata200_mod >= gate_pos0 && tdata200_mod < gate_pos1) && (offset_val >= down_offset_r) && (q_gc_time_valid_mod16 == 4'h0)) begin
                offset_val <= offset_val + 15'h20;
                if (offset_val == 16'hffe0) begin
                    offset_val <= 0;
                end
            end      
        end else begin
            offset_val <= offset_val;
        end
    end
end

wire [15:0] offset;
assign offset = fb_mode_r? offset_val:0;

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

always @(ext_amp0,ext_amp1,ext_amp2,ext_amp3,zero_amp) begin
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
reg [2:0] rd_en_4_shift;

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
        if (rd_en_4_shift[0] == 1 && insert_zero_mode_r == 0) begin
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
            
        end else if (rd_en_4_shift[0] == 1 && insert_zero_mode_r == 1) begin
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
            // end else if (counter_3b >= 6 && counter_3b<7 && pos == 0) begin
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
    end
end

// reg [2:0] rd_en_4_shift;
// always @(posedge tx_core_clk) begin
//     if (tx_core_reset) begin
//         amp1 <= 0;
//         minus_amp1 <= 0;
//         amp2 <= 0;
//         minus_amp2 <= 0;
//         amp1_old <= 0;
//         minus_amp1_old <= 0;
//         amp2_old <= 0;
//         minus_amp2_old <= 0;
//         rd_en_4_shift <= 0;
//     end else begin
//         rd_en_4_shift <= {rd_en_4_shift[1:0],rd_en_4};
//         if (rd_en_4_shift[0]) begin
//             // case(rng_dout4)
//             case (rng_value)
//                 4'h0: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end            
//                 4'h1: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
//                 4'h2: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
//                 4'h3: begin amp1 <= amp0_r; minus_amp1 <= minus_amp0_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
//                 4'h4: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
//                 4'h5: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
//                 4'h6: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
//                 4'h7: begin amp1 <= amp1_r; minus_amp1 <= minus_amp1_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
//                 4'h8: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
//                 4'h9: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
//                 4'ha: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
//                 4'hb: begin amp1 <= amp2_r; minus_amp1 <= minus_amp2_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
//                 4'hc: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp0_r; minus_amp2 <= minus_amp0_r; end
//                 4'hd: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp1_r; minus_amp2 <= minus_amp1_r; end
//                 4'he: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp2_r; minus_amp2 <= minus_amp2_r; end
//                 4'hf: begin amp1 <= amp3_r; minus_amp1 <= minus_amp3_r; amp2 <= amp3_r; minus_amp2 <= minus_amp3_r; end
//             endcase 
//             amp1_old <= amp1;
//             minus_amp1_old <= minus_amp1;
//             amp2_old <= amp2;
//             minus_amp2_old <= minus_amp2; 
//         end
//     end
// end

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
                            

//10 steps   
// shift1_r[3]? (shift1_r[1]? sam0_a: (shift1_r[0]? sam0_9:sam0_8))
// :();

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

// assign rd_en_16 = (counter10 == 0)?1:0;
// assign rd_en_4 = (counter40 == 0)?1:0;

always@(posedge tx_core_clk, posedge tx_core_reset)
begin   
    if (tx_core_reset)
    begin
        // counter10 <= 1<<6 - 1;
        // counter40 <= 1<<4 - 1;
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
        if (tx_tready_sync) begin
            // counter10 <= counter10 + 1;
            // counter40 <= counter40+ 1;
            // if (counter10 >= 19) begin // work with 20 div, missing dataout with 5 div
            //     counter10 <= 0;
            // end 
            // if (counter40 >= 4) begin
            //     counter40 <= 0;
            // end 
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
                    if (fastdac_dpram_seq_addr_dac0_r == (fastdac_dpram_max_addr_seq_dac0_r-1)) begin
                        fastdac_dpram_seq_addr_dac0_r <= 0;
                    end else 
                        fastdac_dpram_seq_addr_dac0_r <= fastdac_dpram_seq_addr_dac0_r+1;

                    if (fastdac_dpram_seq_addr_dac1_r == (fastdac_dpram_max_addr_seq_dac1_r-1)) begin
                        fastdac_dpram_seq_addr_dac1_r <= 0;
                    end else 
                        fastdac_dpram_seq_addr_dac1_r <= fastdac_dpram_seq_addr_dac1_r+1;
                    addr_state_dac0 <= S3;
                end
                default : ;
            endcase

            case (single_addr_state_dac0)
                T0 : begin
                    // fastdac_one_pulse_data_dac0_int <= 64'hffffffffffffffff;
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
                    // fastdac_one_pulse_data_dac0_int <= 64'he000d000c000b000; //4 samples
                    fastdac_one_pulse_data_dac0_int <= 64'hb000c000d000e000; //4 samples
                    single_addr_state_dac0 <= T3;
                end
                T3 : begin
                    // fastdac_one_pulse_data_dac0_int <= 64'ha000900080003267; //4 samples
                    fastdac_one_pulse_data_dac0_int <= 64'h326780009000a000; //4 samples
                    single_addr_state_dac0 <= T4;
                end
                T4 : begin
                    // fastdac_one_pulse_data_dac0_int <= 64'h3267ffffffffffff;
                    fastdac_one_pulse_data_dac0_int <= 64'hffffffffffff3267;
                    single_addr_state_dac0 <= T5;
                end
                T5 : begin
                    counter_loop <= counter_loop + 1;
                    if (counter_loop <= division_sp_r - 6) begin  //division_sp define fq of sp. 
                        // fastdac_one_pulse_data_dac0_int <= 64'hffffffffffffffff;
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
            // counter10 <= 1<<6 -1;
            // counter40 <= 1<<4 -1;
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
//dac0_mode_r control if dac0 take data from dpram or directly data for one pulse
//0: take data from dpram
//1: direct input data to generate one pulse
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