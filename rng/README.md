# Biased-bit generator (range decoder)

Generate a Bernoulli(p) stream (here p = 0.1, e.g. an unbalanced basis choice)
from a uniform TRNG bit stream, at the entropy floor of ~H(p) input bits per
output symbol. A binary range *decoder*, fed uniform bits, emits symbols with
the modeled probability; renormalization pulls fresh bits only as the interval
shrinks, so unused entropy stays banked between symbols.

## Files

| file                   | what it is                                                        |
|------------------------|-------------------------------------------------------------------|
| `biasgen.c`            | C golden model. Emits `stim.mem` + `expected.mem`, measures realized p, prints the entropy budget. |
| `rtl_model.c`          | Cycle-faithful C transcription of the RTL datapath (clz single-shot renorm, 8-bit window, prime FSM, `take` handshake). Cross-checks the *hardware algorithm* against the golden model. |
| `basis_rangedec.v`     | Synthesizable module: one biased symbol/cycle once primed.        |
| `tb_basis_rangedec.v`  | Self-checking testbench: drives the module from `stim.mem`, compares to `expected.mem`. |
| `Makefile`             | `make verify` (C) and `make sim` (Verilog).                       |

## Run

```
make verify          # builds biasgen + rtl_model, prints results
make sim             # needs iverilog (or adapt for Verilator)
```

Expected `verify` output (seed-dependent only in the sample column):

```
verif : 20000 symbols, 9370 input bits consumed (0.469 bits/sym), p0_sample=0.099...
mc    : 20000000 symbols, realized p(0)=0.100025  (nominal 0.100006, delta=+1.9e-05)
mc    : H(p)=0.4691 bits/sym
budget: basis 37.5 Mbit/s + state 80.0 Mbit/s = 117.5 Mbit/s @ 80 MHz (supply 200)
PASS: RTL datapath reproduces all 20000 golden symbols (consumed 9370 bits)
```

## Notes for the QKD context

- **Realized p.** It is `P0/2^PREC` plus a small (~2e-5) finite-precision term
  from the `(range>>PREC)` floor. The Monte-Carlo run reports the actual value;
  record *that*, not the nominal, in your security accounting. Raise `PREC`
  (and the multiply width) if you need it tighter, or shrink it for a coarser
  but cleaner p.
- **Runtime-tunable p.** `P0` is a parameter; wire it to a register-map field
  to retune p without rebuilding.
- **State bit.** Balanced and already entropy-optimal: register one raw FIFO
  bit per cycle. Do *not* let any bit feed both the state path and the basis
  decoder -- shared bits correlate basis choice with the key bit.
- **Input quality.** Everything assumes uniform iid input. Residual TRNG bias
  or serial correlation passes straight into the realized p and the state bit;
  condition / health-test upstream.
- **Throughput.** This core does one symbol per clock (single-cycle renorm),
  so it sustains 80 Msym/s at 80 MHz, drawing ~37.5 Mbit/s average from the
  bit-FIFO with bursts up to 4 bits/cycle. Size the FIFO for the burst.
```
