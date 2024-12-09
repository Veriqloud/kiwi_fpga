`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2023 04:29:04 PM
// Design Name: 
// Module Name: sync_ltc
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

// module sync_ltc(
//     input pps,
//     input clk10,
//     input rst,
//     input sync_trigger, //1s trigger 
//     output sync_ltc
//     );
// reg [1:0] shift;


// always @(posedge pps) begin
//     if(!rst) begin
//         shift <= 0;
//     end else begin
//         shift <= {shift[0],sync_trigger};
//     end            
// end

// assign sync_ltc = shift[0];

// endmodule

module sync_ltc(
    input pps,
    input clk10,
    input rst,
    input sync_trigger, //1s trigger 
    output reg sync_ltc
    );
reg [31:0] counter;
wire trigger_pps; //trigger align to pps
reg [2:0] shift;


always @(posedge pps) begin
    shift <= {shift[1:0],sync_trigger};
end

assign trigger_pps = shift[0];

 always @(posedge clk10) begin
     if (!rst) begin
         counter <= 0;
         sync_ltc <= 1'b0;
     end else begin
         if (trigger_pps) begin
             counter <= counter + 1;
             if (counter <= 20) begin //1ms 20000
                 sync_ltc <= 1'b1;
             end else begin
                 sync_ltc <= 1'b0;
             end
         end else begin
            counter <= 0;
         end
     end
 end

endmodule
