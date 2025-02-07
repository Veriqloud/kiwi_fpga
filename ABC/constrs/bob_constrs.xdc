##Clocks and resets--------------------------------------------

create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]
set_property PACKAGE_PIN T6 [get_ports sys_clk_n]
set_property PACKAGE_PIN T7 [get_ports sys_clk_p]


set_false_path -from [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS12 [get_ports sys_rst_n]
set_property PACKAGE_PIN E22 [get_ports sys_rst_n]

create_clock -period 5.000 -name refclk -waveform {0.000 2.500} [get_ports ext_fastdac_refclk_p]
set_property PACKAGE_PIN AB6 [get_ports ext_fastdac_refclk_n]
set_property PACKAGE_PIN AB7 [get_ports ext_fastdac_refclk_p]

create_clock -period 320.000 -name sysrefclk -waveform {0.000 161.000} [get_ports ext_fastdac_sysref_p]
set_property PACKAGE_PIN AC19 [get_ports ext_fastdac_sysref_p]
set_property PACKAGE_PIN AD19 [get_ports ext_fastdac_sysref_n]
set_property IOSTANDARD LVDS [get_ports ext_fastdac_sysref_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_fastdac_sysref_*]

#set_property PACKAGE_PIN AA14 [get_ports ext_clk10_p]
#set_property PACKAGE_PIN AB14 [get_ports ext_clk10_n]
#set_property IOSTANDARD LVDS_25 [get_ports ext_clk10_*]
#set_property DIFF_TERM_ADV TERM_100 [get_ports ext_clk10_*]

create_clock -period 100.000 -name clk_10 [get_ports ext_clk10_p]
set_property PACKAGE_PIN B19 [get_ports ext_clk10_p]
set_property PACKAGE_PIN B20 [get_ports ext_clk10_n]
set_property IOSTANDARD LVDS [get_ports ext_clk10_*]

set_property PACKAGE_PIN AB15 [get_ports ext_clk100_p]
set_property PACKAGE_PIN AB16 [get_ports ext_clk100_n]
set_property IOSTANDARD LVDS_25 [get_ports ext_clk100_*]
#set_property DIFF_TERM_ADV TERM_100 [get_ports ext_clk100_*]

#create clock to test the FREQ_HZ
create_clock -period 5.000 -name clk200_net -waveform {0.000 2.500} [get_nets ext_clk200_o]


#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets Bb_top_i/clk_rst/clk_rst_mngt/inst/ibuf_clk100/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets Bob_top_i/clk_rst/clk_rst_mngt/inst/clk100_o]

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets Bb_top_i/clk_rst/clk_rst_mngt/inst/clk10_o]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets Bob_top_i/clk_rst/clk_rst_mngt/inst/clk10_o]

#set_clock_groups -asynchronous -group [get_clocks refclk] -group [get_clocks clk_10]

##Internal clock nets------------------------------------------
create_clock -period 5.000 -name clk200 [get_ports ext_clk200_o]
##Leds---------------------------------------------------------
set_property PACKAGE_PIN U24 [get_ports {led[0]}]
#set_property PACKAGE_PIN V19 [get_ports {led[1]}]
set_property PACKAGE_PIN V19 [get_ports locked_pll]
#set_property PACKAGE_PIN T24 [get_ports {led[2]}]
#set_property PACKAGE_PIN U19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports locked_pll]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[3]}]


##DDR----------------------------------------------------------
set_property PACKAGE_PIN J23 [get_ports ddr_sys_clk_p]
set_property PACKAGE_PIN J24 [get_ports ddr_sys_clk_n]
set_property IOSTANDARD LVDS [get_ports {ddr_sys_clk_p}]
#set property CLOCK_DEDICATED-ROUTE BACKBONE [get_nets {c0_sys_clk_p_0_1}]
#set property CLOCK_DEDICATED-ROUTE BACKBONE [get_nets {c0_sys_clk_n_0_1}]



##IOs------------------------------------
##Bank 64,65,67
##Fastdac
set_property PACKAGE_PIN AD16 [get_ports ext_fastdac_sync_p]
set_property PACKAGE_PIN AE16 [get_ports ext_fastdac_sync_n]
set_property IOSTANDARD LVDS [get_ports ext_fastdac_sync_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_fastdac_sync_*]
set_property IOB TRUE [get_ports ext_fastdac_sync_*]

##TTL gate
set_property IOSTANDARD LVDS [get_ports {pulse_p}]
set_property PACKAGE_PIN AA19 [get_ports {pulse_p}]  
set_property IOSTANDARD LVDS [get_ports {pulse_n}]
set_property PACKAGE_PIN AB19 [get_ports {pulse_n}]

