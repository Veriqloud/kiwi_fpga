`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Hop DINH, Fabrice Faveneau
//
// Create Date: 06/30/2023 10:28:44 AM
// Design Name: Qline_turnkey
// Module Name: reset_register
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Reset synchronizer: asynchronous assert, synchronous de-assert.
//              Takes an unsynchronized reset and releases it cleanly in the
//              clk_i domain through a 2-FF chain. Drives both polarities
//              (rstn_o active-low, rst_o active-high) plus a clk_i passthrough.
//
// Dependencies: none
//
// Revision 0.01 - File Created
// Revision 0.02 - Header completed
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////


module reset_register
        #(parameter RST_ACTIVE_LEVEL = "LOW") (
        input clk_i,
        input rstn_i,
        input rst_i,
        output clk_o,
        output rstn_o,
        output rst_o
    );
(* ASYNC_REG = "TRUE" *) reg [1:0] rstn_r;
(* ASYNC_REG = "TRUE" *) reg [1:0] rst_r;
    
// AXI-LITE reset mngt
initial
begin
    rstn_r <= 0;
    rst_r  <= 3;
end

if (RST_ACTIVE_LEVEL == "LOW")
    always @(posedge clk_i, negedge rstn_i)
    begin
        if (!rstn_i)
        begin
            rstn_r <= 0;
            rst_r  <= 3;
        end    else begin
            rstn_r  <= {rstn_r[0],1'b1};
            rst_r   <= {rst_r[0],1'b0};
        end
    end
else if (RST_ACTIVE_LEVEL == "HIGH")
    always @(posedge clk_i,posedge rst_i)
    begin
        if (rst_i)
        begin
            rstn_r <= 0;
            rst_r  <= 3;
        end    else begin
            rstn_r  <= {rstn_r[0],1'b1};
            rst_r   <= {rst_r[0],1'b0};
        end
end

assign rstn_o   = rstn_r[1];
assign rst_o    = rst_r[1];
assign clk_o    = clk_i;

endmodule
