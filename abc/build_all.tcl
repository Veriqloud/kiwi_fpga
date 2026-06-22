# run_all.tcl

puts "Running project setup script..."
source build_project.tcl

puts "Running block design script..."
source build_bd.tcl

puts "Create wrapper for top level block design..."
set design_name [get_bd_designs]
make_wrapper -files [get_files Qline_turnkey_top.bd] -top 

puts "Done."
