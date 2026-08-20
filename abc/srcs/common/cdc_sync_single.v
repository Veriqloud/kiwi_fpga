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
// Revision 0.02 - no change
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
