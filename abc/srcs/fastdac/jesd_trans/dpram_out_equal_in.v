`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud
// Engineer: Fabrice Faveneau
// 
// Create Date: 07/13/2023 01:40:59 PM
// Design Name: Qline_turnkey
// Module Name: dpram_out_equal_in
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Simple Dual-Port Block RAM with Two Clocks
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Add header and comments
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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