set_property IOSTANDARD LVDS [get_ports {pulse_rep_p}]
set_property PACKAGE_PIN AA20 [get_ports {pulse_rep_p}]  
set_property IOSTANDARD LVDS [get_ports {pulse_rep_n}]
set_property PACKAGE_PIN AB20 [get_ports {pulse_rep_n}]

#TDC OUTPUT
set_property PACKAGE_PIN AD20 [get_ports ext_tdc_refclk_p]
set_property PACKAGE_PIN AE20 [get_ports ext_tdc_refclk_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_refclk_*]

set_property PACKAGE_PIN AF18 [get_ports ext_tdc_rstidxp_p]
set_property PACKAGE_PIN AF19 [get_ports ext_tdc_rstidxp_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_rstidxp_*]

set_property PACKAGE_PIN H13 [get_ports linterrupt_i]

#TDC INPUT
set_property PACKAGE_PIN AB25 [get_ports ext_tdc_sdi_A_p]
set_property PACKAGE_PIN AB26 [get_ports ext_tdc_sdi_A_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_sdi_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_tdc_sdi_*]

set_property PACKAGE_PIN AD23 [get_ports ext_tdc_frame_A_p]
set_property PACKAGE_PIN AE23 [get_ports ext_tdc_frame_A_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_frame_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_tdc_frame_*]

set_property PACKAGE_PIN AC26 [get_ports ext_tdc_sdi_B_p]
set_property PACKAGE_PIN AD26 [get_ports ext_tdc_sdi_B_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_sdi_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_tdc_sdi_*]

set_property PACKAGE_PIN AE25 [get_ports ext_tdc_frame_B_p]
set_property PACKAGE_PIN AE26 [get_ports ext_tdc_frame_B_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_frame_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_tdc_frame_*]

set_property PACKAGE_PIN AB21 [get_ports ext_tdc_lclki_p]
set_property PACKAGE_PIN AC21 [get_ports ext_tdc_lclki_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_lclki_*]
#set_property DIFF_TERM_ADV TERM_100 [get_ports ext_tdc_lclki_*]

create_clock -period 5.000 -name tdc_lclk -waveform {0.000 2.500} [get_ports ext_tdc_lclko_p]
set_property PACKAGE_PIN AD21 [get_ports ext_tdc_lclko_p]
set_property PACKAGE_PIN AE21 [get_ports ext_tdc_lclko_n]
set_property IOSTANDARD LVDS [get_ports ext_tdc_lclko_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports ext_tdc_lclko_*]


##Bank 84



##Bank 86,87
set_property PACKAGE_PIN K9 [get_ports ext_sync_ltc]
set_property PACKAGE_PIN F14 [get_ports ext_pps]
set_property IOSTANDARD LVCMOS33 [get_ports ext_pps]


##SPI buses
set_property PACKAGE_PIN G11 [get_ports ext_tdc_miso]
set_property PACKAGE_PIN H11 [get_ports ext_tdc_mosi]
set_property PACKAGE_PIN D10 [get_ports ext_tdc_sck]
set_property PACKAGE_PIN C9 [get_ports {ext_tdc_ss[0]}]
set_property PACKAGE_PIN K10 [get_ports {ext_tdc_ss[1]}]

#set_property PULLUP true [get_ports ext_rst_jic]
set_property PACKAGE_PIN J15 [get_ports ext_rst_jic]


set_property PACKAGE_PIN C11 [get_ports ext_dac_ltc_miso]
set_property PACKAGE_PIN B11 [get_ports ext_dac_ltc_mosi]
set_property PACKAGE_PIN D11 [get_ports ext_dac_ltc_sck]
set_property PACKAGE_PIN D9 [get_ports {ext_dac_ltc_ss[0]}]
set_property PACKAGE_PIN J9 [get_ports {ext_dac_ltc_ss[1]}]
set_property PACKAGE_PIN H9 [get_ports {ext_dac_ltc_ss[2]}]

set_property PACKAGE_PIN A9 [get_ports ext_clk200_o]
#set_property PACKAGE_PIN E10 [get_ports ext_tdc_rst]
set_property PACKAGE_PIN E11 [get_ports fifo_gc_out_rst]
set_property PACKAGE_PIN F12 [get_ports rd_gc_valid]

#set_property PACKAGE_PIN G12 [get_ports dout4_test_o]
set_property PACKAGE_PIN E13 [get_ports pps_trigger]
set_property PACKAGE_PIN E12 [get_ports probe_tdc_refclk]
set_property PACKAGE_PIN G12 [get_ports probe_tdc_rstidx]
set_property PACKAGE_PIN C12 [get_ports read_done]
set_property PACKAGE_PIN B12 [get_ports rd_en_fifo_gc]
set_property PACKAGE_PIN F13 [get_ports ext_stopa_sim]


