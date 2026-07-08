# Decision log — RNG datapath timing closure & recombine refactor

Date: 2026-07-06
Scope: `Qline_turnkey` timing closure + `angles_top_wrapper` RNG recombine path.
Design: kiwiKD / Qline_turnkey, XCU (GTY refclk 200 MHz, clk_wiz 240/80 MHz, XDMA 250 MHz).

---

## 1. Timing closure — CDC constraints (constrs/Qline_turnkey_constrs.xdc)

Routed report started at WNS **-2.744 ns / 24 failing endpoints**. Diagnosis: 4 of 5
failing groups were **asynchronous clock-domain crossings timed as synchronous**
(independent oscillators: `refclk` GTY, `clk_wiz` outputs from ext clk10, `xdma_0_axi_aclk`
from PCIe). Only the `refclk`→`refclk` group was a real synchronous path.

Decision: use **surgical per-pin waivers** (matches existing XDC style; safer than a blanket
`set_clock_groups` because it only waives crossings we verified are synchronized). Added under
an `## AI suggestion` block:

- `set_false_path -to .../rst80_meta_reg[*]/D` — reset sync into clk80 (rangedec).
- `set_false_path -from [get_clocks refclk] -to .../rng_a_r_reg[*]/D` — BRAM→240 MHz decoy rng.
- `set_false_path -to .../rng_fifo_status_reg[*]/D` — FIFO flags from xdma/clk80 → refclk.
- `set_false_path -from .../rd_en_4_reg/C -to .../decoy_0/.../rd_en_4_r_reg[0]/D` — 40 MHz tick
  resynced into clk240 (2-FF ASYNC_REG + edge detect; 5 ns pulse > 240 MHz period).

### Group 1 — real path (NOT waived): multicycle
`refclk`→`refclk`, `fastdac jesd dpram_seq_rng_16x4` (BRAM) → `ddr4 ddr_data data_pack`.
`rng_data`/`rng_a_data` update only on the 40 MHz `rd_en_4` tick and are **stable for 5
clk200 cycles** (confirmed by user; capture at [ddr_data.v:475]). Decision: **multicycle path**,
scoped `-through` the boundary nets so the single-cycle `cycle_counter`/`rd_en_4` control paths
into `data_pack` are NOT relaxed:
```
set_multicycle_path 2 -setup -through {.../ddr_data_0/inst/rng_data[*] rng_a_data[*]} -to {data_pack_reg[*]}
set_multicycle_path 1 -hold  -through {...} -to {data_pack_reg[*]}
```

### xdma → refclk reset CDC (paths 671/672)
`rng_reset` (refclk) → `angles_rng_inst/rr_reg[*]/R` (xdma 250 MHz). `FDRE.R` is a **synchronous**
reset, so it was timed as setup across async clocks. `rr` is a self-healing 2-bit arbiter → not
safety-critical, but user wants deterministic/repeatable reset for testing. Decision: **add an
s_axis_aclk reset synchronizer in RTL** (see §2) and `set_false_path` its async preset.

---

## 2. angles_top_wrapper — reset handling

- **Added `rst_saxi` synchronizer** (2-FF ASYNC_REG, async assert / sync deassert) in the
  `s_axis_aclk` domain; `rr` now resets on `rst_saxi` instead of the raw cross-domain `rst`.
  Reason: `rst` is toggled at test time; a real CDC into 250 MHz needed a synchronizer for a
  clean, metastability-free, repeatable reset release. XDC: `set_false_path -to rst_saxi_sync_reg[*]/PRE`.
- **Removed the redundant `rst200_sync`.** `clk200` (= `tx_core_clk`) and the clock that registers
  `rng_reset` are the **same physical net** (`clk_rst_mngt/BUFG_GT_inst/O`, `refclk`), so `rst` is
  already clk200-synchronous. The recombine/fifo2 consumers now use `rst` directly. (Kept only where
  it was a true CDC — the s_axis one above.)

---

## 3. Recombine refactor — remove fifo2, capture on rd_en_4

Old path: `bit_unpacker` ×2 → `nibble_assembler` → `fifo_4x4` (**1024-deep BRAM**, drained at
`rd_en_4`). Critique: the BRAM was ~250× oversized for a common-clock nibble rate-matcher, redundant
with the upstream branch FIFOs, and didn't guarantee the real requirement (a valid nibble per tick).

Decision: **eliminate fifo2.** The unpackers hold their current pair; on each `rd_en_4` tick (when
`both_ready`) we advance both unpackers and register the assembled `{E,U,E,U}` nibble directly.
```
both_ready = even_valid & uneven_valid;
nibble     = {even_pair[1], uneven_pair[1], even_pair[0], uneven_pair[0]};
pop        = rd_en_4 & both_ready;   even_take = uneven_take = pop;
```
Removed `nibble_assembler` + `fifo_4x4` instantiations (files + `fifo_4x4` IP now unused).

