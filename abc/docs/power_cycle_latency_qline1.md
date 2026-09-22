# Power-cycle latency test on qline1

2026-09-17, qline1 (ql001 Alice, ql002 Bob), LTC6951 h10 = 0x02 on both. Bring-up
step 3 of `deterministic_latency.md`. Four series of power cycles, both nodes
flashed with the same build per series:

| Series | Boots | Bitstream | md5 | Bob Si5319 |
|---|---|---|---|---|
| c | 10 | `bitstream/bit_sep15_det_latency` | d983dbb0041bfd2fbd98856ee9d169c3 | PLL |
| t | 10 | `bitstream/bit_sep17_tdc_phase` (PPS edge detector and counter phase readback in `tdc_clk_rst_mngt`) | d0e232cc030c0f83d2de351fced7b5b7 | PLL |
| b | 3 | `bitstream/bit_sep17_tdc_phase` | d0e232cc030c0f83d2de351fced7b5b7 | bypass |
| d | 2 | `bitstream/bit_sep17_tdc_phase` | d0e232cc030c0f83d2de351fced7b5b7 | PLL at boot, bypass and PLL reloaded over SPI |

## Result

- **Alice DAC to Bob TTL gate: deterministic in both builds.** Alice's pulse
  lands at the same place inside Bob's APD gate window on every boot (spread
  about 5 units = 100 ps).
- **Bob TDC time frame: not deterministic with the Si5319 PLL in the path.**
  On the boots that jump, the pulses and the gate window move together, by the
  same amount, in the TDC timestamps. The pulse-to-gate relation holds, so the
  TDC timestamp origin is what moves, not the DAC or the gate.
- **The Si5319 DSPLL is the source.** On a boot whose PLL frame sits 5 VCO
  periods off (d01), switching the Si5319 to bypass over SPI puts the frame at
  the same place as on a clean boot (d00), to 0.1 unit; reloading the PLL
  brings the offset back. With the Si5319 in bypass from power-up (b series)
  the frame is the same on every boot. The fix is bypass, see
  `deterministic_latency.md`.
- **Whole clk200-cycle jumps are absent with `bit_sep17_tdc_phase`.** c series:
  3 of 10 boots jumped by whole clk200 cycles and changed the 64-period index.
  t series: 0 of 10, index 17 on every boot, TDC counter phase 0 and valid on
  every boot. At the c series rate, ten clean boots in a row has a probability of
  about 3 %.
- **Sub-cycle jumps remain.** 2 of 10 boots in each series carry an offset below
  one clk200 cycle (c01 +30 alongside a whole-cycle jump, c02 −51; t01 −52, t08
  +31). Each is a whole number of Si5319 VCO periods (206 ps).
- **SPI re-initialisation neither reproduces nor removes them.** 12 × Si5319
  ICAL and 12 × Si5319 RST_REG, each followed by `Time_Calib_Init`, left the
  frame within 1.5 units of t00 on a clean boot, and within 0.7 unit of its
  offset on the jumped boot d01.
- **Bypass does not widen the pulse.** Free-running pulse FWHM 17.3-17.9 units
  in bypass against 17-19 with the PLL.
- Timebase status 0x12024 after init on both nodes, every boot: 0x2a19 (c),
  0x2002a19 (t, b, d: arm_dist 42, phase 0, phase valid).

## Procedure per boot

Power-cycle both nodes, then the old hw_control stack:
`set_laser_1550`, `init` (Alice: Config_Ltc, Sync_Ltc, FDA, SDA, decoy; Bob:
Config_Ltc, Sync_Ltc, FDA, SDA, JIC, `Time_Calib_Init`, TTL gate), `laser_on`,
`Sync_Gc`. Fixed settings on every boot: Alice `am_shift` 0, Bob `gate_delay`
2764 ps, gate width 8 slots, `t0` 10. Bob then records 20 000 clicks each:

1. Alice single pulse (one per 25 ns), APD free-running: pulse position in the
   TDC frame, `time % 1250`.
2. Same, APD gated: gate window position (`time % 625`, pedestal support) and
   pulse position inside it.
3. Alice single64 (one pulse per 64 periods), gated: the period index
   `(gc*2 + q_pos) % 64` that holds the pulse.

0x12024 is read on both nodes before and after init.

Units: TDC time field, 20 ps. 625 = 12.5 ns period, 1250 = 25 ns gc, 250 = one
clk200 cycle.

