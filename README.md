- This repos contains fpga source code for KiwiKD.
- FPGA board: XEM8310 from opalkelly
- FPGA: Xilinx Artix UltraScale+ (XCAU25P-2FFVB676E)
## Prerequisites
- Vivado 2024.2
- Vivado installation includes packages for UltraScale+ FPGA
- Install vivado board file for [XEM8310](https://docs.opalkelly.com/xem8310/vivado-board-file/) (Artix UltraScale+ FPGA)
## Build Vivado project from TCL scripts
### Clone project
```
git clone git@github.com:Veriqloud/kiwi_fpga.git
```
### Build project and block design 
Run these command in vivado Tcl console (If prompted due to invalid topmodule, close the window!):
```
cd [your local directory]/ABC/
```
```
source run_all.tcl
```
If output message is "done", you can generate bitstream.
## Create TCL scripts (Optional)
This is my flow to create the Tcl scripts. I want to separate project and block design so vivado won't copy the sources to local vivado project.
Before create Tcl scripts, remove all design checkpoints (.dcp) and waveforms (.wcfg) in vivado Sources
### Create project.tcl
File -> Project -> Write Tcl. Check in 2 options:
- Write all properties
- Write objects values

Removes everything regarding block design file (.bd). Save the project.tcl
### Create block_design.tcl
File -> Export -> Export Block Design

AXI and AXIS interfaces in vivado project will reset to default clock frequency (100MHz), generate the mistmatched FREQ_HZ error.
Modify the block_design.tcl as follow:

- Before the line 'validate_bd_design', add:
```
source fix_frequency.tcl
```
## Release
- You can get full project without building from Tcl script in Released Source ABC_Prj.zip. This is local Vivado project.
- unzip and start building your bitstream !

