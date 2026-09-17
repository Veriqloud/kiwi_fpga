# Deterministic latency: one PPS sampling point

Branch `ttl-gate-serializer`, 2026-09-15. TDC time frame findings 2026-09-17.

## Problem

The offset between the DAC output and the TTL gate changed across power cycles.

- PPS was sampled by single flops in nine places across five clocks
  (`clk_rst_mngt` clk10, `ttl_gate_apd` and `decoy` clk240, `jesd_transport`
  and `sync_tx_tready` tx_core_clk, `decoy`, `tdc_clk_rst_mngt`, `tdc_core`,
  `ddr_data` clk200). The PPS edge sits at a fixed but unknown phase in each
  clock. A sampler whose setup/hold window contains that phase resolves
  differently on every power cycle; with nine samplers the chance that one of
  them is marginal is high. The WRS aligns PPS with a 10 MHz rising edge, so the
  clk10 sampler used for the LTC6951 SYNC sat exactly on the edge.
- SYSREF was declared as its own clock, grouped asynchronous to refclk and
  captured through a 3-flop synchronizer, so the JESD TX LMFC could land one
  core-clock cycle either way.
- The decoy RNG value crossed from clk200 to clk240 through a synchronizer on
  `rd_en_4`, so the clk240 cycle on which a new value took effect could move.

With those fixed, the DAC-to-gate offset was constant over 20 power cycles on
qline1, but the TDC time frame on Bob still moved on some of them (section TDC
time frame):

- `tdc_clk_rst_mngt` reset its PPS edge detector to 0. A `tdc_rst` released
  inside the 100 ms pps200 high window started the TDC reference clock at an
  arbitrary clk200 cycle. `ttl_gate_apd` had the same detector on pps10.
- The AS6501 reference clock passes through the Si5319 jitter cleaner, whose
  input-to-output skew is not controlled.

## Clock trees

Board (`kiwi_pcb/MB`):

- WR 10 MHz on J19 into the CDCLVD2104 (U10). OUT0 drives the LTC6951 REF,
  OUT2 drives the FPGA clk10 (B19/B20).
- LTC6951: R = 1, N = 20, P = 3, VCO 4.8 GHz, RAO = 1, SN = 1. One P cycle is
  625 ps.

| Output | Divider | Delay | Frequency | Goes to |
|---|---|---|---|---|
| OUT0 | M0 = 8 | - (REF-aligned) | 200 MHz | FPGA refclk, tx_core_clk |
| OUT1 | M1 = 8 | DLY1 = 9 | 200 MHz | AD9152 clock |
| OUT2 | M2 = 512 | DLY2 = 14 | 3.125 MHz | AD9152 SYSREF |
| OUT3 | M3 = 512 | DLY3 = 2 | 3.125 MHz | FPGA SYSREF |
| OUT4 | M4 = 16 | 0 | 100 MHz | FPGA clk100, unused |

- TDC (Tdc sheet): the FPGA drives `tdc_refclk` (5 MHz, J5.25/27) into the
  Si5319 jitter cleaner U6 (CLKIN, AC-coupled), whose CKOUT drives the AS6501 U5
  REFCLK. `tdc_rstidx` (J5.33/35) and LCLKIN (clk200, J5.41/43) go to the
  AS6501 directly. U6, U5 and the stop LVDS driver U24 share the `3V3` LDO U20.

Two trees, both locked to the same 10 MHz edges:

- Tree A: clk10 and the clk_wiz MMCM outputs (240, 80, 480 MHz, and a second
  240 MHz on its own BUFG for the TTL serializer CLKDIV, shifted 56.25 deg). Every output is an
  integer multiple of 10 MHz, so its phase to clk10 is the same after every
  lock, and Vivado times clk10 to clk240/clk80 paths.
- Tree B: LTC6951 OUT0 (tx_core_clk) and OUT3 (SYSREF). Their phase to the
  10 MHz edges is fixed once a SYNC has been issued.

