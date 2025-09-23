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
Run these command in vivado Tcl console:
```
cd [your local directory]/abc/
```
```
source run_all.tcl
```
If output message is "done", you can generate bitstream.The first time you generate, it takes around 30 minutes because Vivado has to Synthesis all modules from scratch. 
When you make little changes you can set design check point (DCP) for incremental synthesis to save time.
## Create TCL scripts (for Dev)
This is my flow to create the Tcl scripts. I want to separate project and block design so vivado won't copy the sources to local vivado project.
Before create Tcl scripts, remove all design checkpoints (.dcp) and waveforms (.wcfg) in vivado Sources
### Create project.tcl
File -> Project -> Write Tcl. Check in 2 options:
- Write all properties
- Write objects values

Removes everything regarding block design file (.bd). Save the project.tcl
### Create block_design.tcl
File -> Export -> Export Block Design

AXI and AXIS interfaces in vivado project will reset to default clock frequency (100MHz), generate the mistmatched FREQ_HZ errors.
Modify the block_design.tcl as follow:

- Before the line 'validate_bd_design', add:
```
source fix_frequency.tcl
```
- Save block_design.tcl
## Archive project (for Dev)
File -> Project -> Archive. Check in 2 options:
- Include configuration settings
- Include run results
Exclude local IP cache results to reduce size of the archive. Save Qline_turnkey.xpr.zip
## Release
- You can get full project without building from Tcl script in Released Source Qline_turnkey.xpr.zip. This is whole project including DCPs, waveforms, run results, settings.
- unzip and start building your bitstream !

