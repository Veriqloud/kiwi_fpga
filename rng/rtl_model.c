/* ============================================================================
 * rtl_model.c -- cycle-faithful transcription of basis_rangedec.v
 *
 * This mirrors the Verilog datapath EXACTLY, operation for operation:
 *   - combinational decode: bound = (range>>PREC)*P0; bit = (code>=bound)
 *   - single-shot renorm via leading-zero count (clz), instead of the
 *     golden model's one-bit-at-a-time while loop
 *   - 8-bit input window with c_norm = (c_sel<<s) | (rnd_in >> (8-s))
 *   - prime FSM: 4 cycles of 8 bits each to fill the 32-bit code register
 *   - 'take' = bits consumed this cycle; a read pointer advances by it
 *
 * It reads the SAME stim.mem the golden model produced and compares its
 * symbol stream against expected.mem.  If this matches, the hardware
 * ALGORITHM (the part of the .v that is easy to get subtly wrong) is proven
 * equivalent to the golden model.  The delivered Verilog testbench runs the
 * identical comparison inside a real simulator (Icarus/Verilator).
 *
 * Build: gcc -O2 -Wall -o rtl_model rtl_model.c
 * Run:   ./rtl_model            (after ./biasgen has written the .mem files)
 * ==========================================================================*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define PREC        15u
#define P0_Q15      3277u
#define RANGE_INIT  0xFFFFFFFFu
#define VBITS       131072
#define NSYM        20000

/* leading-zero count of a 32-bit word (matches the clz32 function in RTL).
 * For this model range_sel is always >= 2^27, so s is in {0,1,3,4}.        */
static int clz32(uint32_t x)
{
    int n = 0;
    for (int i = 31; i >= 0; i--) {
        if ((x >> i) & 1u) break;
        n++;
    }
    return n;
}

int main(void)
{
    static uint8_t stim[VBITS];
    static uint8_t expb[NSYM];

    /* load stimulus (one bit per line) */
    FILE *fs = fopen("stim.mem", "r");
    if (!fs) { perror("stim.mem (run ./biasgen first)"); return 1; }
    for (int i = 0; i < VBITS; i++) {
        int v;
        if (fscanf(fs, "%d", &v) != 1) { fprintf(stderr, "short stim\n"); return 1; }
        stim[i] = (uint8_t)v;
    }
    fclose(fs);

    /* load expected symbols */
    FILE *fe = fopen("expected.mem", "r");
    if (!fe) { perror("expected.mem"); return 1; }
    for (int i = 0; i < NSYM; i++) {
        int v;
        if (fscanf(fe, "%d", &v) != 1) { fprintf(stderr, "short expected\n"); return 1; }
        expb[i] = (uint8_t)v;
    }
    fclose(fe);

    /* ---- RTL state registers ------------------------------------------- */
    uint32_t range  = RANGE_INIT;
    uint32_t code   = 0;
    int      pcnt   = 0;
    int      primed = 0;

    int rd     = 0;     /* stim read pointer (the bit-FIFO position)        */
    int sc     = 0;     /* symbols produced                                 */
    int errors = 0;

    /* clock the model until NSYM symbols have been produced */
    while (sc < NSYM) {
        /* present the next 8 bits, MSB = stim[rd]  (same as TB's rnd_in) */
        uint32_t rnd_in = 0;
        for (int k = 0; k < 8; k++)
            rnd_in = (rnd_in << 1) | stim[rd + k];   /* stim[rd] -> bit 7 */

        int      s;        /* bits consumed this cycle (== 'take')          */
        uint32_t nrange = range, ncode = code;
        int      symbit = 0, valid = 0;

        if (!primed) {
            /* prime cycle: shift 8 fresh bits into code */
            ncode = (code << 8) | rnd_in;
            s     = 8;
            /* state advance handled below */
            range = nrange;
            code  = ncode;
            pcnt += 8;
            if (pcnt == 32) primed = 1;
        } else {
            /* combinational decode */
            uint32_t bound = (uint32_t)(((uint64_t)(range >> PREC)) * P0_Q15);
            int      bit_d = (code >= bound);
            uint32_t r_sel = bit_d ? (range - bound) : bound;
            uint32_t c_sel = bit_d ? (code  - bound) : code;

            s = clz32(r_sel);                          /* renorm shift count */
            uint32_t r_norm = r_sel << s;
            uint32_t c_norm = (c_sel << s) | (s ? (rnd_in >> (8 - s)) : 0u);

            range  = r_norm;
            code   = c_norm;
            symbit = bit_d;
            valid  = 1;
        }

        if (valid) {
            if (symbit != expb[sc]) {
                if (errors < 10)
                    fprintf(stderr,
                            "MISMATCH sym %d: rtl=%d exp=%d (rd=%d)\n",
                            sc, symbit, expb[sc], rd);
                errors++;
            }
            sc++;
        }
        rd += s;                                        /* advance by 'take' */
    }

    if (errors == 0)
        printf("PASS: RTL datapath reproduces all %d golden symbols "
               "(consumed %d bits)\n", NSYM, rd);
    else
        printf("FAIL: %d mismatches\n", errors);

    return errors ? 1 : 0;
}
