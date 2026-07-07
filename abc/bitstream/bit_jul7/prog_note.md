## Description new bitstream
- Adding tunable probability feature to decoy rng and fastdac rng
- Monitor status flags of 2 downstream fifos 1x2 together with 2 upstream fifos 128x16

## Registers map
### Fastdac
- Write value P0 for fastdac rng
- Base : 0x00030000
- Offset : 40 (slv_reg10)
### Decoy
- Writevalue P0 for decoy rng
- Base: 0x00016000
- Offset : 16 (slv_reg4)

## Order of write
- Write register value P0 . for example 3277 corresponding p0 = 0.1
- Write enable register to save value
- Reset rng with fucntion rng_reset() : same as old version

## Monitor fucntion
```
def rng_fifos_mon():
    while(True):
        #Write command
        Write(0x00030000, 0x0)
        Write(0x00030000, 0x2)
        time.sleep(0.01)
        #Read reg
        mon_rng = Read(0x00030000 + 36)
        hex_mon_rng = mon_rng.decode('utf-8').strip()
        rng_af = (int(hex_mon_rng, 16) & 0x80)>>7
        rng_e = (int(hex_mon_rng, 16) & 0x40)>>6
        rng_uv_af = (int(hex_mon_rng, 16) & 0x20)>>5
        rng_uv_e = (int(hex_mon_rng, 16) & 0x10)>>4
        de_rng_af = (int(hex_mon_rng, 16) & 0x8)>>3
        de_rng_e = (int(hex_mon_rng, 16) & 0x4)>>2
        de_rng_uv_af = (int(hex_mon_rng, 16) & 0x2)>>1
        de_rng_uv_e = int(hex_mon_rng, 16) & 0x1
        print(f"rng_af,e: {rng_af},{rng_e},{rng_uv_af},{rng_uv_e} | de_rng_af,e: {de_rng_af},{de_rng_e},{de_rng_uv_af},{de_rng_uv_e}", flush=True)

```

- af : almost_full
- e: empty
- rng : fifo_128x16
- rng_uv : fifo_1x2


