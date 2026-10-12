#!/bin/sh
# iverilog runs of the DDR path testbenches. ddr_data.v redeclares its debug
# output ports, which iverilog rejects; mk_iverilog_ddr_data.py writes a copy
# without them (logic unchanged).
set -e
here=$(cd "$(dirname "$0")" && pwd)
srcs="$here/../../srcs"
out=${1:-/tmp/ddr_path_sim}
mkdir -p "$out"
python3 "$here/mk_iverilog_ddr_data.py" "$srcs/ddr4/ddr_data.v" "$out/ddr_data_iv.v"
for m in 0 1 2 3 4; do
  iverilog -g2012 -o "$out/lookup_$m" -Ptb.MODE=$m "$here/ddr_data_lookup_tb.v" \
    "$out/ddr_data_iv.v" "$here/fifo_gc_in_64x64_model.v"
  vvp -n "$out/lookup_$m" | grep -v finish
done
for cfg in "0 0 0" "0 1 0" "1 0 0" "1 1 0" "0 0 1" "0 1 1" "1 0 1"; do
  set -- $cfg
  iverilog -g2012 -o "$out/sys_$1$2$3" -Ptb_sys.TOPO=$1 -Ptb_sys.CUT=$2 -Ptb_sys.QUIESCE=$3 \
    "$here/ddr_path_sys_tb.v" "$out/ddr_data_iv.v" "$here/fifo_gc_in_64x64_model.v" \
    "$srcs/clk_rst/ddr_axi_reset_seq.v" "$srcs/common/reset_register.v"
  echo "===== TOPO=$1 CUT=$2 QUIESCE=$3"
  vvp -n "$out/sys_$1$2$3" | grep -v finish
done
