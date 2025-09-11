`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2023 05:40:28 PM
// Design Name: Qline_turnkey
// Module Name: pcierefclk
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: GT buffer for PCIE clock
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
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
