## Integrate angles_top_wrapper

### Currently in module
I have module jesd_tranport.v
Line 303 to 361 include 2 fifos for RNG datapath from AXIS to rng_dout4 output at rd_en_4 tick and logic to control when to enable writing side of fifo_128x16 to prevent overflow

### What to implement
I have module angles_top_wrapper.v is supposed to replace logic written from line 303 to 361 in jesd_tranport.v  based on proposed architecture. The purpose is adding range decode in the path of RNG

- Comment out line 303 to 361 instead of overwrite
- Read relevant RTL modules
- Suggest correction to make sure fucntionality is kept
- Make sure fifos is controlled to prevent underflow or overflow
- Consider correct clock domains
- Make sure rng_dout4 is captured with rd_en_4 under 200MHz clock domain
- Name signals to match with others parts of code in jesd_transport.v

### Improve
- Improve module angles_top_wrapper.v and submodules
- Fifo_up_true_wrapper : got rd_en signal from external port which called rd_en_16. this rd_en_16 is tick 10MHz in clk200 domain, rising edge the same with rd_en_4
- Improve bit_unpacker : expected output is 2 bits lasts for 5 cycles of clk200. check pair[1:0] on simulation waveform. The "pair" should not be reset to 0 or change at random cycle. This is to make sure when combine 2 paths to 1 path with 4 bits of data, it's not glitch and combine data with zero or with previous value.
- Adapt testbench 
