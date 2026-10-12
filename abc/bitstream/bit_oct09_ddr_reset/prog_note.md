## Description new bitstream
`bit_sep17_tdc_phase` plus DDR path reset, quiesce and integrity checks
(`abc/docs/monitoring.md` section 7):

- `ddr_axi_reset_seq` (clk_rst_mngt): the DDR path reset (0x12000 offset 0x10)
  also resets the MIG AXI shim (`c0_ddr4_aresetn`) and the M side of the AXI
  clock converter. M side released first, then the S side. No DDR4
  recalibration.
- `ddr_data`: m_axis waits for tready (drops counted); `start_write` held low
  for 1.31 ms stops the writer at a 16-word packet boundary; `quiesced` status;
  word index in bits [7:6] of each DDR byte, checked on read (`slip`); the
  reader answers a lookup whose word was already consumed from the last word
  read, or with alpha/decoy 0 and nibble bit 3 set when the word is further
  back, instead of draining the vfifo.
- `axi_virtual_controller_wrapper`: m_axi idle detector and W beat counter.

- Source: kiwi_fpga branch `ttl-gate-serializer`, commit 4108745
- Built 2026-10-09 with Vivado 2024.2, `abc/build_all.tcl` + synth/impl to
  write_bitstream (`-bin_file`)
- md5 `0650cdd209f743b0e493345fb9a9085a` (.bit)
- Timing: WNS 0.331 ns, WHS 0.010 ns, pulse width 0 failing endpoints
  (`timing_summary.rpt`)

## Requires
Same as `bit_sep17_tdc_phase` (Ltc6951 h10 = 0x02, Si5319 in bypass).

Host side, page 0x1000 (register map is a superset of `bit_sep17_tdc_phase`):
- At session stop write 0 to offset 0x00 (`start_write`).
- Before `Ddr.init` poll 0x34 bit 11 (`quiesced`), up to ~100 ms, then reset.
- Log 0x34 bits [18:11] and 0x44 before each `Ddr.init`.

## Registers map
### ddr_data (base 0x00001000)
#### 0x34 ddr fifo status, new bits (read-only)
- [11] quiesced, [12] wr_stopped, [13] axi_quiet, [14] err_passed (sticky),
  [15] wr_drop (sticky), [16] slip (sticky), [17] stop_req (sticky),
  [18] wr_drained, [31:24] slip_delta (embedded index − read_count, last
  mismatch, mod 256)
#### 0x44 counters (new, read-only)
- [15:0] write drops, [31:16] lookups answered by the escape; both saturating

## Flash
    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_ddr_reset.bit
Takes effect at the next power cycle. Roll back by flashing bit_sep17_tdc_phase's
`Qline_turnkey_top_wrapper_tdc_phase.bit` the same way.
