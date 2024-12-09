`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/22/2024 03:03:22 PM
// Design Name: 
// Module Name: axi_monitor
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


module axi_monitor(
    input clk200_i,
    input ddr_data_rstn,

    input rvalid,
    input rready,
    input wvalid,
    input wready,

    output counter_read,
    output counter_write

    );


reg [47:0] counter_read;
reg [47:0] counter_write;

always @(posedge clk200_i) begin
    if(!ddr_data_rstn) begin
        counter_write <= 0;
        counter_read <= 0;
    end else begin
        if (wready && wvalid) begin
            counter_write <= counter_write + 1;
        end else counter_write <= counter_write;
        if (rready && rvalid) begin
            counter_read <= counter_read + 1;
        end else counter_read <= counter_read;
    end
end

endmodule