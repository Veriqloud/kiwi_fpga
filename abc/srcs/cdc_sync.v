`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2024 11:59:31 AM
// Design Name: 
// Module Name: cdc_sync
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


module cdc_sync(
    input clk_fast,
    input clk_slow,
    input command_en,
    input rstn_fast,
    input rstn_slow
    );

reg [31:0] counter;
reg [2:0] command_en_r;
reg [31:0] counter_fast_val;

initial begin
    command_en_r <= 0;
end

always @(posedge clk_fast) begin
    if (!rstn_fast) begin
        counter <= 0;
        counter_fast_val <= 0;
    end else begin
        counter <= counter + 1;
        command_en_r <= {command_en_r[1:0],command_en};
        if (command_en_r[2] == 0 && command_en_r[1] == 1) begin
            counter_fast_val <= counter;
        end else counter_fast_val <= counter_fast_val;
    end
end

reg [2:0] valid_slow;
reg [31:0] slv_reg;
initial begin
    valid_slow <= 0;
end
always @(posedge clk_slow) begin
    if (!rstn_slow) begin
        valid_slow <= 0;
        slv_reg <= 0;
    end else begin
        valid_slow <= {valid_slow[1:0], command_en_r[1]};
        if (valid_slow[2] == 0 && valid_slow[1] == 1) begin
            slv_reg <= counter_fast_val;
        end else slv_reg <= slv_reg;
    end
end

// reg [31:0] slv_reg;
// reg [31:0] slv_reg_sync1, slv_reg_sync2;
// always @(posedge clk_slow) begin
//     if (!rstn_slow) begin
//         slv_reg <= 0;
//         slv_reg_sync1 <= 0;
//         slv_reg_sync2 <= 0;
//     end else begin
//         slv_reg_sync1 <= counter_fast_val;
//         slv_reg_sync2 <= slv_reg_sync1;
//         slv_reg <= slv_reg_sync2;
//     end
// end
endmodule
