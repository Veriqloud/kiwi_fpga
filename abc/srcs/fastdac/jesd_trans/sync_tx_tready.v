`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 12/06/2023 03:56:14 PM
// Design Name: Qline_turnkey
// Module Name: sync_tx_ready
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description:  phase shift tx_tready signal, to align to pps_i rising edge
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - no change
// Additional Comments:
//  pps_i is synchronous to tx_core_clk, no need 2FF synchronizer
//////////////////////////////////////////////////////////////////////////////////


module sync_tx_tready(
    input pps_i,
    input tx_core_clk,
    input tx_core_rst,
    input tx_tready,
    output reg tx_tready_o
);

reg pps_r;
always @(posedge tx_core_clk, posedge tx_core_rst) begin
    if (tx_core_rst) begin
        tx_tready_o <= 0;
        pps_r <= 0;
    end else begin
        pps_r <= pps_i;
        if (!pps_r && pps_i) begin
            tx_tready_o <= tx_tready;
        end
    end
end
endmodule
