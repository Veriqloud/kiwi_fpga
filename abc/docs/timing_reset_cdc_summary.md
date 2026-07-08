# Timing / Reset / CDC Summary — RNG datapath

Scope: reset distribution (`rng_rst`), clock-domain crossings, and the XDC
timing exceptions for the biased-RNG datapath (`angles_top_wrapper`,
`rangedec_top_wrapper`, `decoy_rng_fifos`, `jesd_transport`).

Device: Xilinx XCAU25P. Tool: Vivado 2024.2.

---

## 1. Clock domains

| Clock (design net)              | Freq     | Role                                           |
|---------------------------------|----------|------------------------------------------------|
| `refclk` = `tx_core_clk` = `clk200` = `fastdac_coreclk_o` | 200 MHz | Same GTY refclk net. RNG read/consumer side.  |
| `s_axis_clk` / `xdma_0_axi_aclk`| 250 MHz  | PCIe GTY. Entropy AXI-Stream write side.        |
| `clk80`                         | 80 MHz   | clk_wiz. Controller / basis_rangedec processing.|
| AXI-Lite clock                  | (slow)   | Source of the `rng_rst` register bit.           |

`refclk`, `tx_core_clk`, and `clk200` are the **same physical net** (BUFG_GT
X1Y1) — crossings between those three names are *not* real CDC.

---

## 2. Reset distribution — `rng_rst`

**Master seed:** `rng_rst = slv_reg7[0]` (`clk_rst_axil_mngt.v:145`) — a raw
AXI-Lite register bit, **asynchronous** to 200/80/250 MHz, glitch-free (only
changes on SW write). The old clk200 pre-sync (`rng_rst_r`) and `rng_reset_inst`
in `clk_rst_mngt.v` are **commented out**; the raw bit now propagates directly
as `rng_reset` into `jesd_transport` and `decoy_rng_fifos`.

**Topology (current, verified clean):** one async master → one `reset_register`
(async-assert / 2-FF sync-deassert) per clock domain. No cross-domain cascade
into synchronous logic.

```
rng_rst (raw async AXIL bit)
├─►[jesd_transport @clk200]
│    ├─ rng_reset_inst : reset_register@tx_core_clk → rng_rst_clk200      (used @478)
│    └─ angles_rng_inst: .rst=raw , .rst_clk200=rng_rst_clk200
│        [angles_top_wrapper]
│        ├─ u_rst_saxi   : reset_register@s_axis_aclk → rst_saxi          (rr @148)
│        ├─ u_even_unpack / u_uneven_unpack / dout_r* @clk200 → rst_clk200
│        ├─ u_true (fifo_up_true) .rst=raw → FIFO async (IP-internal sync)
│        └─ u_basis (rangedec) .rst=raw
│             ├─ u_rst_clk80 : reset_register@clk80 → rst_clk80
│             └─ fifo_128x16 / fifo_1x2 .rst=raw → FIFO async (IP-internal sync)
└─►[decoy_rng_fifos @clk200] rng_reset=raw
     └─ u_rangedec_top_wrapper: u_rst_clk80 (clk80) ; FIFOs → IP async ;
        clk200 side is FIFO-only (no user clk200 flops)
```

**Rule of the design:** every *synchronous* reset consumer sits behind a
`reset_register` in its own clock domain. The raw `rng_rst` only reaches
(a) `reset_register` async pins, and (b) FIFO async-reset inputs.

### History note — the one gap that was fixed
Previously `angles_top_wrapper`'s clk200 datapath (`u_even_unpack`,
`u_uneven_unpack`, `dout_r0`/`dout_r`) reset synchronously on the **raw async**
`rst` with no clk200 synchronizer — a real metastable/ragged-release CDC.
Fixed by adding a synchronized clk200 reset: `jesd_transport` generates
`rng_rst_clk200` (reset_register@tx_core_clk) and passes it into
`angles_top_wrapper.rst_clk200`; the three clk200 users now use it. FIFO `.rst`
ports and the `reset_register` seeds stay on the raw `rst`.

---

## 3. `reset_register` structure (relevant to constraints)

`srcs/common/reset_register.v`: async-assert / sync-deassert.
- HIGH mode: `always @(posedge clk_i, posedge rst_i)`.
- On assert: `rst_r <= 3` (2-bit, async **PRE**), `rstn_r <= 0` (async **CLR**).
- Outputs `rst_o = rst_r[1]`, `rstn_o = rstn_r[1]`.
- When only `rst_o` is used, `rstn_r` is typically trimmed → surviving async
  endpoint is `rst_r_reg[*]/PRE`.

So the async endpoints of any reset are `*/rst_r_reg[*]/PRE` and
`*/rstn_r_reg[*]/CLR`. Timing the async assert is meaningless → `set_false_path`.

---

## 4. FIFO reset (fifo_128x16, fifo_1x2, fifo_up_true)

