- This repos contains fpga source code for KiwiKD.
- FPGA board: XEM8310 from opalkelly
- FPGA: Xilinx Artix UltraScale+ (XCAU25P-2FFVB676E)
## Prerequisites
- Vivado 2022.2
- Vivado installation includes packages for UltraScale+ FPGA
- Install vivado board file for [XEM8310](https://docs.opalkelly.com/xem8310/vivado-board-file/) (Artix UltraScale+ FPGA)
## Build Vivado project from TCL scripts
### Clone project
```
git clone git@github.com:Veriqloud/kiwi_fpga.git
```
### Build project and block design 
Run these command in vivado Tcl console (if prompted due to invalid topmodule, select to automatically pick a top module and click OK):
```
cd [your local directory]/ABC/
```
```
source project.tcl
source block_design.tcl
```
### Troubleshoot the mismatch FREQ_HZ error
AXI and AXIS interfaces in vivado project will reset to default clock frequency (100MHz), generate the mistmatched FREQ_HZ error.

Run these command in Tcl console to change FREQ_HZ:
```
set_property CONFIG.FREQ_HZ 200000000 [get_bd_pins /tdc/tdc_mngt/AS6501_IF_0/m_axis_clk]
set_property CONFIG.FREQ_HZ 200000000 [get_bd_pins /ddr4/axi_virtual_controll_0/aclk]
set_property CONFIG.FREQ_HZ 200000000 [get_bd_intf_pins /ddr4/fifos_out_0/s_axis_alpha]
set_property CONFIG.FREQ_HZ 200000000 [get_bd_intf_pins /ddr4/fifos_out_0/s_axis_gco]
set_property CONFIG.FREQ_HZ 200000000 [get_bd_intf_pins /tdc/tdc_mngt/fifo_gc_tdc_rtl_0/s_axis]
disconnect_bd_net /ddr4/clk200_i_1 [get_bd_pins ddr4/system_ila_ddr/clk]
startgroup
create_bd_port -dir I -type clk -freq_hz 200000000 clk
set_property -dict [list CONFIG.CLK_DOMAIN [get_property CONFIG.CLK_DOMAIN [get_bd_pins ddr4/system_ila_ddr/clk]]] [get_bd_ports clk]
connect_bd_net [get_bd_pins /ddr4/system_ila_ddr/clk] [get_bd_ports clk]
validate_bd_design
```
Run these command to remove clk port and wrap the design:
```
delete_bd_objs [get_bd_nets clk_1] [get_bd_ports clk]
delete_bd_objs [get_bd_nets ddr4/clk_1] [get_bd_pins ddr4/clk]
connect_bd_net [get_bd_pins ddr4/clk200_i] [get_bd_pins ddr4/system_ila_ddr/clk]
validate_bd_design
set design_name [get_bd_designs]
make_wrapper -files [get_files Bob_top.bd] -top -import
save_bd_design
```
Select Bob_top_wrapper as top module.

Ignore critical Warnings in Synthesis.

After design is validated, succeed to create the wrapper, you can generate bitstream.
## Create TCL scripts (Optional)
This is my flow to create the Tcl scripts. I want to separate project and block design so vivado won't copy the sources to local vivado project.
Before create Tcl scripts, remove all design checkpoints (.dcp) and waveforms (.wcfg) in vivado Sources
### Create project.tcl
File -> Project -> Write Tcl. Check in 2 options:
- Write all properties
- Write objects values

Removes everything regarding HDL wrapper and block design file (.bd). Save the project.tcl
### Create block_design.tcl
File -> Export -> Export Block Design

## Release
- You can get full project without building from Tcl script in Released Source ABC_Prj.zip. This is local Vivado project.
- unzip and start building your bitstream !

