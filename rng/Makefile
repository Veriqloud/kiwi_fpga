# Build/run the biased-bit range-decoder and its verification.
#
#   make verify     # C golden model + RTL-faithful C cross-check
#   make sim        # Verilog testbench (needs iverilog) against the golden .mem
#   make            # both

CC      := gcc
CFLAGS  := -O2 -Wall

.PHONY: all verify sim clean

all: verify sim

# --- C golden model + RTL-algorithm cross-check -----------------------------
biasgen: biasgen.c
	$(CC) $(CFLAGS) -o $@ $< -lm

rtl_model: rtl_model.c
	$(CC) $(CFLAGS) -o $@ $<

# emits stim.mem + expected.mem, prints realized p and entropy budget
stim.mem expected.mem: biasgen
	./biasgen

verify: biasgen rtl_model stim.mem expected.mem
	./biasgen
	./rtl_model

# --- Verilog simulation (Icarus Verilog) ------------------------------------
# Substitute your simulator if not using iverilog.
sim: stim.mem expected.mem basis_rangedec.v tb_basis_rangedec.v
	iverilog -g2012 -o tb_sim basis_rangedec.v tb_basis_rangedec.v
	vvp tb_sim

clean:
	rm -f biasgen rtl_model tb_sim stim.mem expected.mem