FIFO Generator config: `Reset_Type = Asynchronous_Reset`,
**`Enable_Reset_Synchronization = true`**. Each FIFO internally re-synchronizes
the async reset into *both* its write and read domains (async-assert /
sync-deassert per domain, `garst_sync_ic[*].rd_rst_inst` flops). Safe in
silicon provided `rng_rst` is held asserted ≥ ~3 cycles of the slowest FIFO
clock (the 80 MHz side) — satisfied, since `rng_rst` is a long SW reset.

`report_cdc` still flags `rng_rst → FIFO internal reset flops` because the
crossing is buried in encrypted IP and the IP's own reset-sync false_paths in
`fifo_*_clocks.xdc` ship **commented out**. This is benign → **waive** it
(do not add an RTL synchronizer in front; the IP requires a raw async reset).

---

## 5. XDC strategy (reset / CDC)

Collapse the scattered per-instance reset false_paths into uniform hier rules,
plus a FIFO CDC waiver:

```tcl
## async assert into every reset_register (deassert is 2-FF synchronized)
set_false_path -to [get_pins -hier -filter {NAME =~ */rst_r_reg[*]/PRE}]
set_false_path -to [get_pins -hier -filter {NAME =~ */rstn_r_reg[*]/CLR}]

## FIFO-gen internal reset synchronizers (Enable_Reset_Synchronization=true)
## Fill real CDC IDs / endpoint names from `report_cdc`.
create_waiver -type CDC -id {CDC-1 CDC-10 CDC-11} \
  -to [get_cells -hier -filter {NAME =~ *u_fifo_u*/*garst_sync_ic* || \
                                NAME =~ *u_true/*garst_sync_ic*}] \
  -description "FIFO-gen internal reset sync; rng_rst held >>3 slow-clk cycles"
```

The two hier rules cover: `jesd/rng_reset_inst`, `angles/u_rst_saxi`,
`angles/u_basis/u_rst_clk80`, `decoy/u_rangedec_top_wrapper/u_rst_clk80`, and
every other `reset_register` in the design — and auto-cover any future one.

### Stale constraints to remove (found against current RTL)
- **BROKEN** — `set_false_path -from {.../clk_rst_mngt/inst/rng_reset_inst/rst_r_reg[1]/C} -to {.../angles_rng_inst/u_basis/u_rst_clk80/...}`
  — source flop is commented out in RTL → "no pins matched". Subsumed by hier rule.
- **OBSOLETE** — `set_false_path -to {.../jesd_transport_0/inst/rng_fifo_status_reg[*]/D}`
  — those flags are now synchronized via `cdc_sync_single`.
- **SUBSUMED** — per-target `.../u_rst_clk80/rst_r_reg[*]/PRE` (decoy) and
  `.../u_rst_saxi/rst_r_reg[*]/PRE` — covered by the hier rule.
- **NEWLY NEEDED (auto-covered)** — `jesd_transport_0/inst/rng_reset_inst/rst_r_reg[*]/PRE`
  (the reset synchronizer moved out of `clk_rst_mngt`).

### Keep (non-reset exceptions, unrelated)
- `set_false_path -from [get_clocks refclk] -to {.../decoy_0/inst/rng_a_r_reg[*]/D}`
- `rd_en_4` false_path (`rd_en_4_reg/C → decoy_0/.../rd_en_4_r_reg[0]/D`)
- `reg_en_80` false_path
- `rng_data`/`rng_a_data` → `data_pack_reg` multicycle (setup 2 / hold 1)
- flag synchronizer false_paths on `u_sync_*/sync_ff_reg[0]/D` (decoy + jesd) —
  these target synchronizer *data* inputs, not resets.

---

## 6. Data-flag CDC (status flags)

FIFO status flags crossing into the consumer (clk200 / tx_core_clk) domain are
synchronized with `cdc_sync_single` (2-FF `ASYNC_REG`, no reset):
- `jesd_transport`: `u_sync_af16`, `u_sync_uv_af16`, `u_sync_uv_e16`,
  `u_sync_uv_af2` → `tx_core_clk`. `empty_16` / `uv_empty_2` already clk200.
- `decoy_rng_fifos`: `u_sync_de_af16`, `u_sync_de_e16`, `u_sync_de_af2`
  → `clk200`. `de_empty_2` already clk200.

These are level flags (single-bit, no multi-bit coherency requirement), so a
2-FF synchronizer is sufficient. First-stage `D` inputs are false-pathed.

---

## 7. Caveats / follow-ups

- **PRE vs CLR after synth:** with only `rst_o` used, `rstn_r` is likely
  trimmed; keep both hier rules — a "no pins matched" on the CLR line is
  harmless. Confirm the async pin resolves to `PRE` (FDPE), not `CLR`.
- **Waiver IDs/endpoints are placeholders:** run `report_cdc` once and paste the
  real `garst_sync_ic` / `rd_rst_inst` cell names and CDC IDs.
- **BD IP scope:** `decoy_rng_fifos_0` is an OOC-synthesized BD IP; its internal
  reset flops only exist post-synth, so the waiver/false_path must be top-level.
- **cdc_sync_single** must be in the project source list *and* the
  `decoy_rng_fifos_0` BD IP source set (re-package OOC), or synth fails.
