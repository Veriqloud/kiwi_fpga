This repos contains fpga source code for KiwiKD
## Prerequisites
- Vivado 2022.2
- Vivado installation includes packages for UltraScale+ FPGA
- Install vivado board file for [XEM8310](https://docs.opalkelly.com/xem8310/vivado-board-file/) (Artix UltraScale+ FPGA)
## Build Vivado project from TCL scripts
### Clone project
- `git clone git@github.com:Veriqloud/kiwi_fpga.git`
### Build project and block design 
Run these command in vivado Tcl console:
- `cd ../ABC/`
- `source project.tcl`
- `source block_design.tcl`
### Troubleshoot the mismatch FREQ_HZ error
## Create TCL scripts (Optional)