## Data, c series (`bit_sep15_det_latency`)

| Boot | Pulse minus gate window start | Gate window start | Free-running first peak | TDC frame shift vs c00 (mod 1250) | Period index /64 | Shift mod 800 ns (ns) |
|---|---|---|---|---|---|---|
| c00 | 124.8 | 524 | 397.3 | 0 | 17 | 0 |
| c00b (re-init, no power cycle) | 122.9 | 526 | 397.9 | +0.3 | 17 | +0.01 |
| c01 | 124.4 | 58 | 1179.0 | −468.9 | 53 | −359.38 |
| c02 | 126.4 | 474 | 347.2 | −50.7 | 17 | −1.00 |
| c03 | 124.1 | 528 | 399.2 | +1.5 | 17 | +0.05 |
| c04 | 125.3 | 526 | 399.8 | +2.1 | 17 | +0.07 |
| c05 | 127.8 | 526 | 400.4 | +2.5 | 17 | +0.07 |
| c06 | 123.3 | 280 | 151.4 | −247.0 | 37 | +245.05 |
| c07 | 125.6 | 528 | 402.1 | +4.2 | 17 | +0.07 |
| c08 | 124.4 | 530 | 401.9 | +4.1 | 17 | +0.08 |
| c09 | 126.8 | 278 | 152.8 | −245.2 | 53 | −354.90 |

Shifts are cross-correlations of the whole histogram against the series'
first boot. Repeat captures within one boot agree to about 0.5 unit.

The last column is the single64 pulse position as `(gc*1250 + time % 1250) mod
40000`, the gc that `tdc_core` writes already including `time_ref_gc`. `time`
spans the 200 ns `tdc_refclk` period (0..10000). In clk200 cycles the four
jumps are:

| Boot | Shift (clk200 cycles) | Remainder after whole cycles, drift-corrected |
|---|---|---|
| c01 | −71.88 | +30 units (0.6 ns) |
| c02 | −0.20 | −51 units (1.0 ns) |
| c06 | +49.01 | 0 |
| c09 | −70.98 | 0 |

c06 and c09 are whole clk200 cycles. c01 and c02 also carry a sub-cycle part.
c01 and c09 land in the same 64-period index but differ by 0.9 clk200 cycles.

## Data, t series (`bit_sep17_tdc_phase`)

| Boot | Pulse minus gate window start | Gate window start | Free-running first peak | TDC frame shift vs t00 (mod 1250) | TDC frame shift vs c00 (mod 1250) | Period index /64 | Shift mod 800 ns vs t00 (ns) | 0x12024 phase |
|---|---|---|---|---|---|---|---|---|
| t00 | 125.8 | 552 | 427.2 | 0 | +29.3 | 17 | 0 | 0, valid |
| t01 | 124.8 | 502 | 375.2 | −51.9 | −22.6 | 17 | −1.00 | 0, valid |
| t02 | 122.6 | 556 | 426.2 | −0.1 | +29.3 | 17 | −0.05 | 0, valid |
| t03 | 132.4 | 546 | 426.6 | −0.3 | +29.0 | 17 | +0.03 | 0, valid |
| t04 | 125.2 | 554 | 426.9 | −0.2 | +29.0 | 17 | −0.04 | 0, valid |
| t05 | 124.7 | 554 | 427.1 | −0.2 | +29.1 | 17 | −0.04 | 0, valid |
| t06 | 124.6 | 554 | 426.8 | −0.3 | +29.0 | 17 | 0.00 | 0, valid |
| t07 | 125.6 | 552 | 426.9 | −0.1 | +29.2 | 17 | +0.06 | 0, valid |
| t08 | 125.2 | 584 | 457.6 | +31.1 | +60.3 | 17 | +0.62 | 0, valid |
| t09 | 124.5 | 554 | 426.9 | 0.0 | +29.4 | 17 | −0.05 | 0, valid |

t03's pulse-minus-window value comes from the window-start estimate (546): its
pulse position and the cross-correlated window agree with t02 within 1.5 units.

Both jumps are below one clk200 cycle and leave the 64-period index unchanged.

### Sub-cycle offsets across both series

In the c00 frame, the frame positions seen so far are:

