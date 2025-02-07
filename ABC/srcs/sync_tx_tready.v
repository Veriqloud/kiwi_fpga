`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop Dinh
// 
// Create Date: 12/06/2023 03:56:14 PM
// Design Name: 
// Module Name: test_jesd_reset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Synchronize tx_tready signal to PPS
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sync_tx_tready(
    input pps_i,
    input tx_core_clk,
    input tx_core_rst,
    input tx_tready,
    output reg tx_tready_o
    );

// reg pps_trigger;
reg pps_r;

always @(posedge tx_core_clk, posedge tx_core_rst) begin
    if (tx_core_rst) begin
        // pps_trigger <= 1'b0;
        tx_tready_o <= 0;
        pps_r <= 0;
    end else begin
        pps_r <= pps_i;
        if (!pps_r && pps_i) begin
            // pps_trigger <= 1'b1;
            tx_tready_o <= tx_tready;
        end
    end
end

// reg [1:0] shift_tx_ready;

// always @(posedge pps_i) begin
//     shift_tx_ready <= {shift_tx_ready[0],tx_tready};
// end
// assign tx_tready_o = shift_tx_ready[0];

endmodule
