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
    input IB_lclk_n,
    input I_lclk_p,
    output O_lclk,

    input IB_frameA_n,
    input I_frameA_p,
    output O_frameA,
    
    input IB_frameB_n,
    input I_frameB_p,
    output O_frameB,

    input IB_sdiA_n,
    input I_sdiA_p,
    output O_sdiA,

    input IB_sdiB_n,
    input I_sdiB_p,
    output O_sdiB

);
    
IBUFDS tdc_lclk_ibuf    (.IB(IB_lclk_n),.O(O_lclk),.I(I_lclk_p));
IBUFDS tdc_frameA_ibuf    (.IB(IB_frameA_n),.O(O_frameA),.I(I_frameA_p));
IBUFDS tdc_frameB_ibuf    (.IB(IB_frameB_n),.O(O_frameB),.I(I_frameB_p));
IBUFDS tdc_sdiA_ibuf    (.IB(IB_sdiA_n),.O(O_sdiA),.I(I_sdiA_p));
IBUFDS tdc_sdiB_ibuf    (.IB(IB_sdiB_n),.O(O_sdiB),.I(I_sdiB_p));
endmodule