The refclk-to-clk10 phase at the FPGA is a board constant that STA does not
model. Nothing is sampled across the two trees: tree B takes its epoch from
SYSREF, and the one data path from tree B to tree A (decoy RNG) goes through a
symbol-indexed table.

## pps_timebase

`srcs/clk_rst/pps_timebase.v`, instantiated in `clk_rst_mngt`. The module header
has the cycle-level description.

1. PPS is sampled once, on the clk10 falling edge, 50 ns from the 10 MHz rising
   edge it is aligned with. The first PPS after `ltc_rst_o` zeroes a
   10 000 000-cycle counter; afterwards PPS is only compared against count 0
   (`pps10_err`). `pps10_o` is high for the first 100 ms of every second.
2. On the first second boundary with the SYNC request bit set, `sync_ltc_o` is
   high for 20 000 cycles (2 ms), launched on the clk10 falling edge.
3. `arm` rises at count 16 of the first second that does not contain a SYNC
   pulse. It crosses into tx_core_clk through a 2-FF synchronizer. The first
   SYSREF rising edge after it becomes cycle `pps200_preset` of the second, and
   a 200 000 000-cycle counter runs from there. `pps200_o` is high for the first
   100 ms of every second. Every SYSREF edge after that must land 64 cycles
   after the previous one (`sysref_err`).

## SYNC and SYSREF phase

With RAO = SN = 1 the LTC6951 retimes the falling edge of SYNC to a REF rising
edge and restarts OUT1..OUT4 one N cycle plus 18 + Dx P cycles later. OUT0 is
not restarted; its rising edges stay on the REF grid. The offset of an output
from the OUT0 edges is therefore (18 + Dx) mod 8 P cycles.

- DLY3 = 6 gave 24 mod 8 = 0: FPGA SYSREF started on a refclk edge and the
  capture had no margin. DLY3 = 2 gives 4 P cycles = 2.5 ns, the middle of the
  refclk period. The change is in `kiwi_hw_control`
  `remote/registers/ltc/Ltc6951Regs.txt` and `Ltc6951Expect.txt` (h10 = 0x02).
- The DAC pair is unchanged: OUT1 at 27 P, OUT2 at 32 P, so the DAC sees SYSREF
  3 P cycles (1.875 ns) before its clock edge.

SYSREF rising edges then lie at 212.5 ns + k x 320 ns after the second boundary.
The SYNC pulse is 20 000 clk10 cycles = 6250 SYSREF periods long, so this does
not depend on which second the SYNC happens in.

`arm` reaches tx_core_clk about 1.61 us into the second. The SYSREF edges around
it are 118 ns before and 202 ns after. If the LTC6951 latency does not include
the N cycle, the edges are at 112.5 ns + k x 320 ns and the margins are 218 ns
and 102 ns. `arm_dist` tells the two apart: 42 with the N cycle, 22 without.
`pps200_preset` = 364 puts `pps200_o` on the same second boundary as `pps10_o`
for 42; for 22 it should be 344. Determinism does not depend on the preset,
only the nominal alignment of the two PPS does.

## Consumers

| Module | Clock | PPS input |
|---|---|---|
| ttl_gate_apd | clk240 | pps10_i |
| decoy (pattern, rng_a_r) | clk240 | pps10_i |
| decoy (DPRAM read-out, rng table write) | clk200 | pps200_i |
| jesd_transport, sync_tx_tready | tx_core_clk | pps200_i |
| tdc_clk_rst_mngt, tdc_core | clk200 | pps200_i |
| ddr_data, ddr_data_axil_mngt (status) | clk200, AXI | pps200_i |

clk200 in the TDC, DDR and decoy hierarchies is the same BUFG_GT net as
tx_core_clk.

