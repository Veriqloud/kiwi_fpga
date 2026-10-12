# Make an iverilog-friendly copy of ddr_data.v: drop the debug output ports
# (they redeclare internal regs), fix declaration-before-use. Logic unchanged.
import sys,re
src,dst=sys.argv[1],sys.argv[2]
t=open(src).read()
s=t.index('    //Debug\n')
e=t.index(');',s)
head=t[:s].rstrip()
# remove the trailing comma of the last remaining port (comma may precede a comment)
head=re.sub(r',(\s*//[^\n]*)?$', lambda m: (m.group(1) or ''), head)
t=head+'\n'+t[e:]
t=t.replace('    output [47:0]   sr_current_dq_gc,','    output reg [47:0] sr_current_dq_gc,')
t=t.replace('reg [47:0] sr_current_dq_gc;\n','')
t=t.replace('    output          sr_current_dq_gc_valid,','    output wire     sr_current_dq_gc_valid,')
t=t.replace('wire sr_current_dq_gc_valid;\n','')
blk_s=t.index('//Debug signals'); blk_e=t.index('//clock domain changing from 200MHz to 250MHz')
blk=t[blk_s:blk_e]; t=t[:blk_s]+t[blk_e:]
blk=blk.replace('wire [31:0] threshold_wait;\n','').replace('wire [47:0] debug_rc_gc_div; \n','').replace('wire [47:0] debug_rc_gc_div;\n','')
anchor='reg [2:0] state_alpha;\n'
i=t.index(anchor)+len(anchor)
t=t[:i]+'wire [31:0] threshold_wait; wire [47:0] debug_rc_gc_div;\nwire s_axis_tvalid_gc_debug; wire [31:0] dq_gc_start_r_debug;\n'+blk+t[i:]
t=t.replace('reg [31:0] counter_rd_en_gc;\n','',1)
t=t.replace('wire rd_en_fifo_gc;\n','reg [31:0] counter_rd_en_gc;\nwire rd_en_fifo_gc;\n',1)
open(dst,'w').write(t)
