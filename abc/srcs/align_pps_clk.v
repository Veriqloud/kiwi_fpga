`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 02:48:03 PM
// Design Name: 
// Module Name: align_pps_clk
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


module align_pps_clk(
    input clk15,
    input pps,
    output clk15_a

    );
reg [1:0] shift;
wire clk15_a_int;
assign clk15_a = clk15_a_int;
always @(posedge pps) begin
    shift <= {shift[0], clk15};
end
assign clk15_a_int = shift[0];
endmodule
