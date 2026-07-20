# Monitoring / Status & Error Flags — RNG datapath

Scope: which status/error flags are meaningful to monitor for correct operation
of the biased-RNG datapath (`angles_top_wrapper`, `rangedec_top_wrapper`, their
FIFOs, `controller`, `basis_rangedec`, `bit_unpacker`), and where output can be
corrupted *silently* (no flag exists).

Device: Xilinx XCAU25P (Opalkelly XEM8310). Tool: Vivado 2024.2.

**Revised 2026-07-15** after a design review, verified against the RTL:
- the fifo2 / nibble-assembler stage described in architecture.md **no longer
  exists** — recombine is a registered nibble capture (architecture.md is stale
  on this point);
- the error-detector set was settled as E1–E4 below (E4 redefined: a
  `tvalid & ~tready` sticky was rejected — see §2.4);
- live status was minimized to two 1-bit signals for CDC/timing safety (§3).

Related: [architecture.md](architecture.md) (recombine section outdated),
[timing_reset_cdc_summary.md](timing_reset_cdc_summary.md).

Diagram (interactive monitor map, badges E1–E4 / S1–S2 / A1 pinned on the
datapath): <https://claude.ai/code/artifact/5bc12398-2214-4746-b7dd-5b2aa07a304a>

---

## 1. Datapath recap (as in RTL)

```
XDMA H2C entropy 128b @ s_axis_aclk (250 MHz), AXI4-S slave (tkeep/tlast ignored)
  ── arbiter (weighted RR: 1-of-3 beats prefers basis; redirect-on-full) ──┐
  ├─► even/true path  : fifo_up_true (128->16 async) ─ rd @clk200 ─► bit_unpacker(IN_W=16)
  └─► uneven/basis path: rangedec_top_wrapper
         fifo_up (128->16 async) ─ rd @clk80
         └─► controller (64b shift buffer, prefetch) ── rnd_in[7:0] ──┐
             ▲ take (forced 0 until rng_ready)                        │
             └────────────── basis_rangedec (held in rst until rng_ready)
                     basis_bit 1b @clk80
                     └─► fifo_uneven (fifo_1x2, 1->2 async) ─ rd @clk200 ─► bit_unpacker(IN_W=2)
  recombine @clk200 (NO output FIFO): pop = rd_en_4 & both_ready
    -> 2-stage register (matches legacy fifo_16x4 latency)
    -> dout[3:0] = {E,U,E,U}, valid 2 clk200 cycles after rd_en_4
    -> consumed by jesd_transport (samples via rd_en_4_shift)
```

Clock domains: `s_axis_aclk` 250 MHz (entropy write) / `clk80` (controller +
basis_rangedec, fifo_up read, fifo_uneven write) / `clk200` (fifo read sides +
nibble capture; `rd_en_4` = 40 MHz strobe). Resets arrive pre-synchronized per
domain (`rst_clk250/80/200` from clk_rst_mngt).

**Design philosophy:** overflow/underflow are made *structurally impossible*
(reads gated on `~empty`, writes gated on `~almost_full & ~full & ~wr_rst_busy`).
So the raw `full`/`empty` flags are mostly **status**, not **errors**. The two
places output can be silently corrupted have **no flag at all** — those are what
actually need watching.

**Backpressure is normal:** the source over-produces by design
(160 > 80 + 37.5 Mbit/s); surplus is shed via `s_axis_tready`
(`= ~up_almost_full | ~tr_almost_full`, `angles_top_wrapper.v:141-147`). Any
monitor that treats refused beats as an error will fire in healthy operation
(see §2.4).

**IP flag availability:** neither FIFO generates `overflow`/`underflow`
(`C_HAS_OVERFLOW = C_HAS_UNDERFLOW = 0`, e.g. `ip/fifo_1x2/fifo_1x2.xci:197,202`).
`fifo_up_true_wrapper` *does* bring out `wr_data_count[11:0]` /
`rd_data_count[14:0]` — left unconnected at the top
(`angles_top_wrapper.v:212,218`). The basis entropy wrapper (`fifo_up_wrapper`)
does not expose counts; `fifo_1x2` has none.