| Offset vs c00 (units) | Boots |
|---|---|
| −51 | c02 |
| −23 | t01 |
| 0 to +4 (slow drift) | c00, c03–c05, c07, c08, and c06/c09 after removing whole cycles |
| +28 to +30 | t00, t02–t07, t09; c01 after removing whole cycles |
| +60 | t08 |

The two builds have different routing, so a fixed offset between the series is
possible. c01's remainder of +30 in the c build matches the t series' most
common position, and t01 and t08 sit at −52 and +31 from it, which is about the
spacing of the c series values. The t series was captured about 3 h after the
c series.

Every jump measured within one series is a whole number of Si5319 VCO periods.
From `registers/jit_cleaner/Si5319_regs.txt` (N31 = 3, N2_HS = 5, N2_LS = 582,
N1_HS = 5, NC1_LS = 194) and the 5 MHz input, fosc = 970 × 5 MHz = 4.85 GHz, one
period 206.2 ps = 10.31 units:

| Jump | Units | VCO periods |
|---|---|---|
| c02 vs c00 | −50.7 | −4.92 |
| c01 remainder | +30 | +2.9 |
| t01 vs t00 | −51.9 | −5.03 |
| t08 vs t00 | +31.1 | +3.02 |

## Re-initialisation without power cycle (Bob, `bit_sep17_tdc_phase`)

Same boot as t09. Alice in single-pulse mode, Bob free-running capture of 20 000
clicks after each step, frame position `time % 1250` cross-correlated against
t00:

| Step on Bob | Rounds | Frame vs t00 (units) | Hops |
|---|---|---|---|
| none (baseline) | 1 | +0.7 | 0 |
| `Time_Calib_Init` | 3 | +0.7 to +0.8 | 0 |
| `Config_Jic` + `Time_Calib_Init` | 12 | +0.6 to +1.5 | 0 |
| Si5319 ICAL write alone (LOL poll below), then `Time_Calib_Init` | 1 | +1.0 | 0 |
| Si5319 RST_REG (reg 136 = 0x80), 1 s wait, `Config_Jic` + `Time_Calib_Init` | 12 | +0.6 to +1.4 | 0 |

- `Config_Jic` writes the register file, whose last entry is ICAL (reg 136 =
  0x40); reg 3 = 0x15 sets SQ_ICAL. Polling reg 130 right after the ICAL write:
  LOL_INT set at 3 ms and cleared at 42 ms, then stayed clear for 8 s. After
  every round LOL_INT = 0 and LOS1_INT = 0.
- After RST_REG, reg 3 read the reset default 0x05 (configured 0x15) and the
  device ID (reg 135) read 0x32, so the device reset took effect before the
  register file was reloaded.
- `Time_Calib_Init` includes `Reset_Tdc` and the AS6501 power-on reset over SPI.
  Every round: 0x12024 = 0x2002a19, TDC counter phase 0, valid.
- The frame drifts by about 0.1 unit per round, no step.

At the power-cycle jump rate of 2 in 10, 24 Si5319 rounds without a hop has a
probability of 0.5 %. Neither ICAL nor RST_REG over SPI, nor the AS6501 reset,
reproduces the jump.

## Data, b series (`bit_sep17_tdc_phase`, Si5319 bypass)

Bob's `~/config/registers/jit_cleaner/Si5319_regs.txt` line 1 is `0x00,0x16`
(BYPASS_REG = 1); the rest of the file, ICAL included, is unchanged. `init`
otherwise as above. The first bypass measurement was on boot t09 without a
power cycle: `Config_Jic` + `Time_Calib_Init`, free-running capture, three
times (`byp1`-`byp3`): frame +139.2 units vs t00, the three within 0.2 unit.
Bypass removes the PLL's input-to-output delay, hence the constant offset
against the t series; it is not a jump.

| Boot | Reg 0 after init | Pulse minus gate edge | Free-running FWHM (units) | TDC frame shift vs b00 (mod 1250) | vs t00 | Period index /64 | 0x12024 phase |
|---|---|---|---|---|---|---|---|
| b00 | 0x16 | 145.0 | 17.3 | 0 | +139.7 | 17 | 0, valid |
| b01 | 0x16 | 148.9 | 17.6 | −0.6 | +139.1 | 17 | 0, valid |
| b02 | 0x16 | 148.5 | 17.9 | 0.0 | +139.7 | 17 | 0, valid |

