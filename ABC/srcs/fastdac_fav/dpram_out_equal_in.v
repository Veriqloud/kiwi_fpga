`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2023 01:40:59 PM
// Design Name: 
// Module Name: dpram_out_equal_in
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

// Simple Dual-Port Block RAM with Two Clocks
// File: simple_dual_two_clocks.v

module dpram_out_equal_in #(
    parameter RAM_INIT="alpha_pos.init",
    parameter WIDTH = 32,
    parameter SIZE = 1024,
    parameter ADDRWIDTH = 10)
    (clka,clkb,ena,enb,wea,addra,addrb,dia,dob);

input clka,clkb,ena,enb,wea;
input [ADDRWIDTH-1:0] addra,addrb;
input [WIDTH-1:0] dia;
output [WIDTH-1:0] dob;
reg [WIDTH-1:0] ram [SIZE-1:0];
reg [WIDTH-1:0] dob;

initial begin
$readmemb(RAM_INIT, ram, 0, SIZE-1);
end

always @(posedge clka)
begin
if (ena)
begin
if (wea)
ram[addra] <= dia;
end
end

always @(posedge clkb)
begin
if (enb)
begin
dob <= ram[addrb];
end
end
endmodule