## Description new bitstream
TTL gate serializer build: the APD gate is a 12-bit pattern shifted out by an
OSERDESE3 at 960 Mb/s, one bit per 1.0417 ns slot of the 12.5 ns period.
Register semantics, calibration procedure and rollback are in
`abc/docs/ttl_gate_howto.md` and `abc/docs/ttl_gate_serializer.md`.

- Source: kiwi_fpga branch `ttl-gate-serializer`, commit 08c713c
- Built 2026-09-12 with Vivado 2024.2, `abc/build_all.tcl` + synth/impl to
  write_bitstream; a rebuild of the 2026-08-29 file that was on alice1/bob1
  (md5 cc83abad…) from the same sources
- md5 `ae1b1aade94f0c3cdaf09a264992e644`
- Timing: WNS 0.356 ns, WHS 0.011 ns, 0 failing endpoints of 223649
  (`timing_summary.rpt`)
- MMCM: VCO 960 MHz -> 240 (/4), 80 (/12, 90 deg), 480 (/2)
- OSERDESE3_pulse at BITSLICE_RX_TX_X0Y41; gate fine delay X0Y40/41, decoy
  fine delay X0Y42/43

## Registers map
### TTL gate (base 0x00015000)
#### gate pattern
- Write the 12-bit pattern, bit 0 = first slot; latched by params_en
  (0->1 on slv_reg2[0]) together with slv_reg1 and slv_reg3
- Offset : 0x18 (slv_reg6)
- Resets to 0 = no gate at all: nothing is gated until something writes it
#### slv_reg1[22:15] (old duty_val / delay_val)
- No longer read; write_delay_master's duty/tune arguments are ignored, its
  fine-delay field is unchanged

## Flash
    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_ttl_serdes.bit
Takes effect at the next power cycle. Roll back by flashing bit_jul20's
`Qline_turnkey_top_wrapper.bit` the same way.
