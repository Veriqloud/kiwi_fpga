`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau
// 
// Create Date: 01/30/2024 12:17:12 PM
// Design Name: 
// Module Name: ILVDS_TDC
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


module ILVDS_TDC(
    input lclk_n,
    input lclk_p,
    output O_lclk,

    input frameA_n,
    input frameA_p,
    output O_frameA,
    
    input frameB_n,
    input frameB_p,
    output O_frameB,

    input sdiA_n,
    input sdiA_p,
    output O_sdiA,

    input sdiB_n,
    input sdiB_p,
    output O_sdiB

);
    
IBUFDS tdc_lclk_ibuf    (.IB(lclk_n),.O(O_lclk),.I(lclk_p));
IBUFDS tdc_frameA_ibuf    (.IB(frameA_n),.O(O_frameA),.I(frameA_p));
IBUFDS tdc_frameB_ibuf    (.IB(frameB_n),.O(O_frameB),.I(frameB_p));
IBUFDS tdc_sdiA_ibuf    (.IB(sdiA_n),.O(O_sdiA),.I(sdiA_p));
IBUFDS tdc_sdiB_ibuf    (.IB(sdiB_n),.O(O_sdiB),.I(sdiB_p));
endmodule
