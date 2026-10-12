// behavioural stand-in for the fifo_gc_in_64x64 IP (standard read, valid flag)
module fifo_gc_in_64x64(input rst, input wr_clk, input rd_clk, input [63:0] din, input wr_en,
    input rd_en, output reg [63:0] dout, output full, output almost_full, output empty,
    output almost_empty, output reg valid, output prog_full, output prog_empty,
    output wr_rst_busy, output rd_rst_busy);
  reg [63:0] mem [0:16383]; reg [14:0] wp, rp;
  assign empty = (wp==rp); assign full = (wp-rp)==16384;
  assign almost_full=0, almost_empty=0, prog_full=0, prog_empty=0, wr_rst_busy=0, rd_rst_busy=0;
  always @(posedge wr_clk) if (rst) wp<=0; else if (wr_en && !full) begin mem[wp[13:0]]<=din; wp<=wp+1; end
  always @(posedge rd_clk) if (rst) begin rp<=0; valid<=0; dout<=0; end
    else begin valid<=0; if (rd_en && !empty) begin dout<=mem[rp[13:0]]; rp<=rp+1; valid<=1; end end
endmodule
