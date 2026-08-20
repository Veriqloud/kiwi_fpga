`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau
// 
// Create Date: 01/30/2024 12:23:11 PM
// Design Name: Qline_turnkey
// Module Name: tdc_olvds
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2 
// Description: Buffers for clock and reset, sent to TDC chip
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed the tdc_reflck port spelling to tdc_refclk (port
//                 declaration and the OBUFDS_tdc_refclk .I connection)
//               - OBUFDS_tdc_lclki slew SLOW -> FAST. This buffer forwards
//                 clk200 (200 MHz, 2.5 ns half period) to the TDC LCLK input,
//                 where a slow edge rate costs eye margin on the LVDS link.
//                 The refclk (5 MHz) and rstidx buffers keep SLOW, they are
//                 slow enough that the reduced edge rate is harmless.
// Additional Comments:
//   IOSTANDARD is left at DEFAULT on all three buffers, the actual standard
//   comes from the LVDS properties set on the pins in
//   Qline_turnkey_constrs.xdc.
//
//////////////////////////////////////////////////////////////////////////////////


module tdc_olvds(
    output  tdc_refclk_n,
    output  tdc_refclk_p,
    input   tdc_refclk,

    output  tdc_rstidx_n,
    output  tdc_rstidx_p,
    input   tdc_rstidx,

    output  tdc_lclki_n,
    output  tdc_lclki_p,
    input   tdc_lclki
);
    
OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_tdc_refclk (
      .O(tdc_refclk_p),     // Diff_p output (connect directly to top-level port)
      .OB(tdc_refclk_n),   // Diff_n output (connect directly to top-level port)
      .I(tdc_refclk)      // Buffer input
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
      .SLEW("FAST")           // Specify the output slew rate
   ) OBUFDS_tdc_lclki (
      .O(tdc_lclki_p),     // Diff_p output (connect directly to top-level port)
      .OB(tdc_lclki_n),   // Diff_n output (connect directly to top-level port)
      .I(tdc_lclki)      // Buffer input
   );

endmodule
