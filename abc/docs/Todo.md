## Programming note 3 Jul

#### Registers
- Decoy : rdec_p0 : Base of decoy + slv_reg4
- Fastdac : rdec_p0 : Base of fastdac + slv_reg10

#### Reset sequence
- These regs only using in true random mode
- After setting register, toggle rst_rng to start rdec algorithm

## Todo next
- Check functionality again in detail
- Optimize fifos size. Include fifo 128x16, fifo_1x2
- Implement flags for fifo_1x2. Check flags of fifos to prevent underflow, overflow

## Todo next
- Update monitoring rng fifos : 
 + decoy fifo_128x16, fifo_1x2 (both in rangedec_wrapper)
 + fastdac fifo_128x16 for true rng, both 2 fifos in rangedec_wrapper

- Shrink fifo depth:
 + fifo_128x16 : from 4096 to 128
 + fifo_1x2 : from 1024 to 64
 + fifo_gc_in_64x64 : from 16k to 512

- Write tests function again
- Compare 2 bitstream
