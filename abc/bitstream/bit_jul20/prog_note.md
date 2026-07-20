## Description new bitstream
- Adding tunable probability feature to decoy rng and fastdac rng
- Monitor sticky flags of decoy rng and angle rng : These flags will raise when errors in downstream happen

## Registers map
### Fastdac
#### P0
- Write value P0 for fastdac rng
- Base : 0x00030000
- Offset : 40 (slv_reg10)

#### rng_monitor
- Read sticky flags in register
- Base : 0x00030000
- Offset : 44 (slv_reg11)

#### clear sticky bits
- Write HIGH to register bits to clear the stick flags to 0 state
- Base : 0x00030000
- Offset : 44 (slv_reg11)

|[31:8]|[7:4]|[3:0]|
|------|-----|-----|
|rsv   |raw bits, history of corresponding sticky bits | sticky flags

- bit 0 (raw 4) : E1
- bit 1 (raw 5) : E2
- bit 2 (raw 6) : E3
- bit 3 (raw 7) : E1 for decoy

#### Description of Error
- E1: sticky: rng_ready & (take > ctrl_level)

If entropy starves and ctrl_level hits 0, the take-clamp silently zeroes the buffer and basis_rangedec — which has no valid-input port — keeps decoding rnd_in = 0x00 (rng_ready is sticky, so the reset gate does not re-engage). Output stays present and “valid” but statistically wrong. No presence flag (pair_valid, dout_empty, uneven_empty) catches it.

Latched on the exact take-clamp event, not ctrl_level == 0: a same-cycle refill word can step the level from below take straight to 16, hiding the zero while the decode still ran on zero-fill.

controller.v:88 · implemented: err_ctrl_underrun (rangedec_top_wrapper, clk80)

- E2 is a never-event: the bit_unpacker gate (fifo_rd_en = ~rd_pend &
    ~pfull & ~fifo_empty) makes a read-while-empty impossible; if this
    latches, the fifo_1x2 read contract broke (CDC fault or an edit
    upstream). Also the fabric equivalent of the IP Underflow_Flag.

- E3 latches when the endpoint pops on a tick with a branch not ready --
    dout then holds the PREVIOUS nibble (silent repeat downstream).
    Self-contained: rd_en_4 & ~both_ready, nothing else. NOTE: the
    endpoint (jesd_transport) free-runs rd_en_4 from the first PPS
    edge and ignores dout_empty, so entropy streaming must be up and
    the pipe primed BEFORE rd_en_4 starts ticking -- otherwise E3
    latches at bring-up and every dead tick after it is masked.


### Decoy
- Writevalue P0 for decoy rng
- Base: 0x00016000
- Offset : 16 (slv_reg4)

## Sequence of write P0
- Write register value P0 . for example 3277 corresponding p0 = 0.1
- Write enable register to save value
- Reset rng with fucntion rng_reset() : same as old version

## Sequence of monitor rng
- reset rng, reset decoy 
- clear stick bits by writing 1 to corresponding bits
- start rng services / stop service
Note: can read sticky flags register whenever needed. In normal service, all sticky bits should stay 0. Need to reset rng, reset decoy and clear the flags before monitoring for next session







