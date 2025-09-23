# run_all.tcl

puts "Running project setup script..."
source project.tcl

puts "Running block design script..."
source block_design.tcl

puts "Create wrapper for top level block design..."
set design_name [get_bd_designs]
make_wrapper -files [get_files Qline_turnkey_top.bd] -top 

puts "Done."