pps10 and pps200 are high for the first 100 ms of every second, so an edge
detector whose previous-sample flop resets to 0 sees a rising edge when its
reset is released inside that window. `tdc_clk_rst_mngt` and `ttl_gate_apd`
reset that flop to 1. `tdc_core`, `ddr_data` and `decoy` wait for PPS low
before looking for the edge. Two detectors still have the pattern:
`sync_tx_tready` resets `pps_r` to 0, and the `rd_en_4` grid in
`jesd_transport` keeps `pps_r` through `tx_core_reset`, which fires if the
reset was asserted with pps200 low and released with it high. Neither moved the
DAC-to-gate offset in 20 power cycles.

## TDC time frame

The AS6501 measures each stop against the preceding REFCLK edge (TSTOP, 20 ps
per unit with REFCLK_DIVISIONS = 10000 at 5 MHz) and counts REFCLK edges since
RSTIDX (reference index, 0..7 with RSTIDX every 8 periods). The TDC time frame
is therefore set by when the REFCLK edges and the RSTIDX pulse arrive at the
chip relative to the photons.

### Counter start in the FPGA

`tdc_clk_rst_mngt` starts the 5 MHz `tdc_refclk` and the `tdc_rstidx` pulse
(every 320 clk200 cycles, 3 cycles either side of a refclk rising edge) on the
first pps200 rising edge after `tdc_rst`. The edge detector starts from the high
state, so a `tdc_rst` released inside the 100 ms pps200 high window waits for
the next second. Both outputs are driven from flops, decoded from the next
counter state, so they have the clk200 cycle timing of the former combinational
decode without its glitches.

0x24 [24:16] reads the counter phase at the last pps200 edge: 0 when the
counters started on a pps200 edge, otherwise the start offset in clk200 cycles
mod 320. It is valid ([25]) from the second pps200 edge after `tdc_rst`.

With the edge detector resetting to 0 (`bit_sep15_det_latency`), 3 of 10 power
cycles moved the frame by whole clk200 cycles (71, 72 and 111 cycles in the
1.6 us RSTIDX frame) and changed the 64-period index. `Reset_Tdc()` is a plain
register write, so its release lands in the high window on about 1 init in 10.
With the fix (`bit_sep17_tdc_phase`) 0 of 10 moved by whole cycles and the phase
read 0 on every boot.

### Si5319 jitter cleaner

The remaining jumps were below one clk200 cycle: 2 of 10 power cycles in each
series, by −52 or +31 units (−1.04 ns, +0.625 ns), always both the pulses and
the gate window together.

- All 8 pulse slots of the 200 ns reference period moved by the same amount, so
  the AS6501 scaling did not change; the REFCLK edge at the chip moved.
- The LTC6951 is not the source: with RAO = 1, P and M0 are inside the PLL loop
  (fVCO = fREF x N x P x M0 / R = 4.8 GHz), so OUT0 is aligned to REF.
- Si5319 configuration (`kiwi_hw_control` `registers/jit_cleaner`): N31 = 3,
  N2 = 5 x 582, N1 = 5 x 194, so fOSC = 5 MHz / 3 x 2910 = 4.85 GHz (206.2 ps
  = 10.31 units) and CKOUT = 5 MHz. The jumps are −5 and +3 fOSC periods.
- The Si53xx reference manual (6.2.4): the input-to-output skew of the Si5319
  is not controlled.
- ICAL and RST_REG over SPI (24 rounds) and the AS6501 power-on reset did not
  reproduce the jumps; a power cycle of the board did.
- With the Si5319 in bypass mode (register 0 BYPASS_REG = 1) power cycles no
  longer move the frame, and the measured pulse width is the same as with the
  PLL active.

The Si5319 therefore runs in bypass: `Si5319_regs.txt` starts with
`0x00,0x16`, written before the ICAL at the end of the file. CKOUT is then the
FPGA `tdc_refclk` through the Si5319 input and output buffers.

## Decoy RNG crossing

