## Description new bitstream
Deterministic DAC-to-gate latency: PPS is sampled once (`pps_timebase`, clk10
falling edge), the LTC6951 SYNC and both clock trees take their second epoch
from it, SYSREF is captured by one timed flop, and the decoy RNG crosses into
clk240 through a symbol-indexed table. Design, registers and bring-up checks are
in `abc/docs/deterministic_latency.md`. Includes the TTL gate serializer build.

- Source: kiwi_fpga branch `ttl-gate-serializer`, uncommitted working tree on top
  of 08c713c
- Built 2026-09-15 with Vivado 2024.2, `abc/build_all.tcl` + synth/impl to
  write_bitstream
- md5 `d983dbb0041bfd2fbd98856ee9d169c3`
- Timing: WNS 0.321 ns, WHS 0.010 ns, pulse width 0 failing endpoints
  (`timing_summary.rpt`)
- MMCM: VCO 960 MHz -> 240 (/4), 80 (/12, 90 deg), 480 (/2), 240 (/4, 56.25 deg,
  TTL serializer CLKDIV only)

## Requires
`kiwi_hw_control` `remote/registers/ltc/Ltc6951Regs.txt` and
`Ltc6951Expect.txt` with h10 = 0x02 (LTC6951 OUT3 delay 2). With the old value
0x06 FPGA SYSREF lands on a refclk edge.

## Registers map
### clk_rst (base 0x00012000)
#### timebase configuration
- Offset : 0x20 (slv_reg8)
- [7:0] arm_cnt, reset 16
- [23:8] pps200_preset, reset 364
#### timebase status (read-only)
- Offset : 0x24
- [0] locked10, [1] pps10_err, [2] ltc_synced, [3] arm, [4] locked200,
  [5] sysref_err, [15:8] arm_dist (expect 42)

`Sync_Ltc()` is unchanged. Gate, DAC and decoy positions need one recalibration.

## Flash
    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_det_latency.bit
Takes effect at the next power cycle. Roll back by flashing bit_sep12_ttl_serdes's
`Qline_turnkey_top_wrapper_ttl_serdes.bit` the same way.