set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 86]]
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 87]]

##GT banks
##224 for fastdac
set_property PACKAGE_PIN AF7 [get_ports {ext_fastdac_txp_out[0]}]
set_property PACKAGE_PIN AF6 [get_ports {ext_fastdac_txn_out[0]}]

set_property PACKAGE_PIN AE9 [get_ports {ext_fastdac_txp_out[1]}]
set_property PACKAGE_PIN AE8 [get_ports {ext_fastdac_txn_out[1]}]

set_property PACKAGE_PIN AD7 [get_ports {ext_fastdac_txp_out[2]}]
set_property PACKAGE_PIN AD6 [get_ports {ext_fastdac_txn_out[2]}]

set_property PACKAGE_PIN AC5 [get_ports {ext_fastdac_txp_out[3]}]
set_property PACKAGE_PIN AC4 [get_ports {ext_fastdac_txn_out[3]}]


###SET CONSTRAINTS RESETS
set_false_path -from [get_clocks mmcm_clkout1] -to [get_clocks refclk]
set_false_path -from [get_clocks mmcm_clkout1] -to [get_clocks clk_out1_Bob_top_clk_wiz_0_0]
set_false_path -from [get_clocks mmcm_clkout1] -to [get_clocks clk_out2_Bob_top_clk_wiz_0_0]

### SET CONSTRAINTS DDR_DATA
#set_false_path -from [get_clocks refclk] -to [get_clocks mmcm_clkout1]
#set_false_path -from [get_clocks xdma_0_axi_aclk] -to [get_clocks mmcm_clkout1]
#set_false_path -from [get_clocks refclk] -to [get_clocks xdma_0_axi_aclk]

###SET CONSTRAINTS TDC

set_false_path -from [get_cells Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg*_reg[*]] -to [get_clocks refclk]

set_false_path -from [get_cells Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg*_reg[*]] -to [get_clocks tdc_lclk]

#set_false_path -from [get_cells Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[0]] -to [get_cells Bob_top_i/tdc/AS6501_IF_0/inst/reg_enable_r_reg[0]]

#set_false_path -from [get_cells Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[1]] -to [get_cells Bob_top_i/tdc/AS6501_IF_0/inst/reg_enable200_r_reg[0]]


#set_multicycle_path -setup 2 -from [get_clocks refclk] -to [get_pins Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/s_axis_tdata_reg[*]/CE]

#set_multicycle_path -hold 1 -from [get_clocks refclk] -to [get_pins Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/s_axis_tdata_reg[*]/CE]



###SET CONSTRAINTS FASTDAC
set_false_path -through [get_pins Bob_top_i/fastdac/jesd204b_tx_wrapper_0/inst/tx_core_reset] -to [get_pins Bob_top_i/fastdac/jesd204b_tx_wrapper_0/inst/vtx_reset_gt_r_*/PRE]

set _shared_i0 [get_cells Bob_top_i/fastdac/jesd204b_tx_wrapper_0/inst/jesd204b_reg_mngt/slv_reg*_*]
set_false_path -from $_shared_i0 -to [get_clocks refclk]
set_false_path -from [get_clocks refclk] -to $_shared_i0 

#set _shared_i1 [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg*_*]
#set _shared_i2 [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/shift_shift1_r_reg[0]]

#set_false_path -from $_shared_i1 -to $_shared_i2
#set_false_path -from $_shared_i2 -to $_shared_i1


set_false_path -from [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg1_reg[*]] -to [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/shift1_r_reg[*]]

set_false_path -from [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg2_reg[*]] -to [get_clocks refclk]

set_false_path -from [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg*_reg[*]] -to [get_clocks refclk]

set_false_path -from [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg3_reg[0]] -to [get_cells Bob_top_i/fastdac/jesd_transport_0/inst/shift_shift1_r_reg[0]]


###SET CONSTRAINTS TTL
set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg0_reg[0]] -to [get_clocks clk_out2_Bob_top_clk_wiz_0_0]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg4_reg[0]] -to [get_clocks clk_out2_Bob_top_clk_wiz_0_0]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg5_reg[0]] -to [get_clocks clk_out2_Bob_top_clk_wiz_0_0]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[*]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_240_r_reg[0]]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[*]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_240_reg[*]]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[*]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_80_reg[*]]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg2_reg[0]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_240_r_reg[0]]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg2_reg[0]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_80_r_reg[0]]

set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg3_reg[*]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_80_r_reg[0]]

#set_false_path -from [get_cells Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg3_reg[*]] -to [get_cells Bob_top_i/ttl_gate_apd_0/inst/ttl_params_slv_reg[*]]