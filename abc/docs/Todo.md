## Programming note 3 Jul

#### Registers
- Decoy : rdec_p0 : Base of decoy + slv_reg4
- Fastdac : rdec_p0 : Base of fastdac + slv_reg10

#### Reset sequence
- These regs only using in true random mode
- After setting register, toggle rst_rng to start rdec algorithm

## Todo next
- Clean constraints and ilas for better timing analysis
- Check functionality again in detail
- Optimize fifos size. Include fifo 128x16, fifo_1x2, fifo_4x4
- Check flags of fifos to prevent underflow, overflow