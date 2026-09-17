## Description new bitstream
`bit_sep15_det_latency` plus three changes in `tdc_clk_rst_mngt`, for the TDC
time frame moving across power cycles (`abc/docs/power_cycle_latency_qline1.md`):

- The PPS edge detector no longer fires when `tdc_rst` is released inside the
  100 ms pps200 high window; the refclk/rstidx counters start on the next
  pps200 rising edge.
- `tdc_refclk` and `tdc_rstidx` are driven from flops, same clk200 cycle timing
  as before.
- Counter phase readback in the timebase status register (below).

- Source: kiwi_fpga branch `ttl-gate-serializer`, uncommitted working tree on top
  of 08c713c
- Built 2026-09-17 with Vivado 2024.2, `abc/build_all.tcl` + synth/impl to
  write_bitstream
- md5 `d0e232cc030c0f83d2de351fced7b5b7`
- Timing: WNS 0.409 ns, WHS 0.010 ns, pulse width 0 failing endpoints
  (`timing_summary.rpt`)

## Requires
- `kiwi_hw_control` `remote/registers/ltc/Ltc6951Regs.txt` and
  `Ltc6951Expect.txt` with h10 = 0x02, as for `bit_sep15_det_latency`.
- Si5319 jitter cleaner (U6) in bypass mode:
  `remote/registers/jit_cleaner/Si5319_regs.txt` first line `0x00,0x16`
  (register 0 BYPASS_REG = 1, written before the ICAL at the end of the file).
  U6 sits between the FPGA `tdc_refclk` and the AS6501 REFCLK. With its PLL
  active the input-to-output skew is not controlled, and the TDC time frame
  moves by whole Si5319 VCO periods (206 ps) on some power cycles.

## Registers map
### clk_rst (base 0x00012000)
#### timebase status (read-only)
- Offset : 0x24
- [0] locked10, [1] pps10_err, [2] ltc_synced, [3] arm, [4] locked200,
  [5] sysref_err, [15:8] arm_dist (expect 42)
- [24:16] TDC counter phase: clk200 cycles from the start of the refclk/rstidx
  counters to the last pps200 edge, mod 320. Expect 0.
- [25] phase valid, from the second pps200 edge after `tdc_rst` (`Reset_Tdc()`)

Read after `init` on every boot, e.g. `(read(0x12000, 0x24) >> 16) & 0x3ff`:
0x200 means valid with phase 0. A nonzero phase is the start offset of that
boot's TDC frame.

## Flash
    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_tdc_phase.bit
Takes effect at the next power cycle. Roll back by flashing bit_sep15_det_latency's
`Qline_turnkey_top_wrapper_det_latency.bit` the same way.
