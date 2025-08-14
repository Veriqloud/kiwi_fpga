`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2023 01:42:40 PM
// Design Name: 
// Module Name: IBUFDS
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


module ILVDS(
    input IB,
    input I,
    output O
    );

IBUFDS refclk_ibuf    (.IB(IB),.O(O),.I(I));

endmodule


