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

## Todo
- Check again the decoy
- make sure timing and fucntion of decoy correct

## Wrap up 15 Jul
- Modify decoy.v , shift 2 more sync step for rd_en_4_r, from 2 to 4. 
- Modify temp_sig1/2 high state corresponding to case of rng_a_r
- Adding constraint set_max_delay -datapath only for rd_en_4_r and rng_a_r
- Timing summary clean, cdc report lefts unknown paths for rd_en_4_r, unsafe paths for decoy ila, async reset to fifo_1x2, fifo_128x16, known path for jesd. They are known and can be ignored
