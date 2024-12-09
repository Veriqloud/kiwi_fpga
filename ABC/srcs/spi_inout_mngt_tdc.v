`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2023 11:15:04 AM
// Design Name: 
// Module Name: tdc_spi_inout_mngt
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


module spi_inout_mngt_tdc
    #(NBR_OF_SLAVE = 2)
    (
    // Interface with SPI module
    // MISO 0
    output        out0_o,
    // MOSI 0
    input         in0_i,
    // CONTROL 0
    input         in0t_i,
    
    // MISO 1
    output        out1_o,
    // MOSI 1
    input         in1_i,
    // CONTROL 1
    input         in1t_i,
    
    // CLOCK
    input           sck_i,
    output          sck_o,
    input           sckt_i,
   
   // SELECT
    input[NBR_OF_SLAVE-1:0]      ss_i,
    output[NBR_OF_SLAVE-1:0]     ss_o,
    input           sst_i,
    
    // SPI PORT OUTPUT
    // MOSI
    inout          i0_io,
    inout          i1_io,
    inout[NBR_OF_SLAVE-1:0]     ioss_io,
    inout          iosck_io);

	IOBUF QSPI_IO0_TDC  (.O(out0_o),.IO(i0_io),.I(in0_i),.T(in0t_i));
	IOBUF QSPI_IO1_TDC  (.O(out1_o),.IO(i1_io),.I(in1_i),.T(in1t_i));
	IOBUF QSPI_SCK_TDC  (.O(sck_o),.IO(iosck_io),.I(sck_i),.T(sckt_i));
    
    genvar i;
    generate for (i = 0; i < NBR_OF_SLAVE ; i = i + 1) begin: tristate
        IOBUF QSPI_SS_TDC  (.O(ss_o[i]),.IO(ioss_io[i]),.I(ss_i[i]),.T(sst_i));
    end
    endgenerate
 
endmodule
