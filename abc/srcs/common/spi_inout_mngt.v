`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud   
// Engineer: Fabrice Faveneau
// 
// Create Date: 06/19/2023 11:15:04 AM
// Design Name: Qline_turnkey
// Module Name: spi_inout_mngt
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Manage inout pins for SPI
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_inout_mngt #(
    NBR_OF_SLAVE = 3
    )(
    output        rst_jic,
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
    
    // select for slow dac
    // input ss_i_sda,
    // input sst_i_sda,
    // output ss_o_sda,
    // inout ioss_io_sda,
    // SPI PORT OUTPUT
    // MOSI
//    inout          i0_io,
//    inout          i1_io,
//    inout[NBR_OF_SLAVE-1:0]     ioss_io,
//    inout          iosck_io
    // inout          mosi_io,
    // inout          miso_io,
    // inout[NBR_OF_SLAVE-1:0]     ss_io,
    // inout          sck_io
    output          mosi_io,
    inout          miso_io,
    output[NBR_OF_SLAVE-1:0]     ss_io,
    output          sck_io
);
    assign rst_jic = 1'b1;
	IOBUF QSPI_IO0_TDC  (.O(out0_o),.IO(mosi_io),.I(in0_i),.T(in0t_i));
	IOBUF QSPI_IO1_TDC  (.O(out1_o),.IO(miso_io),.I(in1_i),.T(in1t_i));
	IOBUF QSPI_SCK_TDC  (.O(sck_o),.IO(sck_io),.I(sck_i),.T(sckt_i));
    //IOBUF for Select of Sda
    // IOBUF QSPI_SS_SDA  (.O(ss_o_sda),.IO(ioss_io_sda),.I(ss_i_sda),.T(sst_i_sda));  
    genvar i;
    generate for (i = 0; i < NBR_OF_SLAVE ; i = i + 1) begin: tristate
        IOBUF QSPI_SS_TDC  (.O(ss_o[i]),.IO(ss_io[i]),.I(ss_i[i]),.T(sst_i));
    end
    endgenerate
 
endmodule
