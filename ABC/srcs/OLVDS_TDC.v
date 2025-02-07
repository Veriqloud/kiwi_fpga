`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau
// 
// Create Date: 01/30/2024 12:23:11 PM
// Design Name: 
// Module Name: OLVDS_TDC
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


module OLVDS_TDC(
    output OB_tdc_refclck_n,
    output O_tdc_refclk_p,
    input I_tdc_reflck,

    output OB_tdc_rstidxp_n,
    output O_tdc_rstidxp_p,
    input I_tdc_rstidxp,

    output OB_tdc_lclki_n,
    output O_tdc_lclki_p,
    input I_tdc_lclki

    );
    
OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_refclk (
      .O(O_tdc_refclk_p),     // Diff_p output (connect directly to top-level port)
      .OB(OB_tdc_refclck_n),   // Diff_n output (connect directly to top-level port)
      .I(I_tdc_reflck)      // Buffer input
   );
OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_rstidxp (
      .O(O_tdc_rstidxp_p),     // Diff_p output (connect directly to top-level port)
      .OB(OB_tdc_rstidxp_n),   // Diff_n output (connect directly to top-level port)
      .I(I_tdc_rstidxp)      // Buffer input
   );

OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_lclki (
      .O(O_tdc_lclki_p),     // Diff_p output (connect directly to top-level port)
      .OB(OB_tdc_lclki_n),   // Diff_n output (connect directly to top-level port)
      .I(I_tdc_lclki)      // Buffer input
   );


endmodule
