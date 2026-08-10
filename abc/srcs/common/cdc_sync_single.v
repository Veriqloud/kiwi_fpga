// ============================================================================
// cdc_sync_single.v
//
// Single-bit clock-domain-crossing synchronizer (N-FF, default 2-FF).
//
// Captures one asynchronous 1-bit signal 'd_i' into the destination clock
// 'clk_i' domain through STAGES back-to-back flip-flops, giving the first
// flop time to resolve metastability before the value is used. Output 'q_o'
// is the last (settled) stage.
//
//   d_i --|>FF0|--|>FF1|-- ... --|>FF(STAGES-1)|--> q_o   (all @ clk_i)
//          async   settling            settled
//
// Use for LEVEL or independent single-bit flags (status/enable/reset-request).
// NOT for multi-bit buses that must stay mutually coherent (use a gray-coded
// FIFO / handshake / bus synchronizer instead) -- instantiate one of these per
// INDEPENDENT bit only.
//
// The ASYNC_REG attribute keeps the chain packed and marks it for the tools so
// placement maximises metastability MTBF. Constrain the crossing with e.g.
//   set_false_path  -to [get_pins .../u_sync/sync_ff_reg[0]/D]
// (or set_max_delay -datapath_only), targeting the FIRST stage.
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 07/08/2026
// Design Name: Qline_turnkey
// Module Name: cdc_sync_single
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Reusable single-bit N-FF (default 2-FF) CDC synchronizer.
//
// Dependencies: none
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module cdc_sync_single #(
    parameter integer STAGES = 2        // number of synchronizer FFs (>= 2)
)(
    input  wire clk_i,                  // destination clock domain
    input  wire d_i,                    // asynchronous 1-bit input (source domain)
    output wire q_o                     // synchronized output (clk_i domain)
);

    (* ASYNC_REG = "TRUE" *) reg [STAGES-1:0] sync_ff;

    always @(posedge clk_i)
        sync_ff <= {sync_ff[STAGES-2:0], d_i};   // shift in at LSB, out at MSB

    assign q_o = sync_ff[STAGES-1];              // last, settled stage

endmodule

`default_nettype wire
