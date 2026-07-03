# Mixed-distribution RNG output architecture

## Goal

Output `dout[3:0]` @ 40 MHz, where each nibble is `{even, uneven, even, uneven}`:

| bit | distribution | source |
|---|---|---|
| `dout[3]` | even (true 50/50) | true RNG |
| `dout[2]` | uneven (biased)   | `basis_rangedec` |
| `dout[1]` | even (true 50/50) | true RNG |
| `dout[0]` | uneven (biased)   | `basis_rangedec` |

The biased bits come from `basis_rangedec`; the even bits stay raw true RNG.

## Fixed interfaces (from `context.md`)

Two things are pinned and the rest of the design works around them:

- **`fifo1` is always 128->16 async.** The input FIFO geometry never changes;
  both split branches reuse this same standard block. Splitting must therefore
  happen *around* `fifo1` instances, not by re-cutting `fifo1`'s width.
- **`fifo2` output is always 4 bits; its *input* width is free.** Because the
  input width is a design knob, we pick it to **minimize conversion in the
  datapath and CDC** -- the recombination of even+uneven bits is done so that
  `fifo2` swallows it with the least repacking.

This reframes the old design: instead of building a wide 16-bit word and
fighting `fifo2`'s word ordering, set `fifo2`'s input to exactly **one nibble
(4 bits)** so each `fifo2` read = one ready-made `{E,U,E,U}` output. See
[The recombine](#the-recombine-at-fifo2-pure-wiring).

## Rate budget (drives the design)

Per 40 MHz tick: 2 true + 2 biased bits.

| Stream | Rate needed | Source |
|---|---|---|
| even bits (2/tick)  | 80 Mbit/s true   | true RNG directly |
| uneven bits (2/tick)| 80 Mbit/s biased | `basis_rangedec` @ **80 MHz** (1 bit/clk = exactly 2 bits/tick) |
| basis entropy draw  | ~0.47 true bit per biased bit -> ~37.5 Mbit/s avg | true RNG |

**Total true-RNG demand ~= 80 + 37.5 ~= 118 Mbit/s avg** -- *less* than the
original 4-true-bits/tick = 160 Mbit/s, because biased bits compress entropy.
So the existing RNG source comfortably feeds both consumers.

This is why running `basis_rangedec` at **80 MHz** (not 200 MHz) matters: at
200 MHz it would over-produce and the wasted-entropy draw (~94 Mbit/s) plus even
bits (80 Mbit/s) would exceed the 160 Mbit/s source.

## Block diagram

```
                    clk_src (async)              clk80                 clk200 / 40 MHz
true RNG 128b
   |
   +-- word demux/arbiter   [SPLIT AT fifo1 INPUT]
   |   (route whole 128b words by backpressure)
   |
   +--> fifo1_up   (128->16 async) -> controller <=> basis_rangedec -1b@80M->
   |     [BASIS ENTROPY PATH]          (rng_ready gate)            basis_bit |
   |                                                                         v
   |                                                      fifo_bias (1->2 async, 80->200)
   |                                                                 2 uneven bits/tick |
   |                                                                                    v
   +--> fifo1_true (128->16 async) ----------------------> bit unpacker      nibble assembler
         [EVEN PATH, read @200M]                            2 even bits/tick-> {E,U,E,U}
                                                                                        |
                                                                       [RECOMBINE AT fifo2]
                                                                                        v
                                                                          fifo2 (4->4) -> dout[3:0] @40MHz
                                                                            read by rd_en_4
```

Both `fifo1_up` and `fifo1_true` are the same 128->16 block (the unchangeable
`fifo1`); only their downstream consumers differ.

## Clock domains

- **clk_src** -- true-RNG producer (async write side of both `fifo1` instances).
- **clk80** -- `controller` + `basis_rangedec` (the `rangedec` datapath, with the
  `rng_ready` startup gate); also the `fifo_bias` write side.
- **clk200** -- even-bit unpack, nibble assembly, and `fifo2`; output nibble
  popped every 5th cycle by the 40 MHz `rd_en_4` pulse.

## Split: demux at the source (the "beginning of fifo1")

A single physical RNG stream feeds a small **word arbiter** in `clk_src` that
routes each incoming 128-bit word to whichever branch's `fifo1` is hungrier
(using `almost_full`/`prog_full` backpressure from `fifo1_up` vs `fifo1_true`).

- Any true bit is interchangeable, so routing whole words by backpressure adds
  **no bias** and keeps both consumers fed.
- The split lives entirely in the `clk_src` domain, *before* either `fifo1`, so
  each branch keeps a clean, independent 128->16 async CDC -- no shared-FIFO
  arbitration across clock domains, and `fifo1` itself is untouched.

## The recombine (at fifo2, pure wiring)

We exploit the free `fifo2` *input* width to make recombination trivial: set
**`fifo2` to 4->4** so its input word *is* one output nibble. The assembler, in
`clk200`, builds each nibble directly from the two streams that have already
crossed into `clk200`:

```
fifo2_din[3] = e1;   // even  (true RNG, from fifo1_true unpacker)
fifo2_din[2] = u1;   // uneven (biased, from fifo_bias)
fifo2_din[1] = e0;   // even
fifo2_din[0] = u0;   // uneven
```

Because the input word equals the output word, **there is no asymmetric
word-ordering to reason about** -- the old 16-bit/4-nibble interleave trick is
gone. One `fifo2` read at 40 MHz yields exactly `{E,U,E,U}`.

*Fallback:* if reusing the existing 16x4 `fifo2` is preferred over instancing a
4x4, build the 16-bit word as four identical `E U E U` nibbles so every emitted
nibble is `E U E U` regardless of unpack order:

```
word[4k+3]=e[2k+1]; word[4k+2]=u[2k+1]; word[4k+1]=e[2k]; word[4k+0]=u[2k];  // k=0..3
```

The 4->4 form is recommended: less repacking, less buffering, simpler timing.

## What to reuse vs build

| Block | Status |
|---|---|
| `fifo1_up` = `fifo_up_wrapper` (128->16 async) | have -- basis entropy path |
| `controller` + `basis_rangedec` + `rng_ready` gate | have (`srcs/rangedec_top_wrapper.v`) |
| biased CDC FIFO 80->200 | reuse `fifo_decoy_1x2_wrapper` as **`fifo_bias` 1->2** (2 uneven bits/tick) |
| `fifo1_true` (128->16 async, read @200 MHz) + bit unpacker | new, small (second `fifo1` instance) |
| source word demux/arbiter | new, small (the split) |
| nibble assembler + `fifo2` | new assembler; **`fifo2` = 4->4** (or reuse existing 16x4 -- see fallback) |

## Open points to confirm

1. **Biased path is rate-matched (80 = 80 Mbit/s)** -- the known knife-edge:
   keep the producer slightly ahead and **drop on `fifo_bias` full**
   (`wr_en = basis_valid & ~full`), and only assemble a nibble when `fifo_bias`
   has its 2 uneven bits ready, so the uneven lanes never underflow into stale
   data. The even path has margin, so it is not at risk.
2. **`rd_en_4`** must be a clean one-`clk200`-cycle pulse at 40 MHz (200/5), same
   as the existing decoy/`fifo2` read expects.
3. **`fifo2` width** -- recommended **4->4** (one nibble per read, zero repack).
   Keeping the existing 16->4 also works via the four-identical-nibbles fallback;
   4->4 wins on timing/buffering simplicity.
4. **Even-bit framing** -- `fifo1_true` gives 16 true bits/read but each nibble
   needs only 2; a small shift/unpack buffer feeds eight nibbles per `fifo1_true`
   read (16 / 2), so reads are infrequent and the even path stays slack.
5. **`rd_en_4` origin** -- confirm whether it is generated upstream or should be
   produced inside this top.
