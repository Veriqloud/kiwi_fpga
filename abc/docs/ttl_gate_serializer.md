# TTL gate: 1.0417 ns duty-cycle resolution (test build)

Built 2026-08-29 from kiwi_fpga branch ttl-gate-serializer. Not a release.
Gate confirmed working on alice1/bob1 hardware on 2026-08-30.
The incumbent bit_jul20 bitstream is untouched in this directory.

## What changed
The APD gate is now a 12-bit pattern shifted out by an OSERDESE3 in 4:1 DDR mode
(CLK 480 MHz / CLKDIV 240 MHz, 960 Mb/s). One pattern bit = 1.0417 ns, four
times the old 240 MHz resolution. Duty cycle and tune delay are both bit
positions in that word.

MMCM retuned: VCO 960 MHz -> 240 (/4), 80 (/12, 90 deg), 480 (/2).
fine_delay now runs at 240 MHz (DRC REQP-1743: ODELAY CLK must equal OSERDES
CLKDIV). Its tap-step timing is scaled so existing fine-delay register values
keep their meaning.

## Register change
slv_reg6, base 0x00015000, offset 0x18: gate pattern [11:0].
One bit per 1.0417 ns slot of the 12.5 ns gate period, bit 0 first. The run of
set bits is the duty cycle, its offset is the tune delay.
slv_reg1[22:15] (old duty_val / delay_val) is no longer used.

Write sequence is unchanged: write the pattern, then rising edge on slv_reg2[0]
to latch it into the 240 MHz domain.

Examples:
  0x00F  four bits  -> 4.1667 ns gate (equivalent to the old duty_val = 1)
  0x03F  six bits   -> 6.25 ns gate (not expressible before)
  0x03C  0x00F << 2 -> same width, shifted 2.0833 ns later

## Recalibration
PPS to first gate edge is 6.689 ns (simulated), different from the old
shift-register path. Absolute gate position will need retuning once; the pattern
offset now corrects it in 1.0417 ns steps instead of 4.167 ns.

## Timing
WNS 0.356 ns, WHS 0.011 ns, 0 failing endpoints. All timing constraints met.

## To flash
  cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
  sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper_ttl_serdes.bit
Takes effect at the next power cycle. To go back, flash
Qline_turnkey_top_wrapper.bit from the same directory.
