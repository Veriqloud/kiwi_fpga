## Integrate rangedec_top_wrapper

Module rangedec_top_warpper.v replace fifos in decoy_rng_fifos.v to output 2 bits of uneven_dout.

Checking on ila_rdec, I got uneven_dout signal. 
But probing rng_a_r signal in decoy.v just return value 2 constantly. Even the decoy_rng_mode already set to 1. 

Tried to used AI suggest constraints or not, it returns the same value 2.

Analyse RTL module, suggest which could be made wrong