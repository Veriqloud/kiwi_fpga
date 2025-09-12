`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2023 01:42:40 PM
// Design Name: Qline_turnkey
// Module Name: ILVDS
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Instantiate IBUFDS
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ILVDS(
    input IB,
    input I,
    output O
    );

IBUFDS refclk_ibuf    (.IB(IB),.O(O),.I(I));

endmodule


