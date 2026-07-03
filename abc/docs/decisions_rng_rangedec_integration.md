# Range-decoder RNG integration — decisions & summary

Working log of the design decisions made while integrating the biased-RNG
range decoder into the two consumer datapaths (**decoy** and **fastdac/jesd**).
Kept for future discussion; see linked source files for the implementation.

Related docs: [architecture.md](architecture.md) (mixed-distribution output),
[context.md](context.md) (decoy integration notes),
[context_jesd.md](context_jesd.md) (jesd integration request).

---

## 1. Modules & datapath overview

Biased-RNG core (shared): `srcs/common/rng_rangedec/`
- `basis_rangedec.v` — Bernoulli(p) bit generator (range decoder used as sampler).
  Verified bit-exact vs C golden model. Consumes ~0.469 uniform bits/symbol at p=0.1.
- `controller.v` — 16b prefetch buffer -> 8b `rnd_in`, drives FIFO reads.
- `fifo_up_wrapper.v` — async 128->16 entropy FIFO (write @producer, read @clk80).
- `fifo_uneven_1x2_wrapper.v` — async 1->2 FIFO (write basis_bit @clk80, read 2b @clk200).
- `rangedec_top_wrapper.v` — chains the above: entropy -> controller -> decoder ->
  uneven FIFO -> `uneven_dout[1:0]` @clk200.

Two integration tops:
- **decoy**: `srcs/decoy/decoy_rng_fifos.v` instantiates `rangedec_top_wrapper`,
  outputs `de_rng_dout2[1:0]` -> `decoy.v` `rng_value`.
- **fastdac/jesd**: `srcs/fastdac/rdec/angles_top_wrapper.v` (mixed-distribution:
  even/true path + uneven/basis path recombined to `dout[3:0]` {E,U,E,U} @40 MHz),
  instantiated in `srcs/fastdac/jesd_trans/jesd_transport.v`.

Clock domains: producer (wr/s_axis, 250 MHz) / **clk80** (basis processing) /
**clk200** (output, = `tx_core_clk` in jesd). `rst` async active-high to FIFOs.

---

## 2. Debug finding: decoy `rng_a_r` stuck at constant "2"

Symptom: `rng_a_r` read a constant `2` even with `decoy_rng_mode` set to 1.

**Root cause (confirmed):** the mux `rng_a = decoy_rng_mode_r ? rng_value : dpram_rng_dout`
was taking the **DPRAM branch** — `decoy_rng_mode_r` was still 0. `decoy_rng_sequence.mem[0]`
low bits = `2'b10` = 2, and the DPRAM read address is pps-gated (stuck at 0) → constant 2.

**Why the mode bit didn't apply:** `decoy_rng_mode_r` only latches on a **rising edge of
`reg_enable_o`** (`decoy.v`). Writing the mode register while enable was already high
produced no edge → the new value never latched.

**Decision / rule:** to change any handshake-latched config, write the value **then**
pulse `reg_enable` low→high. This applies to `decoy_rng_mode`, `P0`, and every
`reg_enable`-latched field. Documented so it isn't rediscovered.

**Secondary (noted, not the freeze cause):** `fifo_1x2` is a **Standard FIFO** (`Valid_Flag=false`),
so `dout` is valid **1 read-clock cycle after** `rd_en`. The decoy capture samples `rng_a`
on the `rd_en_4` rising edge → grabs the pre-read (off-by-one) word once real data flows.
Fix later by either regenerating the FIFO as **FWFT** or delaying the decoy capture one cycle.

---

## 3. Decision: `P0` is a runtime register, not a parameter

`P0` (Bernoulli threshold, Q15; 3277/2^15 ≈ 0.1) changed from a compile-time
`parameter` to a runtime input `p0_i` / `rdec_p0_i`, propagated:
`basis_rangedec.p0_i` <- `rangedec_top_wrapper.rdec_p0_i` <- top (`decoy_rng_fifos` /
`angles_top_wrapper`). `PREC` stays a parameter (structural precision, not a runtime knob).

Files: `basis_rangedec.v`, `rangedec_top_wrapper.v`, `angles_top_wrapper.v`,
`decoy_rng_fifos.v`, plus testbenches (`rangedec_top_wrapper_tb.v`,
`angles_top_wrapper_tb.v` drive the port with a constant).

### 3a. CDC decision: **live-safe**, latched in the destination clk80 domain

`P0` crosses from the AXIL clock domain into clk80. A plain multi-bit 2-FF
synchronizer is **CDC-unsafe** (Vivado `report_cdc` warns: multi-bit bus through
ASYNC_REG → bit-skew/incoherence). We chose the **stable-source + synchronized
load-enable** pattern (Vivado-recognized safe):

- The raw AXIL value (`rdec_p0_o`) is held stable in the AXIL domain.
- A single-bit `reg_enable` is synchronized into clk80 (3-FF ASYNC_REG + rising-edge
  detect); the **whole 16-bit bus is latched at once** on that edge → `rdec_p0_r`.
- `rangedec_top_wrapper` therefore treats `rdec_p0_i` as **already clk80-synchronous**
  (no internal CDC); it feeds `basis_rangedec.p0_i` directly.

