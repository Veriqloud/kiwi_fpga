`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer:
//
// Create Date: 10/09/2026
// Design Name: Qline_turnkey
// Module Name: ddr_axi_reset_seq
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Resets both sides of the DDR4 AXI path together.
//
//   The S side (ddr_data, axis_burst, the virtual FIFO and the S port of the
//   AXI clock converter) runs on clk200. The M side (the M port of the clock
//   converter and the AXI shim of the DDR4 MIG, c0_ddr4_aresetn) runs on the
//   MIG ui_clk. The AXI clock converter resets its whole FIFO when either
//   side is reset, while the MIG keeps whatever write beats or commands it had
//   already accepted, so a reset of the S side alone can leave the MIG one or
//   more beats out of step with the AXI bursts (docs/monitoring.md, "DDR path
//   reset").
//
//   Sequence, driven by req_rstn_200 (ddr_data_rst, 0x12000 offset 0x10):
//   - req_rstn_200 low: the S side goes into reset at once, the M side
//     is requested into reset.
//   - The S side stays in reset until the M side has been seen in reset and
//     req_rstn_200 is high again, at least MIN_RST_CYCLES clk200 cycles.
//   - The M side is released first; the S side follows RELEASE_GAP clk200
//     cycles after the release has been seen back in clk200.
//
//   c0_ddr4_aresetn resets only the AXI shim of the MIG; it does not start a
//   calibration (that is sys_rst / ui_clk_sync_rst).
//
//   If ui_clk is not running the S side is held in reset: the DDR path cannot
//   work without the MIG anyway.
//
// Dependencies: reset_register.v
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////


module ddr_axi_reset_seq #(
    parameter integer MIN_RST_CYCLES = 64,
    parameter integer RELEASE_GAP    = 16
)(
    input  wire clk200_i,
    input  wire req_rstn_200,     // 1 = run, synchronous to clk200_i
    input  wire clk_ui_i,
    input  wire rst_ui_i,         // MIG ui_clk_sync_rst, active high
    output wire s_rstn_200_o,     // to reset_register (LOW) in clk200
    output wire m_rstn_ui_o       // c0_ddr4_aresetn and converter m_axi_aresetn
);

localparam [1:0] ST_RST = 2'd0, ST_REL_M = 2'd1, ST_REL_S = 2'd2, ST_RUN = 2'd3;

reg [1:0]  state  = ST_RST;
reg        m_req  = 1'b0;        // clk200: 1 = M side may run
reg        s_run  = 1'b0;        // clk200: 1 = S side may run
reg [7:0]  cnt    = 8'd0;

(* ASYNC_REG = "TRUE" *) reg [2:0] m_req_ui_r = 3'b000;   // clk_ui
(* ASYNC_REG = "TRUE" *) reg [2:0] m_ack_r    = 3'b000;   // clk200

// M side, ui_clk domain. Both reset inputs come from ui_clk flops.
always @(posedge clk_ui_i) begin
    m_req_ui_r <= {m_req_ui_r[1:0], m_req};
end

reset_register #(.RST_ACTIVE_LEVEL("HIGH")) m_reset_inst (
    .clk_i (clk_ui_i),
    .rstn_i(1'b1),
    .rst_i (rst_ui_i | ~m_req_ui_r[2]),
    .clk_o (),
    .rstn_o(m_rstn_ui_o),
    .rst_o ());

// M side state seen in clk200
always @(posedge clk200_i) begin
    m_ack_r <= {m_ack_r[1:0], m_rstn_ui_o};
end
wire m_running = m_ack_r[2];

always @(posedge clk200_i) begin
    if (!req_rstn_200) begin
        state <= ST_RST;
        m_req <= 1'b0;
        s_run <= 1'b0;
        cnt   <= 8'd0;
    end else begin
        case (state)
            ST_RST: begin
                m_req <= 1'b0;
                s_run <= 1'b0;
                if (cnt != 8'hff) cnt <= cnt + 1;
                if (!m_running && cnt >= MIN_RST_CYCLES) begin
                    state <= ST_REL_M;
                    m_req <= 1'b1;
                    cnt   <= 8'd0;
                end
            end
            ST_REL_M: begin
                m_req <= 1'b1;
                if (m_running) begin
                    state <= ST_REL_S;
                    cnt   <= 8'd0;
                end
            end
            ST_REL_S: begin
                cnt <= cnt + 1;
                if (cnt >= RELEASE_GAP) begin
                    state <= ST_RUN;
                    s_run <= 1'b1;
                end
            end
            ST_RUN: begin
                s_run <= 1'b1;
                // the MIG reset its AXI shim on its own (ui_clk_sync_rst):
                // take the S side through a full sequence as well
                if (!m_running) begin
                    state <= ST_RST;
                    m_req <= 1'b0;
                    s_run <= 1'b0;
                    cnt   <= 8'd0;
                end
            end
            default: state <= ST_RST;
        endcase
    end
end

// Asserts with req_rstn_200 in the same cycle (reset_register is asynchronous
// on assertion), releases only from the sequence.
assign s_rstn_200_o = req_rstn_200 & s_run;

endmodule
