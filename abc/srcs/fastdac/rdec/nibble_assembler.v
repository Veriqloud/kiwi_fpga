// ============================================================================
// nibble_assembler.v
//
// Recombine stage (see docs/architecture.md). Combines one even pair and one
// uneven pair into a 4-bit nibble {E,U,E,U} and writes it to fifo2 (fifo_4x4),
// whose every read then yields a ready-made dout[3:0] = even|uneven|even|uneven.
//
//   nibble = { even[1], uneven[1], even[0], uneven[0] }
//             dout[3]   dout[2]    dout[1]   dout[0]
//
// Purely combinational: a nibble is produced (and both pair sources advanced)
// on any cycle where BOTH pairs are valid and fifo2 has room. fifo2 'full'
// throttles the average rate down to the 40 MHz read rate; surplus upstream
// entropy is dropped earlier (at each branch FIFO).
// ============================================================================
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 06/30/2026
// Design Name: Qline_turnkey
// Module Name: nibble_assembler
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Combines an even pair and an uneven pair into a {E,U,E,U} nibble
//              and writes it to fifo2 when both are valid and fifo2 has room.
//
// Dependencies: none
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module nibble_assembler (
    // ---- even pair source (true RNG) ----
    input  wire [1:0] even_pair,
    input  wire       even_valid,
    output wire       even_take,

    // ---- uneven pair source (biased) ----
    input  wire [1:0] uneven_pair,
    input  wire       uneven_valid,
    output wire       uneven_take,

    // ---- fifo2 (fifo_4x4) write side ----
    output wire [3:0] nibble,
    output wire       nibble_wr_en,
    input  wire       fifo2_full
);

    wire go = even_valid & uneven_valid & ~fifo2_full;

    assign nibble       = {even_pair[1], uneven_pair[1], even_pair[0], uneven_pair[0]};
    assign nibble_wr_en = go;
    assign even_take    = go;
    assign uneven_take  = go;

endmodule

`default_nettype wire