`rng_a` is produced in clk200 on the 40 MHz `rd_en_4` grid and used in clk240
on the 6-slot decoy pattern. Both sides number their symbols from their own
synchronous PPS; one second holds 40 000 000 symbols, a multiple of 16.

- clk200 writes `rng_a` for symbol n into a 16-entry register table at index
  n mod 16, three cycles after the tick.
- clk240 reads index (n - 8) mod 16 at the start of its symbol n (the pattern
  slot with counter == 2, first slot of the temp_signal1 half) into `rng_a_r`.
- The index returns to 0 on the event after the PPS edge. A write strobe in the
  same clk200 cycle as the pps200 edge still belongs to the old second. From
  the second second on, the `rd_en_4` grid puts a strobe exactly there, while
  in the first second the ticks only start after the edge.

An entry is 8 symbols (200 ns) old when read and is rewritten 16 symbols
(400 ns) after it was written. Simulation passes with pps200 up to 170 ns
either side of pps10. The emitted decoy
symbol lags the recorded `rng_a` by 8 symbols more than before; the decoy delay
calibration absorbs it once.

## Constraints

- `ext_pps`: `set_input_delay` +-40 ns against clk_10 (falling-edge capture).
- `ext_sync_ltc`: `set_output_delay` 0 against clk_10 (falling-edge launch).
- SYSREF: the `sysrefclk` clock and its clock group are gone;
  `set_input_delay` 1.5..3.5 ns against refclk.
- `arm_s_reg[0]` (clk10 to tx_core_clk), `slv_reg8` (static configuration) and
  `timebase_status_s0` (into the AXI clock) are false paths.
- Decoy table to `rng_a_r`: `set_max_delay -datapath_only 5`.

## Registers

`clk_rst_axil_mngt`, base 0x12000 (decode widened to 4 bits):

| Offset | Bits | Meaning |
|---|---|---|
| 0x00 | [0] | SYNC request (unchanged) |
| 0x18 | [0] | `ltc_sync_rst`: unlocks the timebase (unchanged) |
| 0x20 | [7:0] | `arm_cnt`, reset 16 |
| 0x20 | [23:8] | `pps200_preset`, reset 364 |
| 0x24 | [0] locked10, [1] pps10_err, [2] ltc_synced, [3] arm, [4] locked200, [5] sysref_err, [15:8] arm_dist, [24:16] TDC counter phase (expect 0), [25] phase valid | read-only status |

`Sync_Ltc()` needs no change: the reset relocks the timebase on the next PPS,
the SYNC bit issues one pulse on the next second boundary, and tree B arms in
the second after it. `ltc_synced` reads 1 from the end of the pulse until the
bit is cleared.

## Bring-up on hardware

1. Scope PPS against the 10 MHz at the FPGA side of the cables: rising edges
   within +-40 ns.
2. `kiwi_hw_control`: LTC6951 h10 = 0x02, Si5319 register 0 = 0x16 (bypass).
3. After `Sync_Ltc()` and 2 s, read 0x12024: locked10 = 1, pps10_err = 0,
   arm = 1, locked200 = 1, sysref_err = 0, arm_dist = 42 (or 22, then write
   344 to the preset field).
4. After `Time_Calib_Init()` on Bob and 2 s, 0x12024 [25:16] = 0x200 (TDC
   counter phase 0, valid).
5. Power-cycle 10 to 20 times and histogram the DAC-to-gate offset and the TDC
   frame position (`time % 1250` of a single pulse per gc, and the 64-period
   index of a single64 pattern): one value each.
6. Recalibrate once: the gate, DAC and decoy positions relative to the second
   all moved. PPS to `pps10_o` is two clk10 cycles.

## Verification

- `sim/pps_timebase_tb.v`, scaled second, behavioural LTC6951: five power cycles
  with PPS skew -40..+40 ns, refclk phase 0.1..4.7 ns and a different SYSREF
  phase before the SYNC. `pps10`, `pps200` and `arm_dist` (42) are identical in
  every run, SYNC is launched on the falling edge with the programmed width, and
  both error flags trip when PPS or SYSREF move.