**Correctness (agreed):** even/uneven pairs becoming valid on different cycles is **harmless to
`dout`** because (a) `pop` only fires when both are valid, and (b) both unpackers advance in lockstep
(1:1 pairing, never mis-indexed). This holds **conditionally** on `both_ready` being asserted every
tick → requires **basis_rangedec to sustain 80 Mbit/s** (assumed guaranteed). If a branch runs dry,
`jesd_transport` (which leaves `dout_empty` unused and free-runs `rd_en_4`) would re-emit the previous
nibble — a stale repeat, not corruption.

---

## 4. bit_unpacker — 1-word prefetch

Problem: the uneven path (1 pair/word) drained `pairs` to 0 each take, so `pair` went invalid/reset
mid-tick (visible on the wcfg). Decision: **prefetch the next FIFO word into a 1-word lookahead
(`pbuf`/`pfull`)** while emitting the current word; on the last-pair take, reload `sbuf` from `pbuf`
on the same cycle. `pairs` never hits 0 → `pair` stays valid continuously and changes only on
`pair_take`. No same-cycle register races (a read is only issued when `~pfull`, so completion and
reload can't collide). Even path (8 pairs/word) is seamless; the once-per-8 `fifo_rd_en` lines up
with the reload.

**Observed asymmetry explained:** with 16-bit words `pair` toggles on the same edge as `fifo_rd_en`
(prefetch always full → seamless reload). With 2-bit words `pair` toggles ~3 cycles after
`fifo_rd_en` = the read pipeline latency (`fifo_rd_en`→dout(+1)→pbuf(+1)→sbuf(+1)). This exposes that
the **uneven/basis branch runs dry** (source slower than 40 MHz demand) — a rate/provisioning symptom,
not an unpacker bug. Nibble stays correct via `both_ready` gating.

---

## 5. Output latency match

`fifo_16x4` (the replaced output FIFO) is a **Standard FIFO with embedded output registers**,
`C_PRELOAD_LATENCY = 2` ⇒ `dout` appeared **2 clk200 cycles** after the `rd_en_4` edge.

Decision: reproduce exactly with a **2-stage register** (`dout_r0` captured on `pop`, then pipelined
to `dout_r`), keeping `dout` **registered** (not combinational). This leaves the `jesd_transport`
consumer (`rd_en_4 -> rd_en_4_shift[0]`) unchanged.

Note: the consumer samples at `rd_en_4_shift[0]` (delay-1) while data is valid at delay-2 — an
inherent **off-by-one that existed with the old fifo_16x4 too**. Matching the 2-cycle latency
preserves that exact (harmless-for-RNG) behavior. Changing it (consumer → `rd_en_4_shift[1]`, or
1-stage `dout_r`) would deviate from legacy timing — deliberately NOT done.

---

## 6. Open item — entropy FIFO sizing (not yet changed)

| FIFO | write W×D | storage | ~BRAM |
|---|---|---|---|
| `fifo_128x16` (even) | 128b × 4096 | 512 Kbit | ~15 RAMB36 |
| `fifo_1x2` (uneven/basis) | 1b × 1024 | 1 Kbit | ~1 RAMB18 |

Conclusion: **shrink, do not expand.** These are rate-limited, back-pressured elastic buffers;
depth never raises throughput (producer = ~32 Gbit/s XDMA vs 80 Mbit/s/branch demand, ~200× headroom).
Depth only rides through **XDMA H2C delivery gaps**: `depth_bits ≥ worst_gap × 80 Mbit/s`.
- `fifo_128x16` = 512 Kbit buffers ~6.5 ms → absurd; 4096→512 frees ~12 BRAM (128-bit width floors
  it at ~2 BRAM regardless of depth). Consider a programmable full threshold for margin when shallow.
- `fifo_1x2` = 1 Kbit buffers ~12.8 µs; shrinking to ~32-64 could move it to distributed RAM (0 BRAM),
  but first confirm its overflow protection (it has **no almost_full** flag).

**BLOCKED ON:** worst-case XDMA H2C stall budget (continuous descriptor ring vs on-demand). That number
sets both final depths.

---

## Files touched
- `constrs/Qline_turnkey_constrs.xdc` — CDC false paths + Group-1 multicycle (AI suggestion block).
- `srcs/fastdac/rdec/angles_top_wrapper.v` — rst_saxi sync, drop rst200_sync, remove fifo2,
  rd_en_4 nibble capture, 2-stage output latency.
- `srcs/fastdac/rdec/bit_unpacker.v` — 1-word prefetch.
- `sim/angles_top_wrapper_tb.v` — comment updates (logic unchanged).
- Now unused: `srcs/fastdac/rdec/nibble_assembler.v`, `srcs/fastdac/rdec/fifo_4x4_wrapper.v`, IP `fifo_4x4`.

## Verification status
- 5-cycle-stable pair (prefetch): PASS in xsim (user).
- Full timing re-run after all constraints: reduced 24→ (in progress); confirm 0 failing endpoints.
- Recombine distribution/underflow self-check + 2-cycle latency: verify in xsim with
  `angles_top_wrapper_tb_behav.wcfg`.
