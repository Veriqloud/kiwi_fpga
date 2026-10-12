## Description new bitstream
`bit_oct09_ddr_reset` plus the decoy bit order in the DDR record:

- `ddr_data`: the decoy bits are packed as `{rng_a_data[0], rng_a_data[1]}` in
  bits [5:4] of each DDR byte, so bit 5 is the first pulse of the gc as
  `rng_data[3:2]` is. The decoy lookup returns the decoy bit of the pulse whose
  angle the angle lookup returns at the same delay.
- Testbench `sim/ddr_path/ddr_data_lookup_tb.v` checks the decoy bit per pulse
  for clicks in both halves of the gc (MODE 0: 48/48).

- Source: kiwi_fpga branch `ttl-gate-serializer`, commit 2688a27 plus the
  `ddr_data.v` change
- Built 2026-10-12 with Vivado 2024.2, `abc/build_all.tcl` + synth/impl to
  write_bitstream (`-bin_file`)
- md5 `b9ff34fdcb351261995b2698cf99fc3a` (.bit)
- Timing: WNS 0.321 ns, WHS 0.010 ns, pulse width 0 failing endpoints
  (`timing_summary.rpt`)

## Requires
Same as `bit_oct09_ddr_reset`; register map unchanged.

`decoy_fiber_delay` moves: one setting gives the full decoy contrast, about one
period off the two half-contrast settings of the earlier bitstreams (3976/3978
on qline1 at `decoy_delay` 6250 -> about 3977). Rerun `find_decoy_delay`.

## Flash
    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_decoy_order.bit
Takes effect at the next power cycle. Roll back by flashing bit_oct09_ddr_reset's
`Qline_turnkey_top_wrapper_ddr_reset.bit` the same way.
