`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH
//
// Create Date: 11/07/2023 05:40:28 PM
// Design Name: Qline_turnkey
// Module Name: pcierefclk
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: PCIe reference clock input buffer. Wraps an IBUFDS_GTE4 to bring
//              the differential refclk pair (I/IB) into the GT quad as O, plus a
//              divide-by-1 copy on ODIV2 for fabric use.
//
// Dependencies: Xilinx IBUFDS_GTE4 primitive (UltraScale+ GTH/GTY)
//
// Revision 0.01 - File Created
// Revision 0.02 - Header completed
// Additional Comments:
// REFCLK_HROW_CK_SEL = 2'b00 selects ODIV2 = O (no division). CEB tied low to
// keep the buffer permanently enabled.
//
//////////////////////////////////////////////////////////////////////////////////


module pcierefclk(
    //ports for PCIE refclk buffer
    input IB,
    input I,
    output O,
    output ODIV2
    );

IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(O), .ODIV2(ODIV2), .I(I), .CEB(1'b0), .IB(IB)); 

endmodule
