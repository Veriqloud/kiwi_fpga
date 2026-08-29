set origin_dir "."
set _xil_proj_name_ "Qline_turnkey"
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -force -part xcau25p-ffvb676-2-e
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "board_part_repo_paths" -value "[file normalize "$origin_dir/boards"]" -objects $obj
set_property -name "board_part" -value "opalkelly.com:xem8310-au25p:part0:1.0" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj


# Set user IP repository paths
set_property ip_repo_paths [list \
    [file normalize ./user_intf]
] [current_project]

set obj [current_project]
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [glob -nocomplain "${origin_dir}/srcs/**/*.v" "${origin_dir}/srcs/**/**/*.v" "$origin_dir/ip/*/*.xci"]
# clk_rst_mngt_backup.v declares a second module named clk_rst_mngt; with both in
# the fileset the reference is unresolvable and build_bd.tcl cannot elaborate
set files [lsearch -all -inline -not -glob $files "*_backup.v"]
set added_files [add_files -fileset sources_1 $files]


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/constrs/Qline_turnkey_constrs.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "constrs/Qline_turnkey_constrs.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj


# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

#Update Ip catalog
update_compile_order -fileset sources_1
update_ip_catalog -rebuild -scan_changes
report_ip_status -name ip_status
upgrade_ip [get_ips]
generate_target all [get_ips]
update_compile_order -fileset sources_1