**Port exposure today:** `s_axis_tready`, `dout_empty`, `even_almost_full/empty`,
`up_almost_full/up_empty`, `uneven_almost_full/empty` are on `angles_top_wrapper`
ports. `ctrl_level`, `rng_ready`, `basis_valid` are **internal to
rangedec_top_wrapper** — the register bits that need them require new output
ports (`rangedec_top_wrapper` → `angles_top_wrapper`).

---

## 2. Sticky error detectors — implemented 2026-07-16

One flop each, latched in the signal's native domain. These are the only
signals that catch actual corruption; every FIFO flag is secondary to them.

**Status: in RTL.** Exposed as output ports `err_ctrl_underrun` (on both
wrappers), `err_uneven_gate`, `err_endpoint_ovread` (on `angles_top_wrapper`),
and `de_err_ctrl_underrun` (decoy-path E1, on `decoy_rng_fifos`). Verified in
behavioral sim (xsim `tb_err_flags`: healthy run all clear; drain → E3 then
E1; E2 never). The E4 entropy-stall watchdog was removed 2026-07-17 (§2.4);
its register bit now carries the decoy-path E1.

### 2.1 E1 — controller entropy underrun  ⚠ NO FLAG — #1 hazard
```
sticky: rng_ready & (take > ctrl_level)      // latch in clk80
```
`controller.bits_level` (`ctrl_level`) is the buffer fill (0..64). If entropy
starves, the take-clamp (`controller.v:88`, `if (take >= bits_avail)`)
*silently* zeroes the buffer, and `basis_rangedec` — which has **no
valid-input port** — keeps decoding `rnd_in = 0x00` (`rng_ready` is sticky, so
the reset gate does not re-engage). Output stays present and "valid" but
**statistically wrong**. No presence flag (`pair_valid`, `dout_empty`,
`uneven_empty`) catches it.

Implementation note: the latch condition is `take > ctrl_level` — the exact
clamp event — not `ctrl_level == 0`: a same-cycle refill word can step
`bits_level` from `< take` straight to 16, hiding the zero while the decode
still ran on zero-fill.

### 2.2 E2 — uneven read-gate never-event
```
sticky: uneven_empty & uneven_rd_en          // latch in clk200
```
Verifies the `bit_unpacker` read gate holds
(`bit_unpacker.v:79`: `fifo_rd_en = ~rd_pend & ~pfull & ~fifo_empty`). Must
never fire; if it does, the fifo_1x2 read contract broke. Assertion in
hardware, not a live alarm.

*Interchangeable with regenerating fifo_1x2 with `Underflow_Flag`*
(`C_HAS_UNDERFLOW = 1`): the IP flag is exactly rd_en-while-empty at the same
`rd_clk`. It is a per-read pulse, so the sticky latch is still needed either
way — the fabric AND is cheaper unless the IP is being regenerated anyway.

### 2.3 E3 — endpoint over-read
```
sticky: rd_en_4 & ~both_ready                // latch in clk200
```
The endpoint asked for a nibble on a tick when both pairs weren't ready
(`dout_empty = ~both_ready`). The internal pop already gates on `both_ready`
(`pop = rd_en_4 & both_ready`), so this catches `jesd_transport` sampling a
dead tick — on a missed pop, `dout` holds the **previous** nibble (silent
repeat).

Simplified 2026-07-17: the 16-consecutive-pops arming was removed; the flag is
self-contained (`rd_en_4`, `both_ready` only). This makes bring-up ordering a
**requirement**: `jesd_transport` free-runs `rd_en_4` from the first PPS edge
and ignores `dout_empty`, so entropy streaming must be up and the pipe primed
*before* the read cadence starts — start entropy, wait for S2 `rng_ready`
(fifo_1x2 then pre-fills to full, giving a permanent cushion), then start
PPS/reads. If reads start first, E3 latches at bring-up and masks every later
dead tick. (The old arming tolerated the ~10 expected dead ticks right after
priming when reads begin immediately, as the tb does — with the pre-fill
ordering above those dead ticks do not occur.)

