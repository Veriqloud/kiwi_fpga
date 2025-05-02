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
    output tdc_refclk_n,
    output tdc_refclk_p,
    input tdc_reflck,

    output tdc_rstidx_n,
    output tdc_rstidx_p,
    input tdc_rstidx,

    output tdc_lclki_n,
    output tdc_lclki_p,
    input tdc_lclki

    );
    
OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_refclk (
      .O(tdc_refclk_p),     // Diff_p output (connect directly to top-level port)
      .OB(tdc_refclk_n),   // Diff_n output (connect directly to top-level port)
      .I(tdc_reflck)      // Buffer input
   );
OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_rstidx (
      .O(tdc_rstidx_p),     // Diff_p output (connect directly to top-level port)
      .OB(tdc_rstidx_n),   // Diff_n output (connect directly to top-level port)
      .I(tdc_rstidx)      // Buffer input
   );

OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_lclki (
      .O(tdc_lclki_p),     // Diff_p output (connect directly to top-level port)
      .OB(tdc_lclki_n),   // Diff_n output (connect directly to top-level port)
      .I(tdc_lclki)      // Buffer input
   );


endmodule