"Pulse minus gate edge" is the pulse position against the gated histogram's
raw support edge rather than the window-start estimate of the c and t tables,
which is fragile (b00 read 149 by the estimate while the aligned gate edges
matched t00 within 2 units). On that metric the c series reads 129-134 and the
t series 143-146.

## Data, d series (`bit_sep17_tdc_phase`, PLL at boot, bypass over SPI)

Each boot powers up and inits in PLL mode (register file at `0x00,0x14`) and
takes the full captures, then loads bypass over SPI (`Config_Jic` +
`Time_Calib_Init`, free-running capture `byp_free`), then reloads PLL the same
way (`pll2_free`). Frames vs t00, units:

| Boot | PLL at power-up | Bypass loaded | Bypass minus PLL | PLL reloaded (ICAL) | Period index /64 |
|---|---|---|---|---|---|
| d00 | +1.7 | +139.6 | 137.9 | +1.9 | 17 |
| d01 | −49.7 | +139.6 | 189.3 | −49.7 | 17 |

d01 is a jump boot: −51.4 vs d00, 5 VCO periods. Its bypass frame is the same
as d00's to 0.1 unit, so the offset is inside the Si5319 PLL path and nothing
upstream of it. Two further rounds on d01 of a full Si5319 software reset
(RST_REG, `Config_Jic` PLL, `Time_Calib_Init`; `rst1_free`, `rst2_free`) read
−49.0 and −49.2: the DSPLL output phase is set at power-up and no SPI-level
reset re-draws it.

The PLL-mode jumps are therefore the Si5319 DSPLL choosing a different VCO
period at each power-up (the reference manual, 6.2.4, leaves the input-to-output
skew uncontrolled). In bypass CKOUT is the FPGA `tdc_refclk` through the input
and output buffers, with no phase to draw.

## Consequence for hw_control

`am_shift` and `gate_delay` can be kept across power cycles. `t0`, the soft
gates, `fiber_delay` and `zero_pos` are in the TDC frame and can be kept with
`bit_sep17_tdc_phase` and the Si5319 in bypass: three bypass boots agree
within 0.6 unit. Bob's Si5319 runs in bypass since 2026-09-17; the register
table in `kiwi_hw_control` `remote/registers/jit_cleaner/` has it, `Config_Jic`
prints the bypass state after init, and the kiwi daemon's `Si5319.configure`
refuses a table without it. The PLL-era table is kept on the nodes as
`Si5319_regs.txt.bak.pll.20260917`.

Raw captures: `~/lat_probe/<boot_id>/{sp_free,sp_gated,sp64_gated}.bin` on
ql002 (16-byte TDC records), one directory per boot; c00 and c00b share a boot
and the directory holds c00b. The re-initialisation captures are in the t09
directory as `base1`, `ctl1`–`ctl3`, `jic01`–`jic12`, `rst1`, `rst02`–`rst12`,
`post1` and `byp1`–`byp3`; the d directories hold `byp_free`, `pll2_free` and,
for d01, `rst1_free` and `rst2_free`. Bob boot IDs:

| Boot | boot_id |
|---|---|
| t00 | 2e79debc-744c-42fe-a69b-571b00535146 |
| t01 | aef448c4-2053-44da-a99b-7eef0037f5c4 |
| t02 | ee5c7cd0-74a8-4a70-b259-9d910d5cf55e |
| t03 | de14c2dd-f5a5-4c0c-9165-9bd7cbfe3ded |
| t04 | 0c14039d-9f7e-44e8-ad6e-545555e5389e |
| t05 | 77c3844c-b21c-490a-9839-97d3b0173eb2 |
| t06 | 7c7043f6-7fe2-485e-924e-c43a748ed3fe |
| t07 | 0dd585bd-4a11-4758-a5b5-4183b95e9797 |
| t08 | b83e57cb-f98e-47ff-b1e5-4c07ff663909 |
| t09 | c79b63ad-56f8-413c-ad7e-a4596631afc5 |
| b00 | 5ed454b3-f762-4fb6-bad5-7e9810473dd9 |
| b01 | f53fd7f3-e94f-4a24-8fcc-5cf1e218f5dd |
| b02 | dd78af99-585c-4b92-b58b-8ce9d48c8a37 |
| d00 | ae5195c7-ed7b-4141-b4cf-f71b54966691 |
| d01 | 4662efd5-3395-49f0-a009-e0c38ae6ece5 |