### 2.4 E4 — entropy stall watchdog  **(REMOVED 2026-07-17)**

Removed from `angles_top_wrapper` (watchdog logic, `STALL_LIMIT` parameter and
`err_ent_stall` port). In practice the host feeds entropy in finite bursts, so
any pause > STALL_LIMIT latched the sticky and it read 1 in essentially every
run — no information beyond what E1 already gives (E1 fires when the drain
actually reaches the decoder). Register bit 3 now carries the **decoy path's
E1** (`de_err_ctrl_underrun` from the `rangedec_top_wrapper` inside
`decoy_rng_fifos`, native clk80, synced in `rng_monitor`), so both range
decoders are covered by the same authoritative corruption detector.

(History: E4 was itself the replacement for a rejected `tvalid & ~tready`
sticky — refused beats are normal here (over-produce + shed by backpressure).
If a stream-liveness flag is ever wanted again, prefer a *non-sticky* level —
counter saturates, self-clears on the next accepted beat — sized well above
the natural 1.6–3.4 µs saturated-beat spacing.)

---

## 3. Live status — minimized set (decision 2026-07-15)

**Timing principle:** the hazard is not the flag count but *what crosses clock
domains*. Fast-changing multi-bit buses (`ctrl_level[6:0]`, data counts) need
gray coding or a capture handshake; **quasi-static 1-bit signals latched in
their native domain cross with a plain 2-FF synchronizer (`ASYNC_REG`)** and
need nothing else. So: keep two 1-bit signals, cut the rest from the permanent
register.

### Keep

| # | Signal | Why | CDC cost |
|---|--------|-----|----------|
| S1 | `ctrl_low` = sticky `rng_ready & (ctrl_level < LOW_TH)` (e.g. 16), clk80 | E1's early warning as one bit — replaces the live 7-bit `ctrl_level` bus (worst CDC candidate: changes every clk80 cycle) | 1b sticky, trivial |
| S2 | `rng_ready`, clk80 | One-shot bring-up check: asserts once at `ctrl_level >= PRIME_BITS = 32` and stays (`rangedec_top_wrapper.v:152-159`); until then `basis_rangedec` is held in reset with `take` forced 0. Never asserts → no biased output ever. | 1b monotonic, trivial |

`basis_valid` (`rdec_valid`) trails `rng_ready` by the decoder's 32-bit prime
and adds nothing — cut.

### Cut from the register (lab / ILA telemetry only)

