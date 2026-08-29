# TTL gate serializer build — how to drive it

Audience: an agent operating alice1/bob1. Read this before touching the APD gate
registers if `Qline_turnkey_top_wrapper_ttl_serdes.bit` is the flashed bitstream.

Built 2026-08-29 from kiwi_fpga branch ttl-gate-serializer. Verified in
simulation, through a full Vivado implementation, and on hardware: the gate is
confirmed working on alice1/bob1 as of 2026-08-30. Duty-cycle tuning was still
in progress at that point, so the pattern values below are starting points, not
a calibrated setting. If behaviour contradicts this document, trust the
hardware and say so.

---

## 1. Read this first: the gate is OFF until you write the pattern

The gate pattern register resets to 0, and a zero pattern means the serializer
emits a constant low. **After flashing, there is no APD gate at all until
something writes slv_reg6.** This is not a fault. The old bitstream had a
non-zero default gate; this one does not.

If you are debugging "no counts / no detector gate" on this bitstream, check
that first.

## 2. What changed

The gate used to be a counter in the 240 MHz domain: duty cycle in whole 4.167 ns
steps, tune delay in whole 4.167 ns steps. It is now a 12-bit pattern shifted out
by an OSERDESE3 at 960 Mb/s. One pattern bit = 1.0417 ns, covering one 12.5 ns
gate period with 12 slots.

Duty cycle and tune delay are no longer separate fields. They are both properties
of the pattern: the run of set bits is the width, its offset is the delay.

The ps-resolution fine delay (ODELAY cascade) is unchanged and still works
exactly as before, including its register fields and calibration values.

## 3. The breaking change

`lib/fpga.py` has:

    def calculate_delay(duty, tune, fine, inc):
        fine_clock_num = fine*16
        transfer = duty<<19|tune<<15|fine_clock_num<<1|inc
        return transfer

    def write_delay_master(duty, tune, fine, inc):
        write(0x15000, 4, calculate_delay(duty, tune, fine, inc))

On this bitstream the `duty` and `tune` arguments are **silently ignored** —
slv_reg1[22:15] is no longer read by the FPGA. The call still succeeds and still
sets the fine delay correctly from `fine` and `inc`. It just no longer changes
the gate width or coarse position.

Do not "fix" this by editing write_delay_master's bit packing. Write the pattern
to slv_reg6 instead, as below.

Note this affects only the TTL gate at base 0x15000. The decoy functions
(`de_write_delay_master`, `de_write_delay_slaves`, base 0x16000) are a different
module and are completely unaffected — their timing is bit-identical to the old
bitstream.

## 4. How to set the gate

slv_reg6, base 0x15000, byte offset 0x18. Bits [11:0].

Bit 0 is the first 1.0417 ns slot of the 12.5 ns period; bit 11 is the last. A
set bit means the gate is high during that slot.

    from lib import fpga

    def write_gate_pattern(pattern):
        """pattern: 12-bit int, one bit per 1.0417 ns slot of the 12.5 ns period."""
        assert 0 <= pattern < (1 << 12)
        fpga.write(0x15000, 0x18, pattern)
        fpga.params_en()        # 0->1 on slv_reg2[0] latches it into the 240 MHz domain

    def gate(width_slots, offset_slots):
        """Contiguous gate: width_slots * 1.0417 ns, starting offset_slots * 1.0417 ns
        into the period. Wraps if offset+width > 12."""
        assert 1 <= width_slots <= 12 and 0 <= offset_slots < 12
        p = ((1 << width_slots) - 1) << offset_slots
        return ((p | (p >> 12)) & 0xFFF)

`params_en()` is unchanged and already does the right thing — it latches
slv_reg1, slv_reg3 and slv_reg6 together on the same 0->1 edge.

### Worked values

    0x00F  = 0b000000001111   4 slots  -> 4.1667 ns, at the period start
                                          (this is what the old duty_val=1 gave)
    0x03F  = 0b000000111111   6 slots  -> 6.2500 ns   (not expressible before)
    0x03C  = 0b000000111100   4 slots  -> 4.1667 ns, shifted 2.0833 ns later
    0x001  = 0b000000000001   1 slot   -> 1.0417 ns   (the new minimum)
    0xFFF                     12 slots -> always high, no gating
    0x000                     no gate at all (the reset value)

Old duty_val N maps to `gate(4*N, 0)`; old tune_val M maps to an offset of 4*M
slots. So the old (duty=1, tune=2) is `gate(4, 8)` = 0xF00.

## 5. Recalibration — expect the gate to be in the wrong place at first

The path from PPS to the output changed, so the absolute gate position moved.
Simulation gives 6.689 ns from the PPS edge to the first gate edge; the old
shift-register path differed. Board propagation and the level translator are not
in that number, so treat it as "expect a shift of a few ns", not a target.

Procedure: set a wide gate first (e.g. `gate(8, 0)` = 0x0FF) so you can find the
detector counts at all, then walk the offset in 1-slot steps to centre it, then
narrow the width. The ODELAY fine delay (`write_delay_master(0, 0, fine, inc)` +
`trigger_fine_master()`) still trims sub-ns on top, unchanged.

## 6. Unchanged — do not re-derive these

- Fine delay: `write_delay_master(0, 0, fine, inc)`, `write_delay_slaves(...)`,
  `trigger_fine_master/slv1/slv2()`. Same registers, same tap timing, same
  calibration values as the old bitstream.
- `params_en()`, base addresses, the write()/read() mmap API.
- Everything outside the TTL gate: decoy, fastdac, RNG, TDC, DDR, JESD.
- Gate period is still 12.5 ns (80 MHz repetition).

## 7. Rollback

The previous bitstream is untouched in this directory as
`Qline_turnkey_top_wrapper.bit` (md5 c6b0fcddade1537d7aa1180b191ac71a, the
bit_jul20 release).

    cd ~/FrontPanel/FrontPanel-Ubuntu22.04LTS-x64-5.3.6/Samples/FlashLoader/Cxx
    sudo ./flashloader w ~/hw_bitstream/Qline_turnkey_top_wrapper.bit

Takes effect at the next power cycle. `Qline_turnkey_top_wrapper_ttl_serdes.ltx`
is the debug-probes file for the new build; the old .ltx will not match it.

## 8. Build facts

WNS 0.356 ns, WHS 0.011 ns, 0 failing endpoints of 223649, all timing
constraints met. MMCM retuned to VCO 960 MHz: 240 (/4), 80 (/12, 90 deg),
480 (/2). The 480 MHz clock is the OSERDESE3 CLK and exists only inside the
gate output path — no fabric logic runs at 480 MHz.
