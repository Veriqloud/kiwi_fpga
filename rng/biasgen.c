/* ============================================================================
 * biasgen.c  --  Bernoulli(p) generator from a uniform bit stream via a
 *                binary range DECODER used as a sampler.
 *
 * Feeding uniform random bits into an arithmetic/range decoder (with no
 * encoder and no message) emits symbols distributed according to the
 * decoder's probability model.  Each symbol costs, on average, H(p) input
 * bits -- the entropy-optimal floor -- because renormalization only pulls
 * fresh bits when the interval has actually shrunk.
 *
 * This file is the GOLDEN MODEL.  It is written so that the Verilog RTL in
 * basis_rangedec.v reproduces its symbol stream bit-for-bit on identical
 * input.  It also:
 *   - emits stim.mem      (uniform input bits, one per line, MSB-first order)
 *   - emits expected.mem  (the golden basis-symbol stream, one per line)
 *   - runs a Monte-Carlo measurement of the REALIZED p (incl. the small
 *     finite-precision distortion from the (range>>PREC) floor) -- this is
 *     the number you record for security accounting.
 *
 * Build:  gcc -O2 -Wall -o biasgen biasgen.c -lm
 * Run:    ./biasgen            (or ./biasgen <seed>)
 * ==========================================================================*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

/* ------- model parameters (must match basis_rangedec.v) ------------------ */
#define PREC        15u             /* probability precision: P0 is Q(PREC)   */
#define P0_Q15      3277u           /* round(0.1 * 2^15); nominal p = P0/2^15 */
#define TOP         (1u << 31)      /* renormalize while range < 2^31         */
#define RANGE_INIT  0xFFFFFFFFu

/* ------- stimulus sizing ------------------------------------------------- */
#define VBITS       131072u         /* uniform bits dumped to stim.mem        */
#define NSYM        20000           /* symbols checked against the RTL        */
#define MCSYM       20000000L       /* symbols for the realized-p measurement */

/* ============================================================================
 * Streaming uniform bit source (xorshift32, MSB-first).
 * Only used to DEFINE a reproducible bit stream; both the golden decoder and
 * the Verilog TB consume exactly these bits (via stim.mem), so the PRNG's
 * statistical quality only affects the Monte-Carlo p estimate, not the
 * C-vs-RTL equivalence check.
 * ==========================================================================*/
static uint32_t g_state = 0;
static uint32_t g_word  = 0;
static int      g_left  = 0;

static int prng_bit(void)
{
    if (g_left == 0) {
        uint32_t x = g_state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        g_state = x;
        g_word  = x;
        g_left  = 32;
    }
    int b = (int)((g_word >> 31) & 1u);   /* take the MSB first */
    g_word <<= 1;
    g_left--;
    return b;
}

/* ============================================================================
 * GOLDEN range decoder.  Bit source is abstracted so we can drive it either
 * from an in-memory stimulus array (for file emission / RTL comparison) or
 * directly from the streaming PRNG (for the long Monte-Carlo run).
 * ==========================================================================*/
typedef struct {
    uint32_t range;
    uint32_t code;
    /* bit source */
    const uint8_t *arr;   /* if non-NULL, read from arr[idx++]               */
    size_t         idx;
    size_t         nbits;
} rdec_t;

static int rdec_next_bit(rdec_t *d)
{
    if (d->arr) {
        /* caller guarantees idx < nbits */
        return (int)d->arr[d->idx++];
    }
    return prng_bit();
}

static void rdec_init(rdec_t *d, const uint8_t *arr, size_t nbits)
{
    d->arr   = arr;
    d->idx   = 0;
    d->nbits = nbits;
    d->range = RANGE_INIT;
    d->code  = 0;
    /* prime: pull 32 bits into code, MSB-first */
    for (int i = 0; i < 32; i++)
        d->code = (d->code << 1) | (uint32_t)rdec_next_bit(d);
}

/* decode one symbol: returns 0 with probability ~ P0/2^PREC */
static int rdec_sym(rdec_t *d)
{
    uint32_t bound = (uint32_t)(((uint64_t)(d->range >> PREC)) * P0_Q15);
    int bit;
    if (d->code < bound) {            /* lower sub-interval -> symbol 0 */
        d->range = bound;
        bit = 0;
    } else {                          /* upper sub-interval -> symbol 1 */
        d->code  -= bound;
        d->range -= bound;
        bit = 1;
    }
    /* renormalize: one fresh bit per shift, MSB-first */
    while (d->range < TOP) {
        d->range <<= 1;
        d->code   = (d->code << 1) | (uint32_t)rdec_next_bit(d);
    }
    return bit;
}

/* ============================================================================ */
int main(int argc, char **argv)
{
    g_state = (argc > 1) ? (uint32_t)strtoul(argv[1], NULL, 10) : 0xDEADBEEFu;
    if (g_state == 0) g_state = 1;          /* xorshift requires nonzero state */

    /* ---- 1. build and dump the uniform stimulus ------------------------- */
    static uint8_t stim[VBITS];
    for (size_t i = 0; i < VBITS; i++)
        stim[i] = (uint8_t)prng_bit();

    FILE *fs = fopen("stim.mem", "w");
    if (!fs) { perror("stim.mem"); return 1; }
    for (size_t i = 0; i < VBITS; i++)
        fprintf(fs, "%d\n", stim[i]);
    fclose(fs);

    /* ---- 2. golden decode -> expected.mem ------------------------------- */
    rdec_t d;
    rdec_init(&d, stim, VBITS);

    FILE *fe = fopen("expected.mem", "w");
    if (!fe) { perror("expected.mem"); return 1; }

    int zeros = 0;
    for (int i = 0; i < NSYM; i++) {
        /* keep an 8-bit lookahead margin for the RTL's input window */
        if (d.idx > VBITS - 8) {
            fprintf(stderr, "stim too short: raise VBITS\n");
            return 1;
        }
        int b = rdec_sym(&d);
        zeros += (b == 0);
        fprintf(fe, "%d\n", b);
    }
    fclose(fe);

    printf("verif : %d symbols, %zu input bits consumed (%.3f bits/sym), "
           "p0_sample=%.5f\n",
           NSYM, d.idx, (double)d.idx / NSYM, (double)zeros / NSYM);

    /* ---- 3. Monte-Carlo: realized p including finite-precision bias ----- */
    rdec_t m;
    rdec_init(&m, NULL, 0);                 /* stream straight from the PRNG  */
    long z = 0;
    for (long i = 0; i < MCSYM; i++)
        if (rdec_sym(&m) == 0) z++;

    double p = (double)z / (double)MCSYM;
    double H = -(p * log2(p) + (1.0 - p) * log2(1.0 - p));
    double nominal = (double)P0_Q15 / 32768.0;

    printf("mc    : %ld symbols, realized p(0)=%.6f  (nominal %.6f, "
           "delta=%+.2e)\n", MCSYM, p, nominal, p - nominal);
    printf("mc    : H(p)=%.4f bits/sym\n", H);
    printf("budget: basis %.1f Mbit/s + state 80.0 Mbit/s = %.1f Mbit/s "
           "@ 80 MHz (supply 200)\n", 80.0 * H, 80.0 * (1.0 + H));

    return 0;
}
