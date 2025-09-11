
################################################################
# This is a generated script based on design: Qline_turnkey_top
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2024.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source Qline_turnkey_top_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# pcierefclk, ttl_gate_apd, spi_inout_mngt, sync_tx_tready, jesd204b_tx_wrapper, jesd_transport, led_test, clk_rst_mngt, axi_virtual_controller_wrapper, axi_clock_converter_rtl, fifos_out, mon_ddr_fifos, ddr_data_reg_mngt, ddr_data, decoy, decoy_rng_fifos, spi_inout_mngt, tdc_clk_rst_mngt, OLVDS_TDC, ILVDS_TDC, fifo_gc_tdc_rtl, TDC_REG_MNGT_v1_0, AS6501_IF

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcau25p-ffvb676-2-e
   set_property BOARD_PART opalkelly.com:xem8310-au25p:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name Qline_turnkey_top

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xdma:4.1\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:axi_quad_spi:3.2\
xilinx.com:ip:jesd204_phy:4.1\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:ddr4:2.2\
xilinx.com:ip:system_ila:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
pcierefclk\
ttl_gate_apd\
spi_inout_mngt\
sync_tx_tready\
jesd204b_tx_wrapper\
jesd_transport\
led_test\
clk_rst_mngt\
axi_virtual_controller_wrapper\
axi_clock_converter_rtl\
fifos_out\
mon_ddr_fifos\
ddr_data_reg_mngt\
ddr_data\
decoy\
decoy_rng_fifos\
spi_inout_mngt\
tdc_clk_rst_mngt\
OLVDS_TDC\
ILVDS_TDC\
fifo_gc_tdc_rtl\
TDC_REG_MNGT_v1_0\
AS6501_IF\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: tdc_mngt
proc create_hier_cell_tdc_mngt { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tdc_mngt() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS2


  # Create pins
  create_bd_pin -dir I -type clk m_axi_tclk
  create_bd_pin -dir I -type clk s_axil_aclk
  create_bd_pin -dir I -type rst s_axil_aresetn
  create_bd_pin -dir I lclk_i
  create_bd_pin -dir I linterrupt_i_0
  create_bd_pin -dir I frame_i
  create_bd_pin -dir I sdi_i
  create_bd_pin -dir O -from 31 -to 0 stopa_sim_limit
  create_bd_pin -dir I -type rst gc_rst
  create_bd_pin -dir I ext_pps
  create_bd_pin -dir O -from 47 -to 0 gc
  create_bd_pin -dir O -from 47 -to 0 gc_time_valid
  create_bd_pin -dir O debug_tdc_tvalid
  create_bd_pin -dir O -from 31 -to 0 debug_tdc_tdata
  create_bd_pin -dir O -from 127 -to 0 debug_s_axis_tdata
  create_bd_pin -dir O debug_s_axis_tvalid
  create_bd_pin -dir O start_gc_o
  create_bd_pin -dir O tvalid200
  create_bd_pin -dir I clk200
  create_bd_pin -dir I rd_en_4
  create_bd_pin -dir O -from 31 -to 0 tdata200
  create_bd_pin -dir O stopa_sim_enable_o
  create_bd_pin -dir I lrst_i
  create_bd_pin -dir O -from 15 -to 0 tdata200_mod
  create_bd_pin -dir O -from 31 -to 0 gate_pos0
  create_bd_pin -dir O -from 31 -to 0 gate_pos1
  create_bd_pin -dir O -from 31 -to 0 gate_pos2
  create_bd_pin -dir O -from 31 -to 0 gate_pos3
  create_bd_pin -dir O -from 3 -to 0 time_ref_gc
  create_bd_pin -dir O -from 5 -to 0 index_shift_gc
  create_bd_pin -dir O -from 3 -to 0 q_gc_time_valid_mod16

  # Create instance: fifo_gc_tdc_rtl_0, and set properties
  set block_name fifo_gc_tdc_rtl
  set block_cell_name fifo_gc_tdc_rtl_0
  if { [catch {set fifo_gc_tdc_rtl_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_gc_tdc_rtl_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_intf_pins /tdc/tdc_mngt/fifo_gc_tdc_rtl_0/m_axis]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_pins /tdc/tdc_mngt/fifo_gc_tdc_rtl_0/m_aclk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   CONFIG.ASSOCIATED_BUSIF {s_axis} \
 ] [get_bd_pins /tdc/tdc_mngt/fifo_gc_tdc_rtl_0/s_aclk]

  # Create instance: TDC_REG_MNGT_v1_0_0, and set properties
  set block_name TDC_REG_MNGT_v1_0
  set block_cell_name TDC_REG_MNGT_v1_0_0
  if { [catch {set TDC_REG_MNGT_v1_0_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $TDC_REG_MNGT_v1_0_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.C_s_axil_ADDR_WIDTH {12} $TDC_REG_MNGT_v1_0_0


  # Create instance: AS6501_IF_0, and set properties
  set block_name AS6501_IF
  set block_cell_name AS6501_IF_0
  if { [catch {set AS6501_IF_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $AS6501_IF_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_intf_pins /tdc/tdc_mngt/AS6501_IF_0/m_axis]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /tdc/tdc_mngt/AS6501_IF_0/m_axis_clk]

  # Create interface connections
  connect_bd_intf_net -intf_net AS6501_IF_0_m_axis [get_bd_intf_pins AS6501_IF_0/m_axis] [get_bd_intf_pins fifo_gc_tdc_rtl_0/s_axis]
  connect_bd_intf_net -intf_net S_AXIL_PCIE_1 [get_bd_intf_pins s_axil] [get_bd_intf_pins TDC_REG_MNGT_v1_0_0/s_axil]
  connect_bd_intf_net -intf_net TDC_REG_MNGT_v1_0_0_mr [get_bd_intf_pins TDC_REG_MNGT_v1_0_0/mr] [get_bd_intf_pins AS6501_IF_0/sr]
  connect_bd_intf_net -intf_net fifo_gc_tdc_rtl_0_m_axis [get_bd_intf_pins M_AXIS2] [get_bd_intf_pins fifo_gc_tdc_rtl_0/m_axis]

  # Create port connections
  connect_bd_net -net AS6501_IF_0_debug_s_axis_tdata  [get_bd_pins AS6501_IF_0/debug_m_axis_data] \
  [get_bd_pins debug_s_axis_tdata]
  connect_bd_net -net AS6501_IF_0_debug_s_axis_tvalid  [get_bd_pins AS6501_IF_0/debug_m_axis_valid] \
  [get_bd_pins debug_s_axis_tvalid]
  connect_bd_net -net AS6501_IF_0_debug_tdc_tdata  [get_bd_pins AS6501_IF_0/debug_tdc_data] \
  [get_bd_pins debug_tdc_tdata]
  connect_bd_net -net AS6501_IF_0_debug_tdc_tvalid  [get_bd_pins AS6501_IF_0/debug_tdc_valid] \
  [get_bd_pins debug_tdc_tvalid]
  connect_bd_net -net AS6501_IF_0_fifo_calib_rst  [get_bd_pins AS6501_IF_0/fifo_calib_rst] \
  [get_bd_pins fifo_gc_tdc_rtl_0/s_aresetn]
  connect_bd_net -net AS6501_IF_0_gate_pos0  [get_bd_pins AS6501_IF_0/gate_pos0] \
  [get_bd_pins gate_pos0]
  connect_bd_net -net AS6501_IF_0_gate_pos1  [get_bd_pins AS6501_IF_0/gate_pos1] \
  [get_bd_pins gate_pos1]
  connect_bd_net -net AS6501_IF_0_gate_pos2  [get_bd_pins AS6501_IF_0/gate_pos2] \
  [get_bd_pins gate_pos2]
  connect_bd_net -net AS6501_IF_0_gate_pos3  [get_bd_pins AS6501_IF_0/gate_pos3] \
  [get_bd_pins gate_pos3]
  connect_bd_net -net AS6501_IF_0_gc  [get_bd_pins AS6501_IF_0/gc] \
  [get_bd_pins gc]
  connect_bd_net -net AS6501_IF_0_gc_time_valid  [get_bd_pins AS6501_IF_0/gc_time_valid] \
  [get_bd_pins gc_time_valid]
  connect_bd_net -net AS6501_IF_0_index_shift_gc  [get_bd_pins AS6501_IF_0/index_shift_gc] \
  [get_bd_pins index_shift_gc]
  connect_bd_net -net AS6501_IF_0_q_gc_time_valid_mod16  [get_bd_pins AS6501_IF_0/q_gc_time_valid_mod16] \
  [get_bd_pins q_gc_time_valid_mod16]
  connect_bd_net -net AS6501_IF_0_start_gc_o  [get_bd_pins AS6501_IF_0/start_gc_o] \
  [get_bd_pins start_gc_o]
  connect_bd_net -net AS6501_IF_0_tdata200  [get_bd_pins AS6501_IF_0/tdata200] \
  [get_bd_pins tdata200]
  connect_bd_net -net AS6501_IF_0_tdata200_mod  [get_bd_pins AS6501_IF_0/tdata200_mod] \
  [get_bd_pins tdata200_mod]
  connect_bd_net -net AS6501_IF_0_time_ref_gc  [get_bd_pins AS6501_IF_0/time_ref_gc] \
  [get_bd_pins time_ref_gc]
  connect_bd_net -net AS6501_IF_0_tvalid200  [get_bd_pins AS6501_IF_0/tvalid200] \
  [get_bd_pins tvalid200]
  connect_bd_net -net ILVDS_TDC_0_O_frameA  [get_bd_pins frame_i] \
  [get_bd_pins AS6501_IF_0/frame_i]
  connect_bd_net -net ILVDS_TDC_0_O_lclk  [get_bd_pins lclk_i] \
  [get_bd_pins AS6501_IF_0/lclk_i]
  connect_bd_net -net ILVDS_TDC_0_O_sdiA  [get_bd_pins sdi_i] \
  [get_bd_pins AS6501_IF_0/sdi_i]
  connect_bd_net -net TDC_REG_MNGT_v1_0_0_stopa_sim_enable_o  [get_bd_pins TDC_REG_MNGT_v1_0_0/stopa_sim_enable_o] \
  [get_bd_pins stopa_sim_enable_o]
  connect_bd_net -net TDC_REG_MNGT_v1_0_0_stopa_sim_limit  [get_bd_pins TDC_REG_MNGT_v1_0_0/stopa_sim_limit] \
  [get_bd_pins stopa_sim_limit]
  connect_bd_net -net clk200_1  [get_bd_pins clk200] \
  [get_bd_pins AS6501_IF_0/m_axis_clk] \
  [get_bd_pins AS6501_IF_0/clk200_i] \
  [get_bd_pins fifo_gc_tdc_rtl_0/s_aclk]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins AS6501_IF_0/pps_i]
  connect_bd_net -net gc_rst_1  [get_bd_pins gc_rst] \
  [get_bd_pins AS6501_IF_0/gc_rst]
  connect_bd_net -net lclk_i_1  [get_bd_pins s_axil_aclk] \
  [get_bd_pins TDC_REG_MNGT_v1_0_0/s_axil_aclk]
  connect_bd_net -net linterrupt_i_0_1  [get_bd_pins linterrupt_i_0] \
  [get_bd_pins AS6501_IF_0/linterrupt_i]
  connect_bd_net -net lrst_i_1  [get_bd_pins lrst_i] \
  [get_bd_pins AS6501_IF_0/lrst_i]
  connect_bd_net -net lrstn_i_1  [get_bd_pins s_axil_aresetn] \
  [get_bd_pins TDC_REG_MNGT_v1_0_0/s_axil_aresetn]
  connect_bd_net -net m_axi_tclk_1  [get_bd_pins m_axi_tclk] \
  [get_bd_pins fifo_gc_tdc_rtl_0/m_aclk]
  connect_bd_net -net rd_en_4_1  [get_bd_pins rd_en_4] \
  [get_bd_pins AS6501_IF_0/rd_en_4]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: clk_rst_buffer
proc create_hier_cell_clk_rst_buffer { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_clk_rst_buffer() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv Veriqloud:tdc:ext_in_rtl:1.0 tdc_ext_in

  create_bd_intf_pin -mode Master -vlnv Veriqloud:tdc:ext_clkrst_rtl:1.0 tdc_ext_clkrst


  # Create pins
  create_bd_pin -dir O O_frameA
  create_bd_pin -dir O O_sdiA
  create_bd_pin -dir I ext_pps
  create_bd_pin -dir O probe_tdc_refclk
  create_bd_pin -dir O probe_tdc_rstidx
  create_bd_pin -dir O pps_trigger
  create_bd_pin -dir O stopa_sim_0
  create_bd_pin -dir O O_lclk
  create_bd_pin -dir I clk200_i
  create_bd_pin -dir I -type rst tdc_rst
  create_bd_pin -dir I -from 31 -to 0 stopa_sim_limit
  create_bd_pin -dir I stopa_sim_enable_i

  # Create instance: tdc_clk_rst_mngt_0, and set properties
  set block_name tdc_clk_rst_mngt
  set block_cell_name tdc_clk_rst_mngt_0
  if { [catch {set tdc_clk_rst_mngt_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $tdc_clk_rst_mngt_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: OLVDS_TDC_0, and set properties
  set block_name OLVDS_TDC
  set block_cell_name OLVDS_TDC_0
  if { [catch {set OLVDS_TDC_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $OLVDS_TDC_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ILVDS_TDC_0, and set properties
  set block_name ILVDS_TDC
  set block_cell_name ILVDS_TDC_0
  if { [catch {set ILVDS_TDC_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ILVDS_TDC_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins tdc_ext_clkrst] [get_bd_intf_pins OLVDS_TDC_0/tdc_ext_clkrst]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins tdc_ext_in] [get_bd_intf_pins ILVDS_TDC_0/tdc_ext_in]

  # Create port connections
  connect_bd_net -net ILVDS_TDC_0_O_frameA  [get_bd_pins ILVDS_TDC_0/O_frameA] \
  [get_bd_pins O_frameA]
  connect_bd_net -net ILVDS_TDC_0_O_lclk  [get_bd_pins ILVDS_TDC_0/O_lclk] \
  [get_bd_pins O_lclk]
  connect_bd_net -net ILVDS_TDC_0_O_sdiA  [get_bd_pins ILVDS_TDC_0/O_sdiA] \
  [get_bd_pins O_sdiA]
  connect_bd_net -net TDC_wrapper_0_tdc_refclk_o  [get_bd_pins tdc_clk_rst_mngt_0/tdc_refclk_o] \
  [get_bd_pins probe_tdc_refclk] \
  [get_bd_pins OLVDS_TDC_0/tdc_reflck]
  connect_bd_net -net TDC_wrapper_0_tdc_rstidxp_o -boundary_type lower  [get_bd_pins probe_tdc_rstidx]
  connect_bd_net -net clk200_i_1  [get_bd_pins clk200_i] \
  [get_bd_pins tdc_clk_rst_mngt_0/clk200_i] \
  [get_bd_pins OLVDS_TDC_0/tdc_lclki]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins tdc_clk_rst_mngt_0/pps_i]
  connect_bd_net -net stopa_sim_enable_i_1  [get_bd_pins stopa_sim_enable_i] \
  [get_bd_pins tdc_clk_rst_mngt_0/stopa_sim_enable_i]
  connect_bd_net -net stopa_sim_limit_1  [get_bd_pins stopa_sim_limit] \
  [get_bd_pins tdc_clk_rst_mngt_0/stopa_sim_limit_i]
  connect_bd_net -net tdc_clk_rst_mngt_0_stopa_sim  [get_bd_pins tdc_clk_rst_mngt_0/stopa_sim] \
  [get_bd_pins stopa_sim_0]
  connect_bd_net -net tdc_clk_rst_mngt_0_tdc_pps_trigger  [get_bd_pins tdc_clk_rst_mngt_0/pps_trigger] \
  [get_bd_pins pps_trigger]
  connect_bd_net -net tdc_clk_rst_mngt_0_tdc_rstidx_o  [get_bd_pins tdc_clk_rst_mngt_0/tdc_rstidx_o] \
  [get_bd_pins OLVDS_TDC_0/tdc_rstidx]
  connect_bd_net -net tdc_rst_1  [get_bd_pins tdc_rst] \
  [get_bd_pins tdc_clk_rst_mngt_0/tdc_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: time_spi
proc create_hier_cell_time_spi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_time_spi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv Veriqloud:com:ext_spi_rtl:1.0 com_ext_spi_tdc


  # Create pins
  create_bd_pin -dir I -type clk s_axil_aclk
  create_bd_pin -dir I -type rst s_axil_aresetn
  create_bd_pin -dir I -type clk clk10_i
  create_bd_pin -dir O rst_jic_0

  # Create instance: axi_quad_spi_0, and set properties
  set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_0 ]
  set_property CONFIG.C_NUM_SS_BITS {2} $axi_quad_spi_0


  # Create instance: spi_inout_mngt_0, and set properties
  set block_name spi_inout_mngt
  set block_cell_name spi_inout_mngt_0
  if { [catch {set spi_inout_mngt_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $spi_inout_mngt_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.NBR_OF_SLAVE {2} $spi_inout_mngt_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins com_ext_spi_tdc] [get_bd_intf_pins spi_inout_mngt_0/com_ext_spi]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins AXI_LITE] [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]

  # Create port connections
  connect_bd_net -net axi_quad_spi_0_io0_o  [get_bd_pins axi_quad_spi_0/io0_o] \
  [get_bd_pins spi_inout_mngt_0/in0_i]
  connect_bd_net -net axi_quad_spi_0_io0_t  [get_bd_pins axi_quad_spi_0/io0_t] \
  [get_bd_pins spi_inout_mngt_0/in0t_i]
  connect_bd_net -net axi_quad_spi_0_io1_o  [get_bd_pins axi_quad_spi_0/io1_o] \
  [get_bd_pins spi_inout_mngt_0/in1_i]
  connect_bd_net -net axi_quad_spi_0_io1_t  [get_bd_pins axi_quad_spi_0/io1_t] \
  [get_bd_pins spi_inout_mngt_0/in1t_i]
  connect_bd_net -net axi_quad_spi_0_sck_o  [get_bd_pins axi_quad_spi_0/sck_o] \
  [get_bd_pins spi_inout_mngt_0/sck_i]
  connect_bd_net -net axi_quad_spi_0_sck_t  [get_bd_pins axi_quad_spi_0/sck_t] \
  [get_bd_pins spi_inout_mngt_0/sckt_i]
  connect_bd_net -net axi_quad_spi_0_ss_o  [get_bd_pins axi_quad_spi_0/ss_o] \
  [get_bd_pins spi_inout_mngt_0/ss_i]
  connect_bd_net -net axi_quad_spi_0_ss_t  [get_bd_pins axi_quad_spi_0/ss_t] \
  [get_bd_pins spi_inout_mngt_0/sst_i]
  connect_bd_net -net clk10_i_1  [get_bd_pins clk10_i] \
  [get_bd_pins axi_quad_spi_0/ext_spi_clk]
  connect_bd_net -net s_axil_aclk_1  [get_bd_pins s_axil_aclk] \
  [get_bd_pins axi_quad_spi_0/s_axi_aclk]
  connect_bd_net -net s_axil_aresetn_1  [get_bd_pins s_axil_aresetn] \
  [get_bd_pins axi_quad_spi_0/s_axi_aresetn]
  connect_bd_net -net spi_inout_mngt_0_out0_o  [get_bd_pins spi_inout_mngt_0/out0_o] \
  [get_bd_pins axi_quad_spi_0/io0_i]
  connect_bd_net -net spi_inout_mngt_0_out1_o  [get_bd_pins spi_inout_mngt_0/out1_o] \
  [get_bd_pins axi_quad_spi_0/io1_i]
  connect_bd_net -net spi_inout_mngt_0_rst_jic  [get_bd_pins spi_inout_mngt_0/rst_jic] \
  [get_bd_pins rst_jic_0]
  connect_bd_net -net spi_inout_mngt_0_sck_o  [get_bd_pins spi_inout_mngt_0/sck_o] \
  [get_bd_pins axi_quad_spi_0/sck_i]
  connect_bd_net -net spi_inout_mngt_0_ss_o  [get_bd_pins spi_inout_mngt_0/ss_o] \
  [get_bd_pins axi_quad_spi_0/ss_i]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: decoy
proc create_hier_cell_decoy { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_decoy() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis


  # Create pins
  create_bd_pin -dir I clk240
  create_bd_pin -dir I -from 3 -to 0 rng_value
  create_bd_pin -dir I rd_en_4
  create_bd_pin -dir I -from 0 -to 0 ext_pps
  create_bd_pin -dir O decoy_signal_p_0
  create_bd_pin -dir O decoy_signal_n_0
  create_bd_pin -dir O decoy_signal_0
  create_bd_pin -dir I -type clk s_axil_aclk
  create_bd_pin -dir I -type rst s_axil_aresetn
  create_bd_pin -dir I -type rst decoy_rst
  create_bd_pin -dir I clk80
  create_bd_pin -dir I clk200
  create_bd_pin -dir I -type rst tx_core_rst
  create_bd_pin -dir I rd_en_16
  create_bd_pin -dir I -type clk s_axis_clk
  create_bd_pin -dir I s_axis_tresetn
  create_bd_pin -dir O -from 1 -to 0 rng_a

  # Create instance: decoy_0, and set properties
  set block_name decoy
  set block_cell_name decoy_0
  if { [catch {set decoy_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $decoy_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: decoy_rng_fifos_0, and set properties
  set block_name decoy_rng_fifos
  set block_cell_name decoy_rng_fifos_0
  if { [catch {set decoy_rng_fifos_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $decoy_rng_fifos_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_pins /decoy/decoy_rng_fifos_0/s_axis_clk]

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [list \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {3} \
    CONFIG.C_PROBE0_WIDTH {2} \
    CONFIG.C_PROBE1_WIDTH {3} \
    CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {1} \
  ] $ila_0


  # Create instance: ila_1, and set properties
  set ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_1 ]
  set_property -dict [list \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {4} \
    CONFIG.C_PROBE1_WIDTH {4} \
    CONFIG.C_PROBE2_WIDTH {2} \
    CONFIG.C_PROBE3_WIDTH {3} \
  ] $ila_1


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axil] [get_bd_intf_pins decoy_0/s_axil]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axis] [get_bd_intf_pins decoy_rng_fifos_0/s_axis]

  # Create port connections
  connect_bd_net -net clk200_1  [get_bd_pins clk200] \
  [get_bd_pins ila_1/clk] \
  [get_bd_pins decoy_0/clk200] \
  [get_bd_pins decoy_rng_fifos_0/clk200]
  connect_bd_net -net clk80_1  [get_bd_pins clk80] \
  [get_bd_pins decoy_0/clk80]
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins clk240] \
  [get_bd_pins ila_0/clk] \
  [get_bd_pins decoy_0/clk240]
  connect_bd_net -net decoy_0_decoy_signal  [get_bd_pins decoy_0/decoy_signal] \
  [get_bd_pins decoy_signal_0]
  connect_bd_net -net decoy_0_decoy_signal_n  [get_bd_pins decoy_0/decoy_signal_n] \
  [get_bd_pins decoy_signal_n_0]
  connect_bd_net -net decoy_0_decoy_signal_p  [get_bd_pins decoy_0/decoy_signal_p] \
  [get_bd_pins decoy_signal_p_0]
  connect_bd_net -net decoy_0_rd_en_4_r  [get_bd_pins decoy_0/rd_en_4_r] \
  [get_bd_pins ila_0/probe1]
  connect_bd_net -net decoy_0_rng_a  [get_bd_pins decoy_0/rng_a] \
  [get_bd_pins rng_a] \
  [get_bd_pins ila_1/probe2]
  connect_bd_net -net decoy_0_rng_a_r  [get_bd_pins decoy_0/rng_a_r] \
  [get_bd_pins ila_0/probe0]
  connect_bd_net -net decoy_rng_fifos_0_de_rng_dout4  [get_bd_pins decoy_rng_fifos_0/de_rng_dout4] \
  [get_bd_pins decoy_0/rng_value]
  connect_bd_net -net decoy_rst_1  [get_bd_pins decoy_rst] \
  [get_bd_pins decoy_0/decoy_rst]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins ila_0/probe2] \
  [get_bd_pins ila_1/probe0] \
  [get_bd_pins decoy_0/pps_i]
  connect_bd_net -net probe7_1  [get_bd_pins rd_en_4] \
  [get_bd_pins ila_1/probe3] \
  [get_bd_pins decoy_0/rd_en_4] \
  [get_bd_pins decoy_rng_fifos_0/rd_en_4]
  connect_bd_net -net rd_en_16_1  [get_bd_pins rd_en_16] \
  [get_bd_pins decoy_rng_fifos_0/rd_en_16]
  connect_bd_net -net rng_value_1  [get_bd_pins rng_value] \
  [get_bd_pins ila_1/probe1]
  connect_bd_net -net s_axil_aclk_1  [get_bd_pins s_axil_aclk] \
  [get_bd_pins decoy_0/s_axil_aclk]
  connect_bd_net -net s_axil_aresetn_1  [get_bd_pins s_axil_aresetn] \
  [get_bd_pins decoy_0/s_axil_aresetn]
  connect_bd_net -net s_axis_clk_1  [get_bd_pins s_axis_clk] \
  [get_bd_pins decoy_rng_fifos_0/s_axis_clk]
  connect_bd_net -net s_axis_tresetn_1  [get_bd_pins s_axis_tresetn] \
  [get_bd_pins decoy_rng_fifos_0/s_axis_tresetn]
  connect_bd_net -net tx_core_rst_1  [get_bd_pins tx_core_rst] \
  [get_bd_pins decoy_rng_fifos_0/tx_core_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tdc
proc create_hier_cell_tdc { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tdc() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXIL_PCIE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS1

  create_bd_intf_pin -mode Slave -vlnv Veriqloud:tdc:ext_in_rtl:1.0 tdc_ext_in

  create_bd_intf_pin -mode Master -vlnv Veriqloud:tdc:ext_clkrst_rtl:1.0 tdc_ext_clkrst

  create_bd_intf_pin -mode Slave -vlnv Veriqloud:com:ext_spi_rtl:1.0 com_ext_spi_tdc


  # Create pins
  create_bd_pin -dir I -type clk m_axi_tclk
  create_bd_pin -dir O probe_tdc_refclk
  create_bd_pin -dir O probe_tdc_rstidx
  create_bd_pin -dir I ext_pps
  create_bd_pin -dir O pps_trigger
  create_bd_pin -dir I clk10_i
  create_bd_pin -dir I linterrupt_i_0
  create_bd_pin -dir I -type clk s_axil_aclk
  create_bd_pin -dir I -type rst s_axil_aresetn
  create_bd_pin -dir O stopa_sim_0
  create_bd_pin -dir I clk200_i
  create_bd_pin -dir I -type rst tdc_rst
  create_bd_pin -dir I -type rst gc_rst
  create_bd_pin -dir O -from 0 -to 0 O_lclk
  create_bd_pin -dir I lrst_i
  create_bd_pin -dir O tvalid200
  create_bd_pin -dir O -from 31 -to 0 tdata200
  create_bd_pin -dir O -from 15 -to 0 tdata200_mod
  create_bd_pin -dir I rd_en_4
  create_bd_pin -dir O -from 31 -to 0 gate_pos0
  create_bd_pin -dir O -from 31 -to 0 gate_pos1
  create_bd_pin -dir O -from 31 -to 0 gate_pos2
  create_bd_pin -dir O -from 31 -to 0 gate_pos3
  create_bd_pin -dir I -from 3 -to 0 rng_value
  create_bd_pin -dir O -from 47 -to 0 gc_time_valid
  create_bd_pin -dir O -from 3 -to 0 q_gc_time_valid_mod16
  create_bd_pin -dir O rst_jic_0

  # Create instance: time_spi
  create_hier_cell_time_spi $hier_obj time_spi

  # Create instance: clk_rst_buffer
  create_hier_cell_clk_rst_buffer $hier_obj clk_rst_buffer

  # Create instance: tdc_mngt
  create_hier_cell_tdc_mngt $hier_obj tdc_mngt

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [list \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {11} \
  ] $ila_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins tdc_ext_clkrst] [get_bd_intf_pins clk_rst_buffer/tdc_ext_clkrst]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins tdc_ext_in] [get_bd_intf_pins clk_rst_buffer/tdc_ext_in]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins AXI_LITE] [get_bd_intf_pins time_spi/AXI_LITE]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins M_AXIS1] [get_bd_intf_pins tdc_mngt/M_AXIS2]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins com_ext_spi_tdc] [get_bd_intf_pins time_spi/com_ext_spi_tdc]
  connect_bd_intf_net -intf_net S_AXIL_PCIE_1 [get_bd_intf_pins S_AXIL_PCIE] [get_bd_intf_pins tdc_mngt/s_axil]

  # Create port connections
  connect_bd_net -net ILVDS_TDC_0_O_frameA  [get_bd_pins clk_rst_buffer/O_frameA] \
  [get_bd_pins tdc_mngt/frame_i] \
  [get_bd_pins ila_0/probe0]
  connect_bd_net -net ILVDS_TDC_0_O_sdiA  [get_bd_pins clk_rst_buffer/O_sdiA] \
  [get_bd_pins tdc_mngt/sdi_i] \
  [get_bd_pins ila_0/probe1]
  connect_bd_net -net TDC_wrapper_0_tdc_refclk_o  [get_bd_pins clk_rst_buffer/probe_tdc_refclk] \
  [get_bd_pins probe_tdc_refclk] \
  [get_bd_pins ila_0/probe2]
  connect_bd_net -net TDC_wrapper_0_tdc_rstidxp_o  [get_bd_pins clk_rst_buffer/probe_tdc_rstidx] \
  [get_bd_pins probe_tdc_rstidx] \
  [get_bd_pins ila_0/probe3]
  connect_bd_net -net clk10_i_1  [get_bd_pins clk10_i] \
  [get_bd_pins time_spi/clk10_i]
  connect_bd_net -net clk200_i_1  [get_bd_pins clk200_i] \
  [get_bd_pins clk_rst_buffer/clk200_i] \
  [get_bd_pins tdc_mngt/clk200] \
  [get_bd_pins ila_0/clk]
  connect_bd_net -net clk_rst_buffer_stopa_sim_0  [get_bd_pins clk_rst_buffer/stopa_sim_0] \
  [get_bd_pins stopa_sim_0]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins clk_rst_buffer/ext_pps] \
  [get_bd_pins tdc_mngt/ext_pps] \
  [get_bd_pins ila_0/probe4]
  connect_bd_net -net gc_rst_1  [get_bd_pins gc_rst] \
  [get_bd_pins tdc_mngt/gc_rst]
  connect_bd_net -net lclk_i_1  [get_bd_pins clk_rst_buffer/O_lclk] \
  [get_bd_pins tdc_mngt/lclk_i] \
  [get_bd_pins O_lclk]
  connect_bd_net -net linterrupt_i_0_1  [get_bd_pins linterrupt_i_0] \
  [get_bd_pins tdc_mngt/linterrupt_i_0]
  connect_bd_net -net lrst_i_1  [get_bd_pins lrst_i] \
  [get_bd_pins tdc_mngt/lrst_i]
  connect_bd_net -net m_axi_tclk_1  [get_bd_pins m_axi_tclk] \
  [get_bd_pins tdc_mngt/m_axi_tclk]
  connect_bd_net -net probe19_1 -boundary_type lower  [get_bd_pins rng_value]
  connect_bd_net -net rd_en_4_1  [get_bd_pins rd_en_4] \
  [get_bd_pins tdc_mngt/rd_en_4]
  connect_bd_net -net s_axil_aclk_1  [get_bd_pins s_axil_aclk] \
  [get_bd_pins time_spi/s_axil_aclk] \
  [get_bd_pins tdc_mngt/s_axil_aclk]
  connect_bd_net -net s_axil_aresetn_1  [get_bd_pins s_axil_aresetn] \
  [get_bd_pins time_spi/s_axil_aresetn] \
  [get_bd_pins tdc_mngt/s_axil_aresetn]
  connect_bd_net -net stopa_sim_limit_1  [get_bd_pins tdc_mngt/stopa_sim_limit] \
  [get_bd_pins clk_rst_buffer/stopa_sim_limit]
  connect_bd_net -net tdc_clk_rst_mngt_0_pps_trigger  [get_bd_pins clk_rst_buffer/pps_trigger] \
  [get_bd_pins pps_trigger]
  connect_bd_net -net tdc_mngt_debug_s_axis_tdata  [get_bd_pins tdc_mngt/debug_s_axis_tdata] \
  [get_bd_pins ila_0/probe9]
  connect_bd_net -net tdc_mngt_debug_s_axis_tvalid  [get_bd_pins tdc_mngt/debug_s_axis_tvalid] \
  [get_bd_pins ila_0/probe8]
  connect_bd_net -net tdc_mngt_debug_tdc_tdata -boundary_type upper  [get_bd_pins tdc_mngt/debug_tdc_tdata]
  connect_bd_net -net tdc_mngt_debug_tdc_tvalid  [get_bd_pins tdc_mngt/debug_tdc_tvalid] \
  [get_bd_pins ila_0/probe5]
  connect_bd_net -net tdc_mngt_gate_pos0  [get_bd_pins tdc_mngt/gate_pos0] \
  [get_bd_pins gate_pos0]
  connect_bd_net -net tdc_mngt_gate_pos1  [get_bd_pins tdc_mngt/gate_pos1] \
  [get_bd_pins gate_pos1]
  connect_bd_net -net tdc_mngt_gate_pos2  [get_bd_pins tdc_mngt/gate_pos2] \
  [get_bd_pins gate_pos2]
  connect_bd_net -net tdc_mngt_gate_pos3  [get_bd_pins tdc_mngt/gate_pos3] \
  [get_bd_pins gate_pos3]
  connect_bd_net -net tdc_mngt_gc  [get_bd_pins tdc_mngt/gc] \
  [get_bd_pins ila_0/probe10]
  connect_bd_net -net tdc_mngt_gc_time_valid  [get_bd_pins tdc_mngt/gc_time_valid] \
  [get_bd_pins gc_time_valid]
  connect_bd_net -net tdc_mngt_index_shift_gc -boundary_type upper  [get_bd_pins tdc_mngt/index_shift_gc]
  connect_bd_net -net tdc_mngt_q_gc_time_valid_mod16  [get_bd_pins tdc_mngt/q_gc_time_valid_mod16] \
  [get_bd_pins q_gc_time_valid_mod16]
  connect_bd_net -net tdc_mngt_start_gc_o  [get_bd_pins tdc_mngt/start_gc_o] \
  [get_bd_pins ila_0/probe7]
  connect_bd_net -net tdc_mngt_stopa_sim_enable_o  [get_bd_pins tdc_mngt/stopa_sim_enable_o] \
  [get_bd_pins clk_rst_buffer/stopa_sim_enable_i]
  connect_bd_net -net tdc_mngt_tdata200  [get_bd_pins tdc_mngt/tdata200] \
  [get_bd_pins tdata200]
  connect_bd_net -net tdc_mngt_tdata200_mod  [get_bd_pins tdc_mngt/tdata200_mod] \
  [get_bd_pins tdata200_mod]
  connect_bd_net -net tdc_mngt_time_ref_gc -boundary_type upper  [get_bd_pins tdc_mngt/time_ref_gc]
  connect_bd_net -net tdc_mngt_tvalid200  [get_bd_pins tdc_mngt/tvalid200] \
  [get_bd_pins tvalid200] \
  [get_bd_pins ila_0/probe6]
  connect_bd_net -net tdc_rst_1  [get_bd_pins tdc_rst] \
  [get_bd_pins clk_rst_buffer/tdc_rst]
  connect_bd_net -net time_spi_rst_jic_0  [get_bd_pins time_spi/rst_jic_0] \
  [get_bd_pins rst_jic_0]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: ddr4
proc create_hier_cell_ddr4 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_ddr4() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 c0_ddr4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_gc

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS1


  # Create pins
  create_bd_pin -dir O led
  create_bd_pin -dir I -from 0 -to 0 sys_rst_n
  create_bd_pin -dir I -type clk ddr_sys_clk_n
  create_bd_pin -dir I -type clk ddr_sys_clk_p
  create_bd_pin -dir O -type clk addn_ui_clkout1
  create_bd_pin -dir O -type clk c0_ddr4_ui_clk
  create_bd_pin -dir O -type rst c0_ddr4_ui_clk_sync_rst
  create_bd_pin -dir O -type clk addn_ui_clkout2
  create_bd_pin -dir I -type rst c0_ddr4_aresetn
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I clk200_i
  create_bd_pin -dir I ext_pps
  create_bd_pin -dir I -type rst s_axil_aresetn
  create_bd_pin -dir I -type rst ddr_data_rstn
  create_bd_pin -dir I rd_en_4
  create_bd_pin -dir I -from 3 -to 0 rng_data
  create_bd_pin -dir I tvalid200
  create_bd_pin -dir I -from 31 -to 0 tdata200
  create_bd_pin -dir I -from 15 -to 0 tdata200_mod
  create_bd_pin -dir O read_done_0
  create_bd_pin -dir O rd_en_fifo_gc_0
  create_bd_pin -dir O -type rst fifo_gc_rst_0
  create_bd_pin -dir O rd_gc_valid_0
  create_bd_pin -dir I -from 31 -to 0 gate_pos0
  create_bd_pin -dir I -from 31 -to 0 gate_pos1
  create_bd_pin -dir I -from 31 -to 0 gate_pos2
  create_bd_pin -dir I -from 31 -to 0 gate_pos3
  create_bd_pin -dir I -from 1 -to 0 rng_a_data

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
  set_property -dict [list \
    CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {15} \
    CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {100} \
    CONFIG.C0.BANK_GROUP_WIDTH {1} \
    CONFIG.C0.DDR4_AxiAddressWidth {31} \
    CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG} \
    CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4} \
  ] $ddr4_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {2} \
  ] $xlconstant_0


  # Create instance: system_ila_ddr, and set properties
  set system_ila_ddr [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_ddr ]
  set_property -dict [list \
    CONFIG.C_MON_TYPE {MIX} \
    CONFIG.C_NUM_MONITOR_SLOTS {4} \
    CONFIG.C_NUM_OF_PROBES {22} \
    CONFIG.C_PROBE10_WIDTH {2} \
    CONFIG.C_PROBE11_WIDTH {4} \
    CONFIG.C_PROBE12_WIDTH {64} \
    CONFIG.C_PROBE13_WIDTH {2} \
    CONFIG.C_PROBE14_WIDTH {48} \
    CONFIG.C_PROBE15_WIDTH {32} \
    CONFIG.C_PROBE16_WIDTH {7} \
    CONFIG.C_PROBE17_WIDTH {42} \
    CONFIG.C_PROBE18_WIDTH {7} \
    CONFIG.C_PROBE19_WIDTH {1} \
    CONFIG.C_PROBE1_WIDTH {2} \
    CONFIG.C_PROBE20_WIDTH {3} \
    CONFIG.C_PROBE21_WIDTH {48} \
    CONFIG.C_PROBE22_WIDTH {1} \
    CONFIG.C_PROBE23_WIDTH {1} \
    CONFIG.C_PROBE24_WIDTH {1} \
    CONFIG.C_PROBE26_WIDTH {1} \
    CONFIG.C_PROBE2_WIDTH {1} \
    CONFIG.C_PROBE3_WIDTH {48} \
    CONFIG.C_PROBE4_WIDTH {3} \
    CONFIG.C_PROBE5_WIDTH {1} \
    CONFIG.C_PROBE7_WIDTH {1} \
    CONFIG.C_PROBE8_WIDTH {7} \
    CONFIG.C_PROBE9_WIDTH {1} \
    CONFIG.C_PROBE_WIDTH_PROPAGATION {MANUAL} \
    CONFIG.C_SLOT {3} \
    CONFIG.C_SLOT_0_APC_EN {0} \
    CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
    CONFIG.C_SLOT_0_MAX_RD_BURSTS {64} \
    CONFIG.C_SLOT_0_MAX_WR_BURSTS {64} \
    CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
    CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
    CONFIG.C_SLOT_3_APC_EN {0} \
    CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
    CONFIG.C_SLOT_3_MAX_RD_BURSTS {8} \
    CONFIG.C_SLOT_3_MAX_WR_BURSTS {8} \
    CONFIG.C_SLOT_4_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
  ] $system_ila_ddr


  # Create instance: axi_virtual_controll_0, and set properties
  set block_name axi_virtual_controller_wrapper
  set block_cell_name axi_virtual_controll_0
  if { [catch {set axi_virtual_controll_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_virtual_controll_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_intf_pins /ddr4/axi_virtual_controll_0/m_axi]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_intf_pins /ddr4/axi_virtual_controll_0/m_axis]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /ddr4/axi_virtual_controll_0/aclk]

  # Create instance: axi_clock_converter_0, and set properties
  set block_name axi_clock_converter_rtl
  set block_cell_name axi_clock_converter_0
  if { [catch {set axi_clock_converter_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_clock_converter_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
 ] [get_bd_intf_pins /ddr4/axi_clock_converter_0/m_axi]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
 ] [get_bd_pins /ddr4/axi_clock_converter_0/m_axi_aclk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /ddr4/axi_clock_converter_0/s_axi_aclk]

  # Create instance: fifos_out_0, and set properties
  set block_name fifos_out
  set block_cell_name fifos_out_0
  if { [catch {set fifos_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifos_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_intf_pins /ddr4/fifos_out_0/m_axis_alpha]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_intf_pins /ddr4/fifos_out_0/m_axis_gco]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_pins /ddr4/fifos_out_0/m_alpha_aclk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_pins /ddr4/fifos_out_0/m_gco_aclk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   CONFIG.ASSOCIATED_BUSIF {s_axis_alpha} \
 ] [get_bd_pins /ddr4/fifos_out_0/s_alpha_aclk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   CONFIG.ASSOCIATED_BUSIF {s_axis_gco} \
 ] [get_bd_pins /ddr4/fifos_out_0/s_gco_aclk]

  # Create instance: mon_ddr_fifos_0, and set properties
  set block_name mon_ddr_fifos
  set block_cell_name mon_ddr_fifos_0
  if { [catch {set mon_ddr_fifos_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $mon_ddr_fifos_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ddr_data_reg_mngt_0, and set properties
  set block_name ddr_data_reg_mngt
  set block_cell_name ddr_data_reg_mngt_0
  if { [catch {set ddr_data_reg_mngt_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ddr_data_reg_mngt_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.C_s_axil_ADDR_WIDTH {12} $ddr_data_reg_mngt_0


  # Create instance: ddr_data_0, and set properties
  set block_name ddr_data
  set block_cell_name ddr_data_0
  if { [catch {set ddr_data_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ddr_data_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_intf_pins /ddr4/ddr_data_0/m_axis]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_intf_pins /ddr4/ddr_data_0/m_axis_alpha]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_intf_pins /ddr4/ddr_data_0/m_axis_gc]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /ddr4/ddr_data_0/m_axis_alpha_clk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /ddr4/ddr_data_0/m_axis_clk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /ddr4/ddr_data_0/m_axis_gc_clk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] [get_bd_pins /ddr4/ddr_data_0/s_axis_clk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_pins /ddr4/ddr_data_0/s_axis_gc_clk]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axil] [get_bd_intf_pins ddr_data_reg_mngt_0/s_axil]
  connect_bd_intf_net -intf_net axi_clock_converter_0_m_axi [get_bd_intf_pins axi_clock_converter_0/m_axi] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net axi_vfifo_ctrl_0_M_AXI1 [get_bd_intf_pins axi_virtual_controll_0/m_axi] [get_bd_intf_pins axi_clock_converter_0/s_axi]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_vfifo_ctrl_0_M_AXI1] [get_bd_intf_pins axi_virtual_controll_0/m_axi] [get_bd_intf_pins system_ila_ddr/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_vfifo_ctrl_0_M_AXIS [get_bd_intf_pins axi_virtual_controll_0/m_axis] [get_bd_intf_pins ddr_data_0/s_axis]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_vfifo_ctrl_0_M_AXIS] [get_bd_intf_pins axi_virtual_controll_0/m_axis] [get_bd_intf_pins system_ila_ddr/SLOT_1_AXIS]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_pins c0_ddr4] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net ddr_data_0_m_axis [get_bd_intf_pins ddr_data_0/m_axis] [get_bd_intf_pins axi_virtual_controll_0/s_axis]
  connect_bd_intf_net -intf_net [get_bd_intf_nets ddr_data_0_m_axis] [get_bd_intf_pins ddr_data_0/m_axis] [get_bd_intf_pins system_ila_ddr/SLOT_2_AXIS]
  connect_bd_intf_net -intf_net ddr_data_0_m_axis_alpha [get_bd_intf_pins fifos_out_0/s_axis_alpha] [get_bd_intf_pins ddr_data_0/m_axis_alpha]
  connect_bd_intf_net -intf_net ddr_data_0_m_axis_gc [get_bd_intf_pins ddr_data_0/m_axis_gc] [get_bd_intf_pins fifos_out_0/s_axis_gco]
  connect_bd_intf_net -intf_net [get_bd_intf_nets ddr_data_0_m_axis_gc] [get_bd_intf_pins ddr_data_0/m_axis_gc] [get_bd_intf_pins system_ila_ddr/SLOT_3_AXIS]
  connect_bd_intf_net -intf_net ddr_data_reg_mngt_0_mr [get_bd_intf_pins ddr_data_reg_mngt_0/mr] [get_bd_intf_pins ddr_data_0/sr]
  connect_bd_intf_net -intf_net fifos_out_0_m_axis_alpha [get_bd_intf_pins M_AXIS1] [get_bd_intf_pins fifos_out_0/m_axis_alpha]
  connect_bd_intf_net -intf_net fifos_out_0_m_axis_gco [get_bd_intf_pins M_AXIS] [get_bd_intf_pins fifos_out_0/m_axis_gco]
  connect_bd_intf_net -intf_net s_axis_gc_1 [get_bd_intf_pins s_axis_gc] [get_bd_intf_pins ddr_data_0/s_axis_gc]

  # Create port connections
  connect_bd_net -net aclk_1  [get_bd_pins aclk] \
  [get_bd_pins mon_ddr_fifos_0/clk250_i] \
  [get_bd_pins ddr_data_0/s_axis_gc_clk] \
  [get_bd_pins fifos_out_0/m_gco_aclk] \
  [get_bd_pins fifos_out_0/m_alpha_aclk]
  connect_bd_net -net aresetn_1  [get_bd_pins aresetn] \
  [get_bd_pins mon_ddr_fifos_0/aresetn] \
  [get_bd_pins ddr_data_0/s_gc_aresetn]
  connect_bd_net -net axi_vfifo_ctrl_0_vfifo_mm2s_channel_empty  [get_bd_pins axi_virtual_controll_0/vfifo_mm2s_channel_empty] \
  [get_bd_pins system_ila_ddr/probe13] \
  [get_bd_pins mon_ddr_fifos_0/vfifo_empty]
  connect_bd_net -net axi_vfifo_ctrl_0_vfifo_s2mm_channel_full  [get_bd_pins axi_virtual_controll_0/vfifo_s2mm_channel_full] \
  [get_bd_pins system_ila_ddr/probe0] \
  [get_bd_pins system_ila_ddr/probe1] \
  [get_bd_pins mon_ddr_fifos_0/vfifo_full]
  connect_bd_net -net axi_virtual_controll_0_vfifo_idle  [get_bd_pins axi_virtual_controll_0/vfifo_idle] \
  [get_bd_pins mon_ddr_fifos_0/vfifo_idle]
  connect_bd_net -net c0_ddr4_aresetn_1  [get_bd_pins c0_ddr4_aresetn] \
  [get_bd_pins ddr4_0/c0_ddr4_aresetn] \
  [get_bd_pins axi_clock_converter_0/m_axi_aresetn]
  connect_bd_net -net clk200_i_1  [get_bd_pins clk200_i] \
  [get_bd_pins system_ila_ddr/clk] \
  [get_bd_pins mon_ddr_fifos_0/clk200_i] \
  [get_bd_pins axi_virtual_controll_0/aclk] \
  [get_bd_pins ddr_data_0/clk200_i] \
  [get_bd_pins ddr_data_0/m_axis_clk] \
  [get_bd_pins ddr_data_0/s_axis_clk] \
  [get_bd_pins ddr_data_0/m_axis_gc_clk] \
  [get_bd_pins ddr_data_0/m_axis_alpha_clk] \
  [get_bd_pins axi_clock_converter_0/s_axi_aclk] \
  [get_bd_pins fifos_out_0/s_gco_aclk] \
  [get_bd_pins fifos_out_0/s_alpha_aclk]
  connect_bd_net -net ddr4_0_addn_ui_clkout1  [get_bd_pins ddr4_0/addn_ui_clkout1] \
  [get_bd_pins addn_ui_clkout1] \
  [get_bd_pins ddr_data_reg_mngt_0/s_axil_aclk]
  connect_bd_net -net ddr4_0_addn_ui_clkout2  [get_bd_pins ddr4_0/addn_ui_clkout2] \
  [get_bd_pins addn_ui_clkout2]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk  [get_bd_pins ddr4_0/c0_ddr4_ui_clk] \
  [get_bd_pins c0_ddr4_ui_clk] \
  [get_bd_pins axi_clock_converter_0/m_axi_aclk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst  [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] \
  [get_bd_pins c0_ddr4_ui_clk_sync_rst]
  connect_bd_net -net ddr4_0_c0_init_calib_complete  [get_bd_pins ddr4_0/c0_init_calib_complete] \
  [get_bd_pins led]
  connect_bd_net -net ddr_data_0_alpha_cycle_counter  [get_bd_pins ddr_data_0/alpha_cycle_counter] \
  [get_bd_pins system_ila_ddr/probe16]
  connect_bd_net -net ddr_data_0_alpha_pack_done  [get_bd_pins ddr_data_0/alpha_pack_done] \
  [get_bd_pins system_ila_ddr/probe7]
  connect_bd_net -net ddr_data_0_alpha_q  [get_bd_pins ddr_data_0/alpha_q] \
  [get_bd_pins system_ila_ddr/probe10]
  connect_bd_net -net ddr_data_0_command_gc_enable_r  [get_bd_pins ddr_data_0/command_gc_enable_r] \
  [get_bd_pins system_ila_ddr/probe20]
  connect_bd_net -net ddr_data_0_cycle_counter  [get_bd_pins ddr_data_0/cycle_counter] \
  [get_bd_pins system_ila_ddr/probe8]
  connect_bd_net -net ddr_data_0_debug_rc_gc_div  [get_bd_pins ddr_data_0/debug_rc_gc_div] \
  [get_bd_pins system_ila_ddr/probe21]
  connect_bd_net -net ddr_data_0_dq_gc  [get_bd_pins ddr_data_0/dq_gc] \
  [get_bd_pins system_ila_ddr/probe14]
  connect_bd_net -net ddr_data_0_dq_gc_start_r_debug  [get_bd_pins ddr_data_0/dq_gc_start_r_debug] \
  [get_bd_pins system_ila_ddr/probe15]
  connect_bd_net -net ddr_data_0_fifo_alpha_rst  [get_bd_pins ddr_data_0/fifo_alpha_rst] \
  [get_bd_pins fifos_out_0/s_alpha_aresetn]
  connect_bd_net -net ddr_data_0_fifo_gc_empty  [get_bd_pins ddr_data_0/fifo_gc_empty] \
  [get_bd_pins mon_ddr_fifos_0/gc_in_fifo_empty]
  connect_bd_net -net ddr_data_0_fifo_gc_full  [get_bd_pins ddr_data_0/fifo_gc_full] \
  [get_bd_pins mon_ddr_fifos_0/gc_in_fifo_full]
  connect_bd_net -net ddr_data_0_fifo_gc_rst  [get_bd_pins ddr_data_0/fifo_gc_rst] \
  [get_bd_pins fifo_gc_rst_0] \
  [get_bd_pins fifos_out_0/s_gco_aresetn]
  connect_bd_net -net ddr_data_0_gc_time_valid_div  [get_bd_pins ddr_data_0/gc_time_valid_div] \
  [get_bd_pins system_ila_ddr/probe17]
  connect_bd_net -net ddr_data_0_gc_time_valid_mod  [get_bd_pins ddr_data_0/gc_time_valid_mod] \
  [get_bd_pins system_ila_ddr/probe18]
  connect_bd_net -net ddr_data_0_pack_done  [get_bd_pins ddr_data_0/pack_done] \
  [get_bd_pins system_ila_ddr/probe9]
  connect_bd_net -net ddr_data_0_rd_en_fifo_gc  [get_bd_pins ddr_data_0/rd_en_fifo_gc] \
  [get_bd_pins rd_en_fifo_gc_0]
  connect_bd_net -net ddr_data_0_rd_gc_valid  [get_bd_pins ddr_data_0/rd_gc_valid] \
  [get_bd_pins rd_gc_valid_0] \
  [get_bd_pins system_ila_ddr/probe6]
  connect_bd_net -net ddr_data_0_read_count  [get_bd_pins ddr_data_0/read_count] \
  [get_bd_pins system_ila_ddr/probe3]
  connect_bd_net -net ddr_data_0_read_done  [get_bd_pins ddr_data_0/read_done] \
  [get_bd_pins read_done_0] \
  [get_bd_pins system_ila_ddr/probe2]
  connect_bd_net -net ddr_data_0_start_save_alpha  [get_bd_pins ddr_data_0/start_save_alpha] \
  [get_bd_pins system_ila_ddr/probe5]
  connect_bd_net -net ddr_data_0_state_alpha  [get_bd_pins ddr_data_0/state_alpha] \
  [get_bd_pins system_ila_ddr/probe4]
  connect_bd_net -net ddr_data_0_tdata_gc  [get_bd_pins ddr_data_0/tdata_gc] \
  [get_bd_pins system_ila_ddr/probe12]
  connect_bd_net -net ddr_data_rstn_1  [get_bd_pins ddr_data_rstn] \
  [get_bd_pins system_ila_ddr/resetn] \
  [get_bd_pins mon_ddr_fifos_0/ddr_data_rstn] \
  [get_bd_pins axi_virtual_controll_0/aresetn] \
  [get_bd_pins ddr_data_0/ddr_data_rstn] \
  [get_bd_pins axi_clock_converter_0/s_axi_aresetn]
  connect_bd_net -net ddr_sys_clk_n_1  [get_bd_pins ddr_sys_clk_n] \
  [get_bd_pins ddr4_0/c0_sys_clk_n]
  connect_bd_net -net ddr_sys_clk_p_1  [get_bd_pins ddr_sys_clk_p] \
  [get_bd_pins ddr4_0/c0_sys_clk_p]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins ddr_data_reg_mngt_0/pps_i] \
  [get_bd_pins ddr_data_0/pps_i]
  connect_bd_net -net fifos_out_0_axis_prog_empty_alpha  [get_bd_pins fifos_out_0/axis_prog_empty_alpha] \
  [get_bd_pins mon_ddr_fifos_0/alpha_out_fifo_empty]
  connect_bd_net -net fifos_out_0_axis_prog_empty_gco  [get_bd_pins fifos_out_0/axis_prog_empty_gco] \
  [get_bd_pins mon_ddr_fifos_0/gc_out_fifo_empty]
  connect_bd_net -net fifos_out_0_axis_prog_full_alpha  [get_bd_pins fifos_out_0/axis_prog_full_alpha] \
  [get_bd_pins mon_ddr_fifos_0/alpha_out_fifo_full]
  connect_bd_net -net fifos_out_0_axis_prog_full_gco  [get_bd_pins fifos_out_0/axis_prog_full_gco] \
  [get_bd_pins mon_ddr_fifos_0/gc_out_fifo_full]
  connect_bd_net -net gate_pos0_1  [get_bd_pins gate_pos0] \
  [get_bd_pins ddr_data_0/gate_pos0]
  connect_bd_net -net gate_pos1_1  [get_bd_pins gate_pos1] \
  [get_bd_pins ddr_data_0/gate_pos1]
  connect_bd_net -net gate_pos2_1  [get_bd_pins gate_pos2] \
  [get_bd_pins ddr_data_0/gate_pos2]
  connect_bd_net -net gate_pos3_1  [get_bd_pins gate_pos3] \
  [get_bd_pins ddr_data_0/gate_pos3]
  connect_bd_net -net mon_ddr_fifos_0_status_200_o  [get_bd_pins mon_ddr_fifos_0/status_200_o] \
  [get_bd_pins ddr_data_reg_mngt_0/ddr_fifos_status_i]
  connect_bd_net -net mon_ddr_fifos_0_status_200_valid_o  [get_bd_pins mon_ddr_fifos_0/status_200_valid_o] \
  [get_bd_pins ddr_data_reg_mngt_0/status_200_valid_i]
  connect_bd_net -net mon_ddr_fifos_0_status_250_o  [get_bd_pins mon_ddr_fifos_0/status_250_o] \
  [get_bd_pins ddr_data_reg_mngt_0/fifos_status_i]
  connect_bd_net -net mon_ddr_fifos_0_status_250_valid_o  [get_bd_pins mon_ddr_fifos_0/status_250_valid_o] \
  [get_bd_pins ddr_data_reg_mngt_0/status_250_valid_i]
  connect_bd_net -net rd_en_4_1  [get_bd_pins rd_en_4] \
  [get_bd_pins ddr_data_0/rd_en_4]
  connect_bd_net -net rng_a_data_1  [get_bd_pins rng_a_data] \
  [get_bd_pins ddr_data_0/rng_a_data]
  connect_bd_net -net rng_data_1  [get_bd_pins rng_data] \
  [get_bd_pins system_ila_ddr/probe11] \
  [get_bd_pins ddr_data_0/rng_data]
  connect_bd_net -net s_axil_aresetn_1  [get_bd_pins s_axil_aresetn] \
  [get_bd_pins ddr_data_reg_mngt_0/s_axil_aresetn]
  connect_bd_net -net sys_rst_n_1  [get_bd_pins sys_rst_n] \
  [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net tdata200_1  [get_bd_pins tdata200] \
  [get_bd_pins ddr_data_0/tdata200]
  connect_bd_net -net tdata200_mod_1  [get_bd_pins tdata200_mod] \
  [get_bd_pins ddr_data_0/tdata200_mod]
  connect_bd_net -net tvalid200_1  [get_bd_pins tvalid200] \
  [get_bd_pins system_ila_ddr/probe19] \
  [get_bd_pins ddr_data_0/tvalid200]
  connect_bd_net -net util_vector_logic_0_Res  [get_bd_pins util_vector_logic_0/Res] \
  [get_bd_pins ddr4_0/sys_rst]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins axi_virtual_controll_0/vfifo_mm2s_channel_full]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: clk_rst
proc create_hier_cell_clk_rst { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_clk_rst() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil

  create_bd_intf_pin -mode Slave -vlnv Veriqloud:cr:ext_cr_rtl:1.0 cr_ext_cr


  # Create pins
  create_bd_pin -dir O qpll0_refclk_o
  create_bd_pin -dir O clk200
  create_bd_pin -dir O clk3125
  create_bd_pin -dir O tx_sync_o
  create_bd_pin -dir O ext_sync_ltc
  create_bd_pin -dir O -from 0 -to 0 -type rst tx_core_reset_o
  create_bd_pin -dir O rstn_axil_o
  create_bd_pin -dir I ext_pps
  create_bd_pin -dir I sys_rst_n
  create_bd_pin -dir O rstn_ddr_axi_o
  create_bd_pin -dir I clk_ddr_axi_i
  create_bd_pin -dir I rst_ddr_axi_i
  create_bd_pin -dir I -type clk s_axil_aclk
  create_bd_pin -dir I fastdac_gt_powergood_i
  create_bd_pin -dir O clk10_o
  create_bd_pin -dir O -type rst tdc_rst_o
  create_bd_pin -dir O -type rst gc_rst_o
  create_bd_pin -dir O lrst_o
  create_bd_pin -dir O -type rst ttl_rst
  create_bd_pin -dir O -type rst ddr_data_rstn_o
  create_bd_pin -dir I lclk_i
  create_bd_pin -dir O -type rst decoy_rst

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $xlconstant_0


  # Create instance: led_test_0, and set properties
  set block_name led_test
  set block_cell_name led_test_0
  if { [catch {set led_test_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $led_test_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_rst_mngt, and set properties
  set block_name clk_rst_mngt
  set block_cell_name clk_rst_mngt
  if { [catch {set clk_rst_mngt [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_rst_mngt eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axil] [get_bd_intf_pins clk_rst_mngt/s_axil]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins cr_ext_cr] [get_bd_intf_pins clk_rst_mngt/cr_ext_cr]

  # Create port connections
  connect_bd_net -net clk_ddr_axi_i_1  [get_bd_pins clk_ddr_axi_i] \
  [get_bd_pins clk_rst_mngt/clk_ddr_axi_i]
  connect_bd_net -net clk_rst_mngt_0_qpll0_refclk_o  [get_bd_pins clk_rst_mngt/fastdac_refclk_o] \
  [get_bd_pins qpll0_refclk_o]
  connect_bd_net -net clk_rst_mngt_0_tx_core_clk_o  [get_bd_pins clk_rst_mngt/fastdac_coreclk_o] \
  [get_bd_pins clk200] \
  [get_bd_pins led_test_0/clk200]
  connect_bd_net -net clk_rst_mngt_0_tx_sysref_o  [get_bd_pins clk_rst_mngt/fastdac_sysref_o] \
  [get_bd_pins clk3125] \
  [get_bd_pins led_test_0/clk3125]
  connect_bd_net -net clk_rst_mngt_clk100_o  [get_bd_pins clk_rst_mngt/clk100_o] \
  [get_bd_pins led_test_0/clk100]
  connect_bd_net -net clk_rst_mngt_clk10_o  [get_bd_pins clk_rst_mngt/clk10_o] \
  [get_bd_pins clk10_o] \
  [get_bd_pins led_test_0/clk10]
  connect_bd_net -net clk_rst_mngt_ddr_data_rstn_o  [get_bd_pins clk_rst_mngt/ddr_data_rstn_o] \
  [get_bd_pins ddr_data_rstn_o]
  connect_bd_net -net clk_rst_mngt_decoy_rst  [get_bd_pins clk_rst_mngt/decoy_rst] \
  [get_bd_pins decoy_rst]
  connect_bd_net -net clk_rst_mngt_fastdac_corerst_o  [get_bd_pins clk_rst_mngt/fastdac_corerst_o] \
  [get_bd_pins tx_core_reset_o]
  connect_bd_net -net clk_rst_mngt_fastdac_syncout_o  [get_bd_pins clk_rst_mngt/fastdac_syncout_o] \
  [get_bd_pins tx_sync_o]
  connect_bd_net -net clk_rst_mngt_gc_rst_o  [get_bd_pins clk_rst_mngt/gc_rst_o] \
  [get_bd_pins gc_rst_o]
  connect_bd_net -net clk_rst_mngt_lrst_o  [get_bd_pins clk_rst_mngt/lrst_o] \
  [get_bd_pins lrst_o]
  connect_bd_net -net clk_rst_mngt_rstn_axil_o  [get_bd_pins clk_rst_mngt/rstn_axil_o] \
  [get_bd_pins rstn_axil_o]
  connect_bd_net -net clk_rst_mngt_rstn_ddr_axi_o  [get_bd_pins clk_rst_mngt/rstn_ddr_axi_o] \
  [get_bd_pins rstn_ddr_axi_o]
  connect_bd_net -net clk_rst_mngt_sync_ltc_o  [get_bd_pins clk_rst_mngt/sync_ltc_o] \
  [get_bd_pins ext_sync_ltc]
  connect_bd_net -net clk_rst_mngt_tdc_rst_o  [get_bd_pins clk_rst_mngt/tdc_rst_o] \
  [get_bd_pins tdc_rst_o] \
  [get_bd_pins led_test_0/tdc_rst]
  connect_bd_net -net clk_rst_mngt_ttl_rst  [get_bd_pins clk_rst_mngt/ttl_rst] \
  [get_bd_pins ttl_rst]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins clk_rst_mngt/pps_i] \
  [get_bd_pins led_test_0/pps]
  connect_bd_net -net fastdac_gt_powergood_i_1  [get_bd_pins fastdac_gt_powergood_i] \
  [get_bd_pins clk_rst_mngt/fastdac_gt_powergood_i]
  connect_bd_net -net lclk_i_1  [get_bd_pins lclk_i] \
  [get_bd_pins clk_rst_mngt/lclk_i]
  connect_bd_net -net rst_ddr_axi_i_1  [get_bd_pins rst_ddr_axi_i] \
  [get_bd_pins clk_rst_mngt/rst_ddr_axi_i]
  connect_bd_net -net s_axil_aclk_1  [get_bd_pins s_axil_aclk] \
  [get_bd_pins clk_rst_mngt/s_axil_aclk]
  connect_bd_net -net sys_rst_n_1  [get_bd_pins sys_rst_n] \
  [get_bd_pins clk_rst_mngt/sys_reset_n]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins led_test_0/syncout] \
  [get_bd_pins led_test_0/sys_reset_n] \
  [get_bd_pins led_test_0/tdc_pps_trigger_i] \
  [get_bd_pins led_test_0/clockchip_sync]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: fastdac
proc create_hier_cell_fastdac { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_fastdac() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil


  # Create pins
  create_bd_pin -dir I -type clk tx_core_clk_0
  create_bd_pin -dir I tx_sync_0
  create_bd_pin -dir I -type clk qpll0_refclk_0
  create_bd_pin -dir O -from 3 -to 0 ext_fastdac_txp_out
  create_bd_pin -dir O -from 3 -to 0 ext_fastdac_txn_out
  create_bd_pin -dir O gt_powergood
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I btx_sysref_i
  create_bd_pin -dir I -type rst tx_core_reset
  create_bd_pin -dir I ext_pps
  create_bd_pin -dir O -from 0 -to 0 rd_en_4
  create_bd_pin -dir O -from 3 -to 0 rng_value
  create_bd_pin -dir I tvalid200
  create_bd_pin -dir I -from 15 -to 0 tdata200_mod
  create_bd_pin -dir I -from 31 -to 0 gate_pos0
  create_bd_pin -dir I -from 31 -to 0 gate_pos1
  create_bd_pin -dir I -from 31 -to 0 gate_pos2
  create_bd_pin -dir I -from 31 -to 0 gate_pos3
  create_bd_pin -dir I -from 47 -to 0 gc_time_valid
  create_bd_pin -dir I -from 3 -to 0 q_gc_time_valid_mod16
  create_bd_pin -dir O rd_en_16

  # Create instance: jesd204_phy_0, and set properties
  set jesd204_phy_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jesd204_phy:4.1 jesd204_phy_0 ]
  set_property -dict [list \
    CONFIG.C_LANES {4} \
    CONFIG.C_PLL_SELECTION {1} \
    CONFIG.GT_Line_Rate {8} \
    CONFIG.GT_REFCLK_FREQ {200} \
    CONFIG.RX_GT_Line_Rate {8} \
    CONFIG.RX_GT_REFCLK_FREQ {200} \
    CONFIG.RX_PLL_SELECTION {1} \
  ] $jesd204_phy_0


  # Create instance: ila_fastdac, and set properties
  set ila_fastdac [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_fastdac ]
  set_property -dict [list \
    CONFIG.C_ENABLE_ILA_AXI_MON {FALSE} \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {8} \
    CONFIG.C_PROBE10_WIDTH {1} \
    CONFIG.C_PROBE11_WIDTH {1} \
    CONFIG.C_PROBE12_WIDTH {1} \
    CONFIG.C_PROBE13_WIDTH {1} \
    CONFIG.C_PROBE14_WIDTH {1} \
    CONFIG.C_PROBE3_WIDTH {1} \
    CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {1} \
    CONFIG.C_PROBE6_WIDTH {3} \
    CONFIG.C_PROBE7_WIDTH {16} \
    CONFIG.C_PROBE8_WIDTH {1} \
    CONFIG.C_PROBE9_WIDTH {1} \
  ] $ila_fastdac


  # Create instance: sync_tx_tready_0, and set properties
  set block_name sync_tx_tready
  set block_cell_name sync_tx_tready_0
  if { [catch {set sync_tx_tready_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $sync_tx_tready_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: jesd204b_tx_wrapper_0, and set properties
  set block_name jesd204b_tx_wrapper
  set block_cell_name jesd204b_tx_wrapper_0
  if { [catch {set jesd204b_tx_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $jesd204b_tx_wrapper_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: jesd_transport_0, and set properties
  set block_name jesd_transport
  set block_cell_name jesd_transport_0
  if { [catch {set jesd_transport_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $jesd_transport_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.C_s_axil_ADDR_WIDTH {16} $jesd_transport_0


  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_intf_pins /fastdac/jesd_transport_0/s_axis]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
 ] [get_bd_pins /fastdac/jesd_transport_0/s_axis_clk]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axis1] [get_bd_intf_pins jesd_transport_0/s_axis]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axil] [get_bd_intf_pins jesd_transport_0/s_axil]
  connect_bd_intf_net -intf_net s_axi_1 [get_bd_intf_pins s_axi] [get_bd_intf_pins jesd204b_tx_wrapper_0/s_axil]

  # Create port connections
  connect_bd_net -net aclk_1  [get_bd_pins aclk] \
  [get_bd_pins jesd_transport_0/s_axis_clk]
  connect_bd_net -net aresetn_1  [get_bd_pins aresetn] \
  [get_bd_pins jesd_transport_0/s_axis_tresetn]
  connect_bd_net -net btx_sysref_i_1  [get_bd_pins btx_sysref_i] \
  [get_bd_pins ila_fastdac/probe4] \
  [get_bd_pins jesd204b_tx_wrapper_0/btx_sysref_i]
  connect_bd_net -net ext_pps_1  [get_bd_pins ext_pps] \
  [get_bd_pins ila_fastdac/probe1] \
  [get_bd_pins sync_tx_tready_0/pps_i]
  connect_bd_net -net gate_pos0_1  [get_bd_pins gate_pos0] \
  [get_bd_pins jesd_transport_0/gate_pos0]
  connect_bd_net -net gate_pos1_1  [get_bd_pins gate_pos1] \
  [get_bd_pins jesd_transport_0/gate_pos1]
  connect_bd_net -net gate_pos2_1  [get_bd_pins gate_pos2] \
  [get_bd_pins jesd_transport_0/gate_pos2]
  connect_bd_net -net gate_pos3_1  [get_bd_pins gate_pos3] \
  [get_bd_pins jesd_transport_0/gate_pos3]
  connect_bd_net -net gc_time_valid_1 -boundary_type lower  [get_bd_pins gc_time_valid]
  connect_bd_net -net jesd204_phy_0_gt_powergood  [get_bd_pins jesd204_phy_0/gt_powergood] \
  [get_bd_pins gt_powergood]
  connect_bd_net -net jesd204_phy_0_tx_reset_done  [get_bd_pins jesd204_phy_0/tx_reset_done] \
  [get_bd_pins jesd204b_tx_wrapper_0/btx_reset_done_i]
  connect_bd_net -net jesd204_phy_0_txn_out  [get_bd_pins jesd204_phy_0/txn_out] \
  [get_bd_pins ext_fastdac_txn_out]
  connect_bd_net -net jesd204_phy_0_txp_out  [get_bd_pins jesd204_phy_0/txp_out] \
  [get_bd_pins ext_fastdac_txp_out]
  connect_bd_net -net jesd204b_tx_wrapper_0_blmfc_r  [get_bd_pins jesd204b_tx_wrapper_0/blmfc_r] \
  [get_bd_pins ila_fastdac/probe5]
  connect_bd_net -net jesd204b_tx_wrapper_0_btx_reset_gt_o  [get_bd_pins jesd204b_tx_wrapper_0/btx_reset_gt_o] \
  [get_bd_pins jesd204_phy_0/tx_reset_gt]
  connect_bd_net -net jesd204b_tx_wrapper_0_btx_tready_o  [get_bd_pins jesd204b_tx_wrapper_0/btx_tready_o] \
  [get_bd_pins ila_fastdac/probe2] \
  [get_bd_pins sync_tx_tready_0/tx_tready]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt0_charisk_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt0_charisk_o] \
  [get_bd_pins jesd204_phy_0/gt0_txcharisk]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt0_tdata_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt0_tdata_o] \
  [get_bd_pins jesd204_phy_0/gt0_txdata]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt1_charisk_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt1_charisk_o] \
  [get_bd_pins jesd204_phy_0/gt1_txcharisk]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt1_tdata_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt1_tdata_o] \
  [get_bd_pins jesd204_phy_0/gt1_txdata]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt2_charisk_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt2_charisk_o] \
  [get_bd_pins jesd204_phy_0/gt2_txcharisk]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt2_tdata_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt2_tdata_o] \
  [get_bd_pins jesd204_phy_0/gt2_txdata]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt3_charisk_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt3_charisk_o] \
  [get_bd_pins jesd204_phy_0/gt3_txcharisk]
  connect_bd_net -net jesd204b_tx_wrapper_0_vgt3_tdata_o  [get_bd_pins jesd204b_tx_wrapper_0/vgt3_tdata_o] \
  [get_bd_pins jesd204_phy_0/gt3_txdata]
  connect_bd_net -net jesd_transport_0_addr_state_dac0  [get_bd_pins jesd_transport_0/addr_state_dac0] \
  [get_bd_pins ila_fastdac/probe6]
  connect_bd_net -net jesd_transport_0_fastdac_seq_data_dac0_int  [get_bd_pins jesd_transport_0/fastdac_seq_data_dac0_int] \
  [get_bd_pins ila_fastdac/probe7]
  connect_bd_net -net jesd_transport_0_rd_en_4  [get_bd_pins jesd_transport_0/rd_en_4] \
  [get_bd_pins rd_en_4]
  connect_bd_net -net jesd_transport_0_rd_en_16  [get_bd_pins jesd_transport_0/rd_en_16] \
  [get_bd_pins rd_en_16]
  connect_bd_net -net jesd_transport_0_rng_value  [get_bd_pins jesd_transport_0/rng_value] \
  [get_bd_pins rng_value]
  connect_bd_net -net jesd_transport_0_tx_tdata  [get_bd_pins jesd_transport_0/tx_tdata] \
  [get_bd_pins jesd204b_tx_wrapper_0/vtx_tdata_i]
  connect_bd_net -net q_gc_time_valid_mod16_1  [get_bd_pins q_gc_time_valid_mod16] \
  [get_bd_pins jesd_transport_0/q_gc_time_valid_mod16]
  connect_bd_net -net qpll0_refclk_0_1  [get_bd_pins qpll0_refclk_0] \
  [get_bd_pins jesd204_phy_0/qpll0_refclk]
  connect_bd_net -net s_axi_aclk_1  [get_bd_pins s_axi_aclk] \
  [get_bd_pins jesd_transport_0/s_axil_aclk] \
  [get_bd_pins jesd204b_tx_wrapper_0/s_axil_aclk]
  connect_bd_net -net s_axi_aresetn_1  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins jesd_transport_0/s_axil_aresetn] \
  [get_bd_pins jesd204b_tx_wrapper_0/s_axil_aresetn]
  connect_bd_net -net tdata200_mod_1  [get_bd_pins tdata200_mod] \
  [get_bd_pins jesd_transport_0/tdata200_mod]
  connect_bd_net -net test_jesd_reset_0_syncout_o  [get_bd_pins sync_tx_tready_0/tx_tready_o] \
  [get_bd_pins ila_fastdac/probe0] \
  [get_bd_pins jesd_transport_0/tx_tready]
  connect_bd_net -net tvalid200_1  [get_bd_pins tvalid200] \
  [get_bd_pins jesd_transport_0/tvalid200]
  connect_bd_net -net tx_core_clk_0_1  [get_bd_pins tx_core_clk_0] \
  [get_bd_pins ila_fastdac/clk] \
  [get_bd_pins jesd204_phy_0/drpclk] \
  [get_bd_pins jesd204_phy_0/tx_core_clk] \
  [get_bd_pins jesd204_phy_0/rx_core_clk] \
  [get_bd_pins jesd_transport_0/tx_core_clk] \
  [get_bd_pins sync_tx_tready_0/tx_core_clk] \
  [get_bd_pins jesd204b_tx_wrapper_0/tx_core_clk]
  connect_bd_net -net tx_core_reset_1  [get_bd_pins tx_core_reset] \
  [get_bd_pins jesd204_phy_0/tx_sys_reset] \
  [get_bd_pins jesd_transport_0/tx_core_reset] \
  [get_bd_pins sync_tx_tready_0/tx_core_rst] \
  [get_bd_pins jesd204b_tx_wrapper_0/tx_core_reset]
  connect_bd_net -net tx_sync_0_1  [get_bd_pins tx_sync_0] \
  [get_bd_pins ila_fastdac/probe3] \
  [get_bd_pins jesd204b_tx_wrapper_0/btx_sync_i]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: spi_dacs_ltc
proc create_hier_cell_spi_dacs_ltc { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_spi_dacs_ltc() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv Veriqloud:com:ext_spi_rtl:1.0 com_ext_spi_dl


  # Create pins
  create_bd_pin -dir I -type clk ext_spi_clk
  create_bd_pin -dir I -type rst s_axi_aresetn

  # Create instance: axi_quad_spi_0, and set properties
  set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_0 ]
  set_property CONFIG.C_NUM_SS_BITS {3} $axi_quad_spi_0


  # Create instance: spi_inout_mngt_0, and set properties
  set block_name spi_inout_mngt
  set block_cell_name spi_inout_mngt_0
  if { [catch {set spi_inout_mngt_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $spi_inout_mngt_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins com_ext_spi_dl] [get_bd_intf_pins spi_inout_mngt_0/com_ext_spi]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins AXI_LITE] [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]

  # Create port connections
  connect_bd_net -net axi_quad_spi_0_io0_o  [get_bd_pins axi_quad_spi_0/io0_o] \
  [get_bd_pins spi_inout_mngt_0/in0_i]
  connect_bd_net -net axi_quad_spi_0_io0_t  [get_bd_pins axi_quad_spi_0/io0_t] \
  [get_bd_pins spi_inout_mngt_0/in0t_i]
  connect_bd_net -net axi_quad_spi_0_io1_o  [get_bd_pins axi_quad_spi_0/io1_o] \
  [get_bd_pins spi_inout_mngt_0/in1_i]
  connect_bd_net -net axi_quad_spi_0_io1_t  [get_bd_pins axi_quad_spi_0/io1_t] \
  [get_bd_pins spi_inout_mngt_0/in1t_i]
  connect_bd_net -net axi_quad_spi_0_sck_o  [get_bd_pins axi_quad_spi_0/sck_o] \
  [get_bd_pins spi_inout_mngt_0/sck_i]
  connect_bd_net -net axi_quad_spi_0_sck_t  [get_bd_pins axi_quad_spi_0/sck_t] \
  [get_bd_pins spi_inout_mngt_0/sckt_i]
  connect_bd_net -net axi_quad_spi_0_ss_o  [get_bd_pins axi_quad_spi_0/ss_o] \
  [get_bd_pins spi_inout_mngt_0/ss_i]
  connect_bd_net -net axi_quad_spi_0_ss_t  [get_bd_pins axi_quad_spi_0/ss_t] \
  [get_bd_pins spi_inout_mngt_0/sst_i]
  connect_bd_net -net ext_spi_clk_1  [get_bd_pins ext_spi_clk] \
  [get_bd_pins axi_quad_spi_0/ext_spi_clk] \
  [get_bd_pins axi_quad_spi_0/s_axi_aclk]
  connect_bd_net -net s_axi_aresetn_1  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins axi_quad_spi_0/s_axi_aresetn]
  connect_bd_net -net spi_inout_mngt_0_out0_o  [get_bd_pins spi_inout_mngt_0/out0_o] \
  [get_bd_pins axi_quad_spi_0/io0_i]
  connect_bd_net -net spi_inout_mngt_0_out1_o  [get_bd_pins spi_inout_mngt_0/out1_o] \
  [get_bd_pins axi_quad_spi_0/io1_i]
  connect_bd_net -net spi_inout_mngt_0_sck_o  [get_bd_pins spi_inout_mngt_0/sck_o] \
  [get_bd_pins axi_quad_spi_0/sck_i]
  connect_bd_net -net spi_inout_mngt_0_ss_o  [get_bd_pins spi_inout_mngt_0/ss_o] \
  [get_bd_pins axi_quad_spi_0/ss_i]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set pcie_7x_mgt_rtl [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_7x_mgt_rtl ]

  set c0_ddr4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 c0_ddr4 ]

  set tdc_ext_in [ create_bd_intf_port -mode Slave -vlnv Veriqloud:tdc:ext_in_rtl:1.0 tdc_ext_in ]

  set tdc_ext_clkrst [ create_bd_intf_port -mode Master -vlnv Veriqloud:tdc:ext_clkrst_rtl:1.0 tdc_ext_clkrst ]

  set com_ext_spi_tdc [ create_bd_intf_port -mode Slave -vlnv Veriqloud:com:ext_spi_rtl:1.0 com_ext_spi_tdc ]

  set com_ext_spi_dl [ create_bd_intf_port -mode Slave -vlnv Veriqloud:com:ext_spi_rtl:1.0 com_ext_spi_dl ]

  set cr_ext_cr [ create_bd_intf_port -mode Slave -vlnv Veriqloud:cr:ext_cr_rtl:1.0 cr_ext_cr ]


  # Create ports
  set sys_rst_n [ create_bd_port -dir I -type rst sys_rst_n ]
  set sys_clk_n [ create_bd_port -dir I sys_clk_n ]
  set sys_clk_p [ create_bd_port -dir I sys_clk_p ]
  set ext_fastdac_txp_out [ create_bd_port -dir O -from 3 -to 0 ext_fastdac_txp_out ]
  set ext_fastdac_txn_out [ create_bd_port -dir O -from 3 -to 0 ext_fastdac_txn_out ]
  set ext_pps [ create_bd_port -dir I ext_pps ]
  set ddr_sys_clk_n [ create_bd_port -dir I -type clk ddr_sys_clk_n ]
  set ddr_sys_clk_p [ create_bd_port -dir I -type clk ddr_sys_clk_p ]
  set ext_sync_ltc [ create_bd_port -dir O ext_sync_ltc ]
  set led [ create_bd_port -dir O -from 0 -to 0 led ]
  set pulse_n [ create_bd_port -dir O -from 0 -to 0 pulse_n ]
  set pulse_p [ create_bd_port -dir O -from 0 -to 0 pulse_p ]
  set probe_tdc_refclk [ create_bd_port -dir O probe_tdc_refclk ]
  set probe_tdc_rstidx [ create_bd_port -dir O probe_tdc_rstidx ]
  set pps_trigger [ create_bd_port -dir O pps_trigger ]
  set linterrupt_i [ create_bd_port -dir I linterrupt_i ]
  set ext_stopa_sim [ create_bd_port -dir O ext_stopa_sim ]
  set locked_pll [ create_bd_port -dir O locked_pll ]
  set read_done [ create_bd_port -dir O read_done ]
  set rd_en_fifo_gc [ create_bd_port -dir O rd_en_fifo_gc ]
  set fifo_gc_out_rst [ create_bd_port -dir O -type rst fifo_gc_out_rst ]
  set rd_gc_valid [ create_bd_port -dir O rd_gc_valid ]
  set ext_clk200_o [ create_bd_port -dir O -type clk ext_clk200_o ]
  set rst_jic [ create_bd_port -dir O rst_jic ]
  set decoy_signal_p [ create_bd_port -dir O decoy_signal_p ]
  set decoy_signal_n [ create_bd_port -dir O decoy_signal_n ]
  set decoy_signal [ create_bd_port -dir O decoy_signal ]
  set ext_sysref [ create_bd_port -dir O -type clk ext_sysref ]

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0 ]
  set_property -dict [list \
    CONFIG.PF0_DEVICE_ID_mqdma {9034} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {A034} \
    CONFIG.PF2_DEVICE_ID_mqdma {9234} \
    CONFIG.PF3_DEVICE_ID_mqdma {9334} \
    CONFIG.axi_data_width {128_bit} \
    CONFIG.axil_master_64bit_en {false} \
    CONFIG.axilite_master_en {true} \
    CONFIG.axilite_master_scale {Megabytes} \
    CONFIG.axilite_master_size {32} \
    CONFIG.axist_bypass_en {false} \
    CONFIG.axisten_freq {250} \
    CONFIG.pf0_device_id {9034} \
    CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
    CONFIG.pl_link_cap_max_link_width {X4} \
    CONFIG.plltype {QPLL1} \
    CONFIG.xdma_axi_intf_mm {AXI_Stream} \
    CONFIG.xdma_rnum_chnl {4} \
    CONFIG.xdma_wnum_chnl {4} \
  ] $xdma_0


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property CONFIG.NUM_MI {9} $axi_interconnect_0


  # Create instance: spi_dacs_ltc
  create_hier_cell_spi_dacs_ltc [current_bd_instance .] spi_dacs_ltc

  # Create instance: pcierefclk_0, and set properties
  set block_name pcierefclk
  set block_cell_name pcierefclk_0
  if { [catch {set pcierefclk_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $pcierefclk_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fastdac
  create_hier_cell_fastdac [current_bd_instance .] fastdac

  # Create instance: clk_rst
  create_hier_cell_clk_rst [current_bd_instance .] clk_rst

  # Create instance: ddr4
  create_hier_cell_ddr4 [current_bd_instance .] ddr4

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.AUTO_PRIMITIVE {MMCM} \
    CONFIG.CLKIN1_JITTER_PS {100.0} \
    CONFIG.CLKIN1_UI_JITTER {0.0010} \
    CONFIG.CLKOUT1_DRIVES {Buffer} \
    CONFIG.CLKOUT1_JITTER {182.015} \
    CONFIG.CLKOUT1_PHASE_ERROR {353.086} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {240} \
    CONFIG.CLKOUT1_REQUESTED_PHASE {0} \
    CONFIG.CLKOUT2_DRIVES {Buffer} \
    CONFIG.CLKOUT2_JITTER {211.971} \
    CONFIG.CLKOUT2_PHASE_ERROR {353.086} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {80} \
    CONFIG.CLKOUT2_REQUESTED_PHASE {90} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {Buffer} \
    CONFIG.CLKOUT3_JITTER {209.021} \
    CONFIG.CLKOUT3_PHASE_ERROR {320.727} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLKOUT3_REQUESTED_PHASE {0.000} \
    CONFIG.CLKOUT3_USED {false} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
    CONFIG.CLK_IN2_BOARD_INTERFACE {Custom} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.JITTER_SEL {No_Jitter} \
    CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {120.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {100.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} \
    CONFIG.MMCM_CLKOUT0_PHASE {0.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {15} \
    CONFIG.MMCM_CLKOUT1_PHASE {90.000} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {1} \
    CONFIG.MMCM_CLKOUT2_PHASE {0.000} \
    CONFIG.MMCM_COMPENSATION {AUTO} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.MMCM_REF_JITTER1 {0.001} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {false} \
    CONFIG.PHASESHIFT_MODE {LATENCY} \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_IN_FREQ {10} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_CLKFB_STOPPED {false} \
    CONFIG.USE_INCLK_STOPPED {false} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_0


  # Create instance: tdc
  create_hier_cell_tdc [current_bd_instance .] tdc

  # Create instance: decoy
  create_hier_cell_decoy [current_bd_instance .] decoy

  # Create instance: ttl_gate_apd_0, and set properties
  set block_name ttl_gate_apd
  set block_cell_name ttl_gate_apd_0
  if { [catch {set ttl_gate_apd_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ttl_gate_apd_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {15000000} \
 ] [get_bd_pins /ttl_gate_apd_0/s_axil_aclk]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins spi_dacs_ltc/AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins tdc/S_AXIL_PCIE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins fastdac/s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins clk_rst/s_axil]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins ttl_gate_apd_0/s_axil]
  connect_bd_intf_net -intf_net axi_interconnect_0_M05_AXI [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins tdc/AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M06_AXI [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins fastdac/s_axil]
  connect_bd_intf_net -intf_net axi_interconnect_0_M07_AXI [get_bd_intf_pins axi_interconnect_0/M07_AXI] [get_bd_intf_pins ddr4/s_axil]
  connect_bd_intf_net -intf_net axi_interconnect_0_M08_AXI [get_bd_intf_pins axi_interconnect_0/M08_AXI] [get_bd_intf_pins decoy/s_axil]
  connect_bd_intf_net -intf_net com_ext_spi_0_1 [get_bd_intf_ports com_ext_spi_tdc] [get_bd_intf_pins tdc/com_ext_spi_tdc]
  connect_bd_intf_net -intf_net com_ext_spi_0_2 [get_bd_intf_ports com_ext_spi_dl] [get_bd_intf_pins spi_dacs_ltc/com_ext_spi_dl]
  connect_bd_intf_net -intf_net cr_ext_cr_0_1 [get_bd_intf_ports cr_ext_cr] [get_bd_intf_pins clk_rst/cr_ext_cr]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports c0_ddr4] [get_bd_intf_pins ddr4/c0_ddr4]
  connect_bd_intf_net -intf_net ddr4_M_AXIS [get_bd_intf_pins ddr4/M_AXIS] [get_bd_intf_pins xdma_0/S_AXIS_C2H_1]
  connect_bd_intf_net -intf_net ddr4_M_AXIS1 [get_bd_intf_pins xdma_0/S_AXIS_C2H_3] [get_bd_intf_pins ddr4/M_AXIS1]
  connect_bd_intf_net -intf_net s_axis_1 [get_bd_intf_pins decoy/s_axis] [get_bd_intf_pins xdma_0/M_AXIS_H2C_3]
  connect_bd_intf_net -intf_net tdc_M_AXIS1 [get_bd_intf_pins xdma_0/S_AXIS_C2H_2] [get_bd_intf_pins tdc/M_AXIS1]
  connect_bd_intf_net -intf_net tdc_ext_in_0_1 [get_bd_intf_ports tdc_ext_in] [get_bd_intf_pins tdc/tdc_ext_in]
  connect_bd_intf_net -intf_net tdc_tdc_ext_clkrst_0 [get_bd_intf_ports tdc_ext_clkrst] [get_bd_intf_pins tdc/tdc_ext_clkrst]
  connect_bd_intf_net -intf_net xdma_0_M_AXIS_H2C_0 [get_bd_intf_pins xdma_0/M_AXIS_H2C_0] [get_bd_intf_pins ddr4/s_axis_gc]
  connect_bd_intf_net -intf_net xdma_0_M_AXIS_H2C_1 [get_bd_intf_pins xdma_0/M_AXIS_H2C_1] [get_bd_intf_pins fastdac/s_axis1]
  connect_bd_intf_net -intf_net xdma_0_M_AXI_LITE [get_bd_intf_pins xdma_0/M_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pcie_7x_mgt_rtl] [get_bd_intf_pins xdma_0/pcie_mgt]

  # Create port connections
  connect_bd_net -net M00_ACLK_1  [get_bd_pins ddr4/addn_ui_clkout1] \
  [get_bd_pins spi_dacs_ltc/ext_spi_clk] \
  [get_bd_pins fastdac/s_axi_aclk] \
  [get_bd_pins clk_rst/s_axil_aclk] \
  [get_bd_pins tdc/s_axil_aclk] \
  [get_bd_pins decoy/s_axil_aclk] \
  [get_bd_pins axi_interconnect_0/M00_ACLK] \
  [get_bd_pins axi_interconnect_0/M01_ACLK] \
  [get_bd_pins axi_interconnect_0/M02_ACLK] \
  [get_bd_pins axi_interconnect_0/M03_ACLK] \
  [get_bd_pins axi_interconnect_0/M04_ACLK] \
  [get_bd_pins axi_interconnect_0/M05_ACLK] \
  [get_bd_pins axi_interconnect_0/M06_ACLK] \
  [get_bd_pins axi_interconnect_0/M07_ACLK] \
  [get_bd_pins axi_interconnect_0/M08_ACLK] \
  [get_bd_pins ttl_gate_apd_0/s_axil_aclk]
  connect_bd_net -net M00_ARESETN_1  [get_bd_pins clk_rst/rstn_axil_o] \
  [get_bd_pins spi_dacs_ltc/s_axi_aresetn] \
  [get_bd_pins fastdac/s_axi_aresetn] \
  [get_bd_pins tdc/s_axil_aresetn] \
  [get_bd_pins ddr4/s_axil_aresetn] \
  [get_bd_pins decoy/s_axil_aresetn] \
  [get_bd_pins axi_interconnect_0/M00_ARESETN] \
  [get_bd_pins axi_interconnect_0/M01_ARESETN] \
  [get_bd_pins axi_interconnect_0/M02_ARESETN] \
  [get_bd_pins axi_interconnect_0/M03_ARESETN] \
  [get_bd_pins axi_interconnect_0/M04_ARESETN] \
  [get_bd_pins axi_interconnect_0/M05_ARESETN] \
  [get_bd_pins axi_interconnect_0/M06_ARESETN] \
  [get_bd_pins axi_interconnect_0/M07_ARESETN] \
  [get_bd_pins axi_interconnect_0/M08_ARESETN] \
  [get_bd_pins ttl_gate_apd_0/s_axil_aresetn]
  connect_bd_net -net clk10_i_1  [get_bd_pins clk_rst/clk10_o] \
  [get_bd_pins tdc/clk10_i] \
  [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net clk_in1_n_0_1  [get_bd_ports ddr_sys_clk_n] \
  [get_bd_pins ddr4/ddr_sys_clk_n]
  connect_bd_net -net clk_in1_p_0_1  [get_bd_ports ddr_sys_clk_p] \
  [get_bd_pins ddr4/ddr_sys_clk_p]
  connect_bd_net -net clk_rst_clk3125  [get_bd_pins clk_rst/clk3125] \
  [get_bd_pins fastdac/btx_sysref_i] \
  [get_bd_ports ext_sysref]
  connect_bd_net -net clk_rst_mngt_0_qpll0_refclk_o  [get_bd_pins clk_rst/qpll0_refclk_o] \
  [get_bd_pins fastdac/qpll0_refclk_0]
  connect_bd_net -net clk_rst_mngt_0_tx_core_clk_o  [get_bd_pins clk_rst/clk200] \
  [get_bd_pins fastdac/tx_core_clk_0] \
  [get_bd_pins tdc/clk200_i] \
  [get_bd_pins ddr4/clk200_i] \
  [get_bd_ports ext_clk200_o] \
  [get_bd_pins decoy/clk200]
  connect_bd_net -net clk_rst_mngt_0_tx_sync_o  [get_bd_pins clk_rst/tx_sync_o] \
  [get_bd_pins fastdac/tx_sync_0]
  connect_bd_net -net clk_rst_rstn_ddr_axi_o  [get_bd_pins clk_rst/rstn_ddr_axi_o] \
  [get_bd_pins ddr4/c0_ddr4_aresetn]
  connect_bd_net -net clk_rst_tdc_rst_o  [get_bd_pins clk_rst/tdc_rst_o] \
  [get_bd_pins tdc/tdc_rst]
  connect_bd_net -net clk_rst_ttl_rst  [get_bd_pins clk_rst/ttl_rst] \
  [get_bd_pins ttl_gate_apd_0/ttl_rst]
  connect_bd_net -net clk_rst_tx_core_reset_o  [get_bd_pins clk_rst/tx_core_reset_o] \
  [get_bd_pins fastdac/tx_core_reset] \
  [get_bd_pins decoy/tx_core_rst]
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins clk_wiz_0/clk_out1] \
  [get_bd_pins decoy/clk240] \
  [get_bd_pins ttl_gate_apd_0/clk240]
  connect_bd_net -net clk_wiz_0_clk_out2  [get_bd_pins clk_wiz_0/clk_out2] \
  [get_bd_pins decoy/clk80] \
  [get_bd_pins ttl_gate_apd_0/clk80]
  connect_bd_net -net clk_wiz_0_locked  [get_bd_pins clk_wiz_0/locked] \
  [get_bd_ports locked_pll]
  connect_bd_net -net ddr4_0_c0_init_calib_complete  [get_bd_pins ddr4/led] \
  [get_bd_ports led]
  connect_bd_net -net ddr4_c0_ddr4_ui_clk  [get_bd_pins ddr4/c0_ddr4_ui_clk] \
  [get_bd_pins clk_rst/clk_ddr_axi_i]
  connect_bd_net -net ddr4_c0_ddr4_ui_clk_sync_rst  [get_bd_pins ddr4/c0_ddr4_ui_clk_sync_rst] \
  [get_bd_pins clk_rst/rst_ddr_axi_i]
  connect_bd_net -net ddr4_fifo_gc_rst_0  [get_bd_pins ddr4/fifo_gc_rst_0] \
  [get_bd_ports fifo_gc_out_rst]
  connect_bd_net -net ddr4_rd_en_fifo_gc_0  [get_bd_pins ddr4/rd_en_fifo_gc_0] \
  [get_bd_ports rd_en_fifo_gc]
  connect_bd_net -net ddr4_rd_gc_valid_0  [get_bd_pins ddr4/rd_gc_valid_0] \
  [get_bd_ports rd_gc_valid]
  connect_bd_net -net ddr4_read_done_0  [get_bd_pins ddr4/read_done_0] \
  [get_bd_ports read_done]
  connect_bd_net -net ddr_data_rstn_1  [get_bd_pins clk_rst/ddr_data_rstn_o] \
  [get_bd_pins ddr4/ddr_data_rstn]
  connect_bd_net -net decoy_decoy_signal_0  [get_bd_pins decoy/decoy_signal_0] \
  [get_bd_ports decoy_signal]
  connect_bd_net -net decoy_decoy_signal_n_0  [get_bd_pins decoy/decoy_signal_n_0] \
  [get_bd_ports decoy_signal_n]
  connect_bd_net -net decoy_decoy_signal_p_0  [get_bd_pins decoy/decoy_signal_p_0] \
  [get_bd_ports decoy_signal_p]
  connect_bd_net -net decoy_rst_1  [get_bd_pins clk_rst/decoy_rst] \
  [get_bd_pins decoy/decoy_rst]
  connect_bd_net -net ext_pps_1  [get_bd_ports ext_pps] \
  [get_bd_pins clk_rst/ext_pps] \
  [get_bd_pins fastdac/ext_pps] \
  [get_bd_pins tdc/ext_pps] \
  [get_bd_pins ddr4/ext_pps] \
  [get_bd_pins decoy/ext_pps] \
  [get_bd_pins ttl_gate_apd_0/pps_i]
  connect_bd_net -net fastdac_gt_powergood  [get_bd_pins fastdac/gt_powergood] \
  [get_bd_pins clk_rst/fastdac_gt_powergood_i]
  connect_bd_net -net gc_rst_1  [get_bd_pins clk_rst/gc_rst_o] \
  [get_bd_pins tdc/gc_rst]
  connect_bd_net -net gc_time_valid_1  [get_bd_pins tdc/gc_time_valid] \
  [get_bd_pins fastdac/gc_time_valid]
  connect_bd_net -net jesd204_phy_0_txn_out  [get_bd_pins fastdac/ext_fastdac_txn_out] \
  [get_bd_ports ext_fastdac_txn_out]
  connect_bd_net -net jesd204_phy_0_txp_out  [get_bd_pins fastdac/ext_fastdac_txp_out] \
  [get_bd_ports ext_fastdac_txp_out]
  connect_bd_net -net linterrupt_i_0_1  [get_bd_ports linterrupt_i] \
  [get_bd_pins tdc/linterrupt_i_0]
  connect_bd_net -net lrst_i_1  [get_bd_pins clk_rst/lrst_o] \
  [get_bd_pins tdc/lrst_i]
  connect_bd_net -net pcierefclk_0_O  [get_bd_pins pcierefclk_0/O] \
  [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net pcierefclk_0_ODIV2  [get_bd_pins pcierefclk_0/ODIV2] \
  [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net probe7_1  [get_bd_pins fastdac/rd_en_4] \
  [get_bd_pins ddr4/rd_en_4] \
  [get_bd_pins tdc/rd_en_4] \
  [get_bd_pins decoy/rd_en_4]
  connect_bd_net -net q_gc_time_valid_mod16_1  [get_bd_pins tdc/q_gc_time_valid_mod16] \
  [get_bd_pins fastdac/q_gc_time_valid_mod16]
  connect_bd_net -net rd_en_16_1  [get_bd_pins fastdac/rd_en_16] \
  [get_bd_pins decoy/rd_en_16]
  connect_bd_net -net rng_a_data_1  [get_bd_pins decoy/rng_a] \
  [get_bd_pins ddr4/rng_a_data]
  connect_bd_net -net rng_data_1  [get_bd_pins fastdac/rng_value] \
  [get_bd_pins ddr4/rng_data] \
  [get_bd_pins tdc/rng_value] \
  [get_bd_pins decoy/rng_value]
  connect_bd_net -net sync_ltc_0_sync_ltc  [get_bd_pins clk_rst/ext_sync_ltc] \
  [get_bd_ports ext_sync_ltc]
  connect_bd_net -net sys_clk_n_1  [get_bd_ports sys_clk_n] \
  [get_bd_pins pcierefclk_0/IB]
  connect_bd_net -net sys_clk_p_1  [get_bd_ports sys_clk_p] \
  [get_bd_pins pcierefclk_0/I]
  connect_bd_net -net sys_rst_n_0_1  [get_bd_ports sys_rst_n] \
  [get_bd_pins ddr4/sys_rst_n] \
  [get_bd_pins clk_rst/sys_rst_n] \
  [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net tdata200_1  [get_bd_pins tdc/tdata200] \
  [get_bd_pins ddr4/tdata200]
  connect_bd_net -net tdata200_mod_1  [get_bd_pins tdc/tdata200_mod] \
  [get_bd_pins ddr4/tdata200_mod] \
  [get_bd_pins fastdac/tdata200_mod]
  connect_bd_net -net tdc_O_lclk  [get_bd_pins tdc/O_lclk] \
  [get_bd_pins clk_rst/lclk_i]
  connect_bd_net -net tdc_gate_pos0  [get_bd_pins tdc/gate_pos0] \
  [get_bd_pins ddr4/gate_pos0] \
  [get_bd_pins fastdac/gate_pos0]
  connect_bd_net -net tdc_gate_pos1  [get_bd_pins tdc/gate_pos1] \
  [get_bd_pins ddr4/gate_pos1] \
  [get_bd_pins fastdac/gate_pos1]
  connect_bd_net -net tdc_gate_pos2  [get_bd_pins tdc/gate_pos2] \
  [get_bd_pins ddr4/gate_pos2] \
  [get_bd_pins fastdac/gate_pos2]
  connect_bd_net -net tdc_gate_pos3  [get_bd_pins tdc/gate_pos3] \
  [get_bd_pins ddr4/gate_pos3] \
  [get_bd_pins fastdac/gate_pos3]
  connect_bd_net -net tdc_pps_trigger  [get_bd_pins tdc/pps_trigger] \
  [get_bd_ports pps_trigger]
  connect_bd_net -net tdc_probe_tdc_refclk  [get_bd_pins tdc/probe_tdc_refclk] \
  [get_bd_ports probe_tdc_refclk]
  connect_bd_net -net tdc_probe_tdc_rstidx  [get_bd_pins tdc/probe_tdc_rstidx] \
  [get_bd_ports probe_tdc_rstidx]
  connect_bd_net -net tdc_rst_jic_0  [get_bd_pins tdc/rst_jic_0] \
  [get_bd_ports rst_jic]
  connect_bd_net -net tdc_stopa_sim_0  [get_bd_pins tdc/stopa_sim_0] \
  [get_bd_ports ext_stopa_sim]
  connect_bd_net -net ttl_gate_apd_0_pulse_n  [get_bd_pins ttl_gate_apd_0/pulse_n] \
  [get_bd_ports pulse_n]
  connect_bd_net -net ttl_gate_apd_0_pulse_p  [get_bd_pins ttl_gate_apd_0/pulse_p] \
  [get_bd_ports pulse_p]
  connect_bd_net -net tvalid200_1  [get_bd_pins tdc/tvalid200] \
  [get_bd_pins ddr4/tvalid200] \
  [get_bd_pins fastdac/tvalid200]
  connect_bd_net -net xdma_0_axi_aclk  [get_bd_pins xdma_0/axi_aclk] \
  [get_bd_pins fastdac/aclk] \
  [get_bd_pins tdc/m_axi_tclk] \
  [get_bd_pins ddr4/aclk] \
  [get_bd_pins decoy/s_axis_clk] \
  [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins axi_interconnect_0/S00_ACLK]
  connect_bd_net -net xdma_0_axi_aresetn  [get_bd_pins xdma_0/axi_aresetn] \
  [get_bd_pins fastdac/aresetn] \
  [get_bd_pins ddr4/aresetn] \
  [get_bd_pins decoy/s_axis_tresetn] \
  [get_bd_pins axi_interconnect_0/ARESETN] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs spi_dacs_ltc/axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00013000 -range 0x00001000 -with_name SEG_axi_quad_spi_0_Reg_1 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs tdc/time_spi/axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00012000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs clk_rst/clk_rst_mngt/s_axil/reg0] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs ddr4/ddr_data_reg_mngt_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00016000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs decoy/decoy_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00010000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs fastdac/jesd204b_tx_wrapper_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00030000 -range 0x00008000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs fastdac/jesd_transport_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00015000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs ttl_gate_apd_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ddr4/axi_virtual_controll_0/m_axi] [get_bd_addr_segs ddr4/axi_clock_converter_0/s_axi/reg0] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ddr4/axi_clock_converter_0/m_axi] [get_bd_addr_segs ddr4/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

