// ============================================================================
// tb_basis_rangedec.v -- self-checking testbench
//
// Drives basis_rangedec with the uniform bit stream the C golden model wrote
// to stim.mem, and compares the module's biased-symbol stream against the
// golden stream in expected.mem.  Prints PASS/FAIL.
//
// Generate the .mem files first:
//     gcc -O2 -o biasgen biasgen.c -lm && ./biasgen
// Run with Icarus Verilog:
//     iverilog -g2012 -o tb basis_rangedec.v tb_basis_rangedec.v && vvp tb
// or with Verilator (--binary, recent versions), or any 2001+ simulator.
//
// Handshake model: each cycle the TB presents the next 8 stimulus bits with
// stim[rd] on rnd_in[7] (MSB-first).  The module reports 'take' = bits it
// consumed this cycle; the TB advances its read pointer by 'take' AT the
// clock edge (nonblocking), so both the DUT and the TB see the same rnd_in
// for the edge that consumes those bits.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module tb_basis_rangedec;
    localparam integer VBITS = 131072;     // must match biasgen.c
    localparam integer NSYM  = 20000;      // must match biasgen.c

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    wire [7:0]  rnd_in;
    wire [3:0]  take;
    wire        basis_bit;
    wire        basis_valid;

    // 1-bit-per-line memories loaded by $readmemb
    reg  stim [0:VBITS-1];
    reg  expb [0:NSYM-1];

    integer rd;        // stimulus read pointer
    integer sc;        // symbols produced
    integer errors;

    // ---- DUT ----
    basis_rangedec #(.PREC(15), .P0(16'd3277)) dut (
        .clk         (clk),
        .rst         (rst),
        .rnd_in      (rnd_in),
        .take        (take),
        .basis_bit   (basis_bit),
        .basis_valid (basis_valid)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // present next 8 bits, MSB = stim[rd]  (combinational from rd)
    assign rnd_in = { stim[rd+0], stim[rd+1], stim[rd+2], stim[rd+3],
                      stim[rd+4], stim[rd+5], stim[rd+6], stim[rd+7] };

    // checker + pointer advance, clocked
    always @(posedge clk) begin
        if (rst) begin
            rd     <= 0;
            sc     <= 0;
            errors <= 0;
        end else begin
            if (basis_valid) begin
                if (basis_bit !== expb[sc]) begin
                    if (errors < 10)
                        $display("MISMATCH sym %0d: dut=%b exp=%b (rd=%0d)",
                                 sc, basis_bit, expb[sc], rd);
                    errors <= errors + 1;
                end
                sc <= sc + 1;
            end
            rd <= rd + take;          // advance by bits consumed this edge
        end
    end

    // stimulus / reset / finish
    initial begin
        $readmemb("stim.mem",     stim);
        $readmemb("expected.mem", expb);
        rd = 0; sc = 0; errors = 0;

        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;                   // release reset

        wait (sc == NSYM);

        if (errors == 0)
            $display("PASS: %0d symbols match C golden model (consumed %0d bits)",
                     NSYM, rd);
        else
            $display("FAIL: %0d mismatches out of %0d symbols", errors, NSYM);
        $finish;
    end

    // safety timeout
    initial begin
        #4_000_000;                   // 4 ms >> ~200 us expected
        $display("TIMEOUT: only %0d/%0d symbols produced", sc, NSYM);
        $finish;
    end
endmodule

`default_nettype wire