- `sim/decoy_rng_xfer_tb.v`: refclk phase 0.1..4.9 ns x pps200 offset -150, 0,
  +150 ns. Every clk240 symbol n carries clk200 symbol n - 8.
- `sim/ttl_gate_apd_tb.v`: pattern widths, 6.689 ns from `pps10_i` to the
  first gate edge, and no gate when `ttl_rst` is released with `pps10_i` high.
  The testbench clk480 half period is 1041 ps against 2083 ps for clk240, so
  the two drift by 2 ps per clk240 cycle and the latency depends on when it is
  measured in the run.
- `sim/tdc_clk_rst_mngt_tb.v`, scaled second: `tdc_refclk_o` and
  `tdc_rstidx_o` equal the combinational decode of reference counters on every
  cycle; refclk 40 cycles with 20 high, rstidx 6 cycles centred on a refclk
  rising edge; no start when `tdc_rst` is released with pps200 high; phase
  readback 0 in steady state and 7 after the pps200 edge moves 7 cycles.

Vivado 2024.2 implementation, `bitstream/bit_sep15_det_latency` (md5
d983dbb0041bfd2fbd98856ee9d169c3). All constraints met; pulse width has 0
failing endpoints.

| Path | Setup slack | Hold slack |
|---|---|---|
| Whole design | 0.321 ns | 0.010 ns |
| SYSREF pin to capture flop (1.5..3.5 ns input delay) | 1.071 ns | 0.521 ns |
| PPS pin to clk10 falling-edge flop (+-40 ns) | 9.690 ns | 7.973 ns |
| SYNC flop to pin | 42.386 ns | |
| pps10_o to clk240 consumers | | 0.235 ns |
| Decoy table to rng_a_r (5 ns max delay) | 4.391 ns | |
| clk240 to clk240_serdes (multicycle 2) | 4.773 ns | 0.100 ns |

Clock interaction: clk_10 to refclk carries only the `arm` false path, refclk to
clk240 only the decoy table.

`bitstream/bit_sep17_tdc_phase` (md5 d0e232cc030c0f83d2de351fced7b5b7) adds the
`tdc_clk_rst_mngt` changes: WNS 0.409 ns, WHS 0.010 ns, pulse width 0 failing
endpoints. The `ttl_gate_apd` edge detector change is not in a bitstream yet.

## TTL gate serializer clocks

OSERDESE3 allows CLKDIV to lag CLK by at most 1.56 ns and CLK to lag CLKDIV by
at most 0.27 ns (slow corner). On-chip variation between two separate clock
trees is about 0.4 ns, so delay-matched clocks fail the 0.27 ns side.

- clk240_serdes is a fourth MMCM output (/4, like clk240) on its own BUFG, loaded
  only by the OSERDESE3 CLKDIV and the three delay primitives' CLK. The
  fine_delay control logic stays on clk240.
- clk480 and clk240_serdes are in one CLOCK_DELAY_GROUP with USER_CLOCK_ROOT
  X0Y0, the serializer's clock region.
- clk240_serdes is shifted 56.25 deg (0.651 ns), the middle of the window. The
  max-skew checks report 0.481 ns and 0.437 ns of slack.
- clk240 logic feeding the serializer and the delay primitives is captured on
  the next clk240_serdes edge (multicycle 2 setup, 1 hold).

Simulation commands (xsim, Vivado 2024.2), from an empty directory:

    xvlog --relax $XILINX_VIVADO/data/verilog/src/glbl.v <sources> <tb>
    xelab --relax -L unisims_ver -L secureip <tb> glbl -s tb
    xsim tb -R [--testplusarg PH200=<ps> --testplusarg OFF200=<cycles>]