| Signal | Why cut |
|--------|---------|
| `ctrl_level[6:0]` live | 7-bit fast bus; S1 + E1 carry the information. Full waveform: clk80 ILA (`ila_rdec` stub, `rangedec_top_wrapper.v:231`). |
| `up_empty` duty | Starvation does its damage at the controller, where S1/E1 catch it; a duty readout needs a counter + multi-bit crossing. |
| `dout_empty` live | An async snapshot of a per-40MHz-tick signal is meaningless at AXI read time; "did a dead tick ever happen" is exactly E3. (The port exists and costs nothing — just don't sync it into the register.) |
| `s_axis_tready` duty | Low duty is normal by design; the failure mode is E4's watchdog. |
| `wr/rd_data_count` | Free-running 12/15-bit binary counts must never be sampled across domains without gray/handshake — the biggest timing liability on the list, for margin telemetry only. |

---

## 4. Reset / bring-up hygiene (minor)

- Resets arrive pre-synchronized per domain (`rst_clk250/80/200`); do not
  re-synchronize locally.
- `uneven_wr_rst_busy` is correctly folded into `uneven_wr_en`
  (`rangedec_top_wrapper.v:200`) — good.
- `rd_rst_busy` on the FIFOs is unused; covered because `fifo_1x2` has
  `Full_Flags_Reset_Value = 1` (full asserted during reset → blocks writes) and
  all readers gate on `~empty`.
- The entropy FIFO write side does not gate on `wr_rst_busy`, so entropy written
  during the reset window is lost (minor — lost entropy only).

---

## 5. No runtime flag — worth a sim assertion

- **`basis_rangedec` has no under-run / valid-input detector** — it trusts
  `rnd_in` is always fresh; its only guard is the upstream `rng_ready` gate.
  Nothing to monitor inside it; E1/S1 (§2.1, §3) are the real health signals.
- **`rdec_p0_i` / `PREC` config correctness:** the single-cycle renorm assumes
  shift `s <= 8` (`basis_rangedec.v:93-101`; true for p=0.1 where
  `s ∈ {0,1,3,4}`). p0 is now a **runtime register**, so a value that lets
  `r_sel` need `s > 8` breaks `take`/`c_norm` silently. Add `assert(s <= 8)` in
  the testbench **and guard the value where the p0 register is written**.

---

## 6. Health register — minimal, one AXI byte

Six flags, every one 1-bit and quasi-static (sticky or monotonic). Bits
`[3:0]` exist as `err_*` ports on `angles_top_wrapper` since 2026-07-16;
`[5:4]` still need ports routed out.

| bit | flag | kind | native domain |
|-----|------|------|---------------|
| 7:6 | reserved | — | — |
| 5 | S1 `ctrl_low` | sticky | clk80 |
| 4 | S2 `rng_ready` | monotonic | clk80 |
| 3 | decoy E1 controller underrun (`de_err_ctrl_underrun`; was E4, removed) | sticky | clk80 |
| 2 | E3 endpoint over-read | sticky | clk200 |
| 1 | E2 read-gate violation | sticky | clk200 |
| 0 | E1 controller underrun | sticky | clk80 |

Implementation:
- Latch each bit **in its native domain** (E1/S1/S2 inside
  `rangedec_top_wrapper`; E2/E3 at `angles_top_wrapper` in clk200; decoy E1
  inside the decoy's `rangedec_top_wrapper` in clk80, exported raw on
  `decoy_rng_fifos.de_err_ctrl_underrun`). Route the latched bits out as
  new ports.
- **`rng_monitor.v`** (srcs/common/rng_rangedec/, instantiated in
  `jesd_transport` @ s_axil_aclk since 2026-07-16) handles the register side:
  per-bit 2-FF sync (`cdc_sync_single`, `ASYNC_REG`) plus a W1C sticky layer.
  Two views: `err_raw_o` = upstream latch level ("fired since datapath
  reset", clears only with the datapath domain reset); `err_sticky_o` = W1C
  "fired since last clear" (edge-set, set dominates clear, re-arms only on a
  new upstream latch). Verified in sim: sync-follow, W1C clear, no re-latch.
- **AXIL register (done 2026-07-17): byte offset `0x2C`** (slot 4'hB in
  `fastdac_axil_mngt`, first free slot after `slv_reg10` @ 0x28). Read:
  `[7:4]` = raw view, `[3:0]` = W1C sticky, each nibble ordered
  {decoy E1, E3, E2, E1}. Write: W1C — `wdata[3:0]` bits written 1 pulse
  `rng_err_clr` for one cycle (no slv_reg storage; the state lives in
  `rng_monitor`). Host usage: read `0x2C`; write `0xF` to `0x2C` to clear
  all sticky bits. Verified closed-loop in sim (AXIL BFM → register →
  rng_monitor → readback: set → 0x11, W1C → 0x10, decode selectivity vs
  0x28, no re-latch).

Triage: `[0]` latched → angles output has been statistically wrong since it
fired; `[3]` latched → same, for the decoy path. `[1]`/`[2]` latching means an
RTL contract broke, not a rate problem.

Do **not** regenerate the FIFO IP just for `Overflow_Flag`/`Underflow_Flag`:
underflow would only re-implement E2 inside the core (still needs the sticky
latch); overflow is prevented by the write gates and would be a second
never-event at best.
