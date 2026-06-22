# run_all.tcl

puts "Running project setup script..."
source build_project.tcl

puts "Running block design script..."
source build_bd.tcl

puts "Create wrapper for top level block design..."
set design_name [get_bd_designs]
set wrapper_file [make_wrapper -files [get_files Qline_turnkey_top.bd] -top]
add_files -norecurse $wrapper_file
set_property top Qline_turnkey_top_wrapper [current_fileset]
update_compile_order -fileset sources_1
puts "Done."