Implemented in both paths:
- **decoy**: `decoy_axil_mngt.v` (`rdec_p0_o = slv_reg4[15:0]`) → `decoy.v` latches into
  `rdec_p0_r` on the existing `reg_enable` clk80 handshake → BD → `decoy_rng_fifos.rdec_p0_i`.
- **fastdac/jesd**: `fastdac_axil_mngt.v` (`rdec_p0_o = slv_reg10[15:0]`, addr `4'hA`) →
  `jesd_transport.v` latches into `rdec_p0_r` via a new `reg_en_80_r` clk80 handshake →
  `angles_rng_inst.rdec_p0_i`.

**Open item:** each crossing needs an XDC `set_max_delay -datapath_only` on
`slv_regN_reg[*] -> rdec_p0_r_reg[*]` (extend any existing blanket CDC constraint on the
`reg_enable`-latched regs). If live P0 retuning while streaming matters, note that a value
change applies to the next decoded symbol with no glitch (latched atomically).

---

## 4. jesd_transport integration (angles_top_wrapper replaces the 2-FIFO RNG path)

Replaced the old `fifo_128x16` + `fifo_16x4` pair (RNG stream → `rng_dout4` @40 MHz)
with one `angles_top_wrapper`. Old code **commented out** (not deleted) for reference.

Decisions taken (answers to open questions):
1. **clk80**: added a **real `clk80` input port** to `jesd_transport` (not reusing
   `tx_core_clk`). Needs BD wiring of an 80 MHz clock. (decoy reuses clk200 as clk80;
   jesd uses a dedicated 80 MHz.)
2. **P0 source**: initially constant `16'd3277`, then upgraded to the AXIL
   `slv_reg10` + clk80 handshake (§3a).
3. **FIFO status**: the even/true `fifo_up_true_wrapper` (128->16) is the analog of the
   old `fifo_128x16`. Its `almost_full`/`empty` are exposed from `angles_top_wrapper`
   (`even_almost_full`/`even_empty`) and remapped to the **legacy signal names**
   `almost_full_16`/`empty_16`, still feeding `rng_fifo_status`.

Signal continuity:
- `dout → rng_dout4` (feeds `rng_value` mux), read timing preserved (both old and new
  output FIFOs are Standard FIFO, 1-cycle read latency; old `valid` flag was unused).
- `s_axis_tready` now driven by the wrapper (both-branches-full); the debug output
  `tready_flag` re-driven as `assign tready_flag = s_axis_tready`.
- `s_axis_tkeep/tlast` tied off (`16'hFFFF`/`1'b0`) — wrapper ignores them.
- `rd_en_16`/`rd_en_16_de` counter logic kept (they are module outputs / decoy-path).

Testbench: `jesd_transport_tb.v` gained an 80 MHz `clk80` generator + wiring.
**Open item:** tb must AXI-write `slv_reg10` (P0) and pulse `reg_en` before RNG-stats
checks, else `rdec_p0_r`=0 → decoder emits all-ones.

---

## 5. Decision: overflow control gates on `almost_full` (headroom), not `full`

Concern raised: `angles` arbiter originally gated `can`/`wr_en` on `full`, whereas the
proven old `fifo_128x16` gated on `almost_full` for headroom.

**Decision:** arbiter accepts new beats only while a branch is **NOT almost-full**
(`up_can = ~up_almost_full`, `tr_can = ~tr_almost_full`), leaving write headroom so the
FIFO never reaches `full`. `s_axis_tready` deasserts only when **both** are almost-full.
`full` kept as a **hard combinational backstop** on each `wr_en` (belt-and-suspenders).

Requires both entropy FIFOs' `almost_full` to be enabled (with a sane threshold) in their
IP config — `fifo_up_true` and rangedec's `fifo_up`. **Open item: confirm in the `.xci`.**

Underflow: relies on source over-production (160 > 80 + 37.5 Mbit/s); output `fifo_4x4`
stays fed. `dout_empty` is available (currently unused) to gate downstream if a hard
underflow guard is wanted.

---

## 6. ILA

`ip/ila_rdec` instantiated in `rangedec_top_wrapper` (clk80): probes the upstream-FIFO
read side, the range-decoder handshake, and `uneven_dout` (the last two probes sample
`uneven_dout`/`uneven_empty` from clk200 asynchronously — debug-only, CDC-unsafe).

---

## 7. Open items checklist

- [ ] XDC `set_max_delay -datapath_only` on `slv_regN -> rdec_p0_r` in **both** paths.
- [ ] Re-package IPs with new ports (`clk80`, `rdec_p0_*`) and wire `clk80` + P0 reg in the BD.
- [ ] Confirm `almost_full` enabled in `fifo_up_true` and `fifo_up` `.xci`.
- [ ] Decide FWFT vs delayed-capture for the Standard-FIFO 1-cycle read latency (decoy `rng_a_r`, §2).
- [ ] `jesd_transport_tb`: add AXI write of `slv_reg10` (P0) + `reg_en` pulse.
- [ ] Optional: wire `dout_empty` into downstream `rd_en` gating for a hard underflow guard.
- [ ] Remember: **write config value, THEN pulse `reg_enable`** (§2) — applies to all latched regs.
