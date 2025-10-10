- This repos contains fpga source code for KiwiKD.
- FPGA board: XEM8310 from opalkelly
- FPGA: Xilinx Artix UltraScale+ (XCAU25P-2FFVB676E)
## Prerequisites
- Vivado 2024.2
- Vivado installation includes packages for UltraScale+ FPGA
- Install vivado board file for [XEM8310](https://docs.opalkelly.com/xem8310/vivado-board-file/) (Artix UltraScale+ FPGA)

Note: 
- Install vivado board file is for developers
- For this specific project, board_part repos is already copied to /abc/boards/
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
If output message is "Done", you can generate bitstream.The first time you generate, it takes around 30 minutes because Vivado has to Synthesis all modules from scratch. 
When you make little changes you can set design check point (DCP) for incremental synthesis to save time.
### Known issues
1.You got "Done" message but you don't see block design : Because there are some vivado ips are locked. 
- Upgrade locked IPs, the red status of IPs should be gone
- source block_design.tcl in Tcl console
## Create TCL scripts (for Dev)
This is my flow to create the Tcl scripts. I want to separate project and block design so vivado won't copy the sources to local vivado project.
Before create Tcl scripts, remove all design checkpoints (.dcp) and waveforms (.wcfg) in vivado Sources
### Create project.tcl
File -> Project -> Write Tcl. Check in 2 options:
- Write all properties
- Write objects values

Modify the project.tcl:
- Removes everything regarding block design file (.bd)
- Replace parameter of board_part_repos_path to "$origin_dir/boards"
- Save the project.tcl
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
- Exclude local IP cache results to reduce size of the archive. 
- Save Qline_turnkey.xpr.zip
## Release
- You can get full project without building from Tcl script in Released Source Qline_turnkey.xpr.zip. This is whole project including DCPs, waveforms, run results, settings is there is any.
- unzip and start building your bitstream !

