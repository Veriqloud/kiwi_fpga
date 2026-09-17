## Description new bitstream
`bit_sep17_tdc_phase` plus the PPS edge guard in `ttl_gate_apd`: a `ttl_rst`
released inside the 100 ms pps10 high window no longer starts the gate; it
starts on the next pps10 rising edge. Design note:
`abc/docs/deterministic_latency.md`.

Not yet tested on hardware; `bit_sep17_tdc_phase` is the last tested build.

- Source: kiwi_fpga branch `ttl-gate-serializer`, commit fac2ea3
- Built 2026-09-17 with Vivado 2024.2, `abc/build_all.tcl` + synth/impl to
  write_bitstream
- md5 `1222cd148392a199b997d91212a3a237`
- Timing: WNS 0.409 ns, WHS 0.010 ns, pulse width 0 failing endpoints
  (`timing_summary.rpt`); pps10_o to `ttl_gate_apd` pps_r setup slack 0.164 ns

## Requires
- `kiwi_hw_control` `remote/registers/ltc/Ltc6951Regs.txt` and
  `Ltc6951Expect.txt` with h10 = 0x02.
- Si5319 jitter cleaner (U6) in bypass mode:
  `remote/registers/jit_cleaner/Si5319_regs.txt` first line `0x00,0x16`
  (register 0 BYPASS_REG = 1, written before the ICAL at the end of the file).

## Registers map
### clk_rst (base 0x00012000)
#### timebase status (read-only)
- Offset : 0x24
- [0] locked10, [1] pps10_err, [2] ltc_synced, [3] arm, [4] locked200,
  [5] sysref_err, [15:8] arm_dist (expect 42)
- [24:16] TDC counter phase, expect 0; [25] phase valid

After `init`, `(read(0x12000, 0x24) >> 16) & 0x3ff` reads 0x200 on Bob.

## Flash
    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_ttl_guard.bit
Takes effect at the next power cycle. Roll back by flashing bit_sep17_tdc_phase's
`Qline_turnkey_top_wrapper_tdc_phase.bit` the same way.
