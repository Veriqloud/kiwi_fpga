##Clocks and resets--------------------------------------------

create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]
set_property PACKAGE_PIN T6 [get_ports sys_clk_n]
set_property PACKAGE_PIN T7 [get_ports sys_clk_p]

set_false_path -from [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS12 [get_ports sys_rst_n]
set_property PACKAGE_PIN E22 [get_ports sys_rst_n]

create_clock -period 5.000 -name refclk -waveform {0.000 2.500} [get_ports cr_ext_cr_fastdac_refclki_p]
set_property PACKAGE_PIN AB6 [get_ports cr_ext_cr_fastdac_refclki_n]
set_property PACKAGE_PIN AB7 [get_ports cr_ext_cr_fastdac_refclki_p]

create_clock -period 320.000 -name sysrefclk -waveform {0.000 161.000} [get_ports cr_ext_cr_fastdac_sysref_p]
set_property PACKAGE_PIN AC19 [get_ports cr_ext_cr_fastdac_sysref_p]
set_property PACKAGE_PIN AD19 [get_ports cr_ext_cr_fastdac_sysref_n]
set_property IOSTANDARD LVDS [get_ports cr_ext_cr_fastdac_sysref_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports cr_ext_cr_fastdac_sysref_*]

create_clock -period 100.000 -name clk_10 [get_ports cr_ext_cr_ext_clk10_p]
set_property PACKAGE_PIN B19 [get_ports cr_ext_cr_ext_clk10_p]
set_property PACKAGE_PIN B20 [get_ports cr_ext_cr_ext_clk10_n]
set_property IOSTANDARD LVDS [get_ports cr_ext_cr_ext_clk10_*]

create_clock -period 10.000 -name clk_100 [get_ports cr_ext_cr_ext_clk100_p]
set_property PACKAGE_PIN AB15 [get_ports cr_ext_cr_ext_clk100_p]
set_property PACKAGE_PIN AB16 [get_ports cr_ext_cr_ext_clk100_n]
set_property IOSTANDARD LVDS_25 [get_ports cr_ext_cr_ext_clk100_*]
#set_property DIFF_TERM_ADV TERM_100 [get_ports ext_clk100_*]

create_clock -period 5.000 -name tdc_lclk -waveform {0.000 2.500} [get_ports tdc_ext_in_lclk_p]
# create_generated_clock -period 5.000 -name tdc_lclk -source [get_clocks refclk] [get_ports ext_tdc_lclko_p]
set_property PACKAGE_PIN AD21 [get_ports tdc_ext_in_lclk_p]
set_property PACKAGE_PIN AE21 [get_ports tdc_ext_in_lclk_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_in_lclk_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports tdc_ext_in_lclk_*]


#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets Bb_top_i/clk_rst/clk_rst_mngt/inst/ibuf_clk100/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets Bob_top_i/clk_rst/clk_rst_mngt/inst/clk100_o]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets Bb_top_i/clk_rst/clk_rst_mngt/inst/clk10_o]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets Bob_top_i/clk_rst/clk_rst_mngt/inst/clk10_o]


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
set_property PACKAGE_PIN AD16 [get_ports cr_ext_cr_fastdac_syncout_p]
set_property PACKAGE_PIN AE16 [get_ports cr_ext_cr_fastdac_syncout_n]
set_property IOSTANDARD LVDS [get_ports cr_ext_cr_fastdac_syncout_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports cr_ext_cr_fastdac_syncout_*]
set_property IOB TRUE [get_ports cr_ext_cr_fastdac_syncout_*]

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
#set_property PACKAGE_PIN AD20 [get_ports ext_tdc_refclk_p]
#set_property PACKAGE_PIN AE20 [get_ports ext_tdc_refclk_n]
#set_property IOSTANDARD LVDS [get_ports ext_tdc_refclk_*]

#set_property PACKAGE_PIN AF18 [get_ports ext_tdc_rstidxp_p]
#set_property PACKAGE_PIN AF19 [get_ports ext_tdc_rstidxp_n]
#set_property IOSTANDARD LVDS [get_ports ext_tdc_rstidxp_*]

#set_property PACKAGE_PIN AB21 [get_ports ext_tdc_lclki_p]
#set_property PACKAGE_PIN AC21 [get_ports ext_tdc_lclki_n]
#set_property IOSTANDARD LVDS [get_ports ext_tdc_lclki_*]

set_property PACKAGE_PIN AD20 [get_ports tdc_ext_clkrst_tdc_refclk_p]
set_property PACKAGE_PIN AE20 [get_ports tdc_ext_clkrst_tdc_refclk_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_clkrst_tdc_refclk_*]

set_property PACKAGE_PIN AF18 [get_ports tdc_ext_clkrst_tdc_rstidxp_p]
set_property PACKAGE_PIN AF19 [get_ports tdc_ext_clkrst_tdc_rstidxp_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_clkrst_tdc_rstidxp_*]

set_property PACKAGE_PIN AB21 [get_ports tdc_ext_clkrst_tdc_lclki_p]
set_property PACKAGE_PIN AC21 [get_ports tdc_ext_clkrst_tdc_lclki_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_clkrst_tdc_lclki_*]

set_property PACKAGE_PIN H13 [get_ports linterrupt_i]

#TDC INPUT
set_property PACKAGE_PIN AB25 [get_ports tdc_ext_in_sdia_p]
set_property PACKAGE_PIN AB26 [get_ports tdc_ext_in_sdia_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_in_sdia_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports tdc_ext_in_sdia_*]

set_property PACKAGE_PIN AD23 [get_ports tdc_ext_in_framea_p]
set_property PACKAGE_PIN AE23 [get_ports tdc_ext_in_framea_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_in_framea_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports tdc_ext_in_framea_*]

set_property PACKAGE_PIN AC26 [get_ports tdc_ext_in_sdib_p]
set_property PACKAGE_PIN AD26 [get_ports tdc_ext_in_sdib_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_in_sdib_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports tdc_ext_in_sdib_*]

set_property PACKAGE_PIN AE25 [get_ports tdc_ext_in_frameb_p]
set_property PACKAGE_PIN AE26 [get_ports tdc_ext_in_frameb_n]
set_property IOSTANDARD LVDS [get_ports tdc_ext_in_frameb_*]
set_property DIFF_TERM_ADV TERM_100 [get_ports tdc_ext_in_frameb_*]


##Bank 84



##Bank 86,87
set_property PACKAGE_PIN K9 [get_ports ext_sync_ltc]
set_property PACKAGE_PIN F14 [get_ports ext_pps]
set_property IOSTANDARD LVCMOS33 [get_ports ext_pps]


##SPI buses
set_property PACKAGE_PIN G11 [get_ports com_ext_spi_tdc_miso_io]
set_property PACKAGE_PIN H11 [get_ports com_ext_spi_tdc_mosi_io]
set_property PACKAGE_PIN D10 [get_ports com_ext_spi_tdc_sck_io]
set_property PACKAGE_PIN C9 [get_ports {com_ext_spi_tdc_ss_io[0]}]
set_property PACKAGE_PIN K10 [get_ports {com_ext_spi_tdc_ss_io[1]}]
set_property PACKAGE_PIN J15 [get_ports rst_jic]


set_property PACKAGE_PIN C11 [get_ports com_ext_spi_dl_miso_io]
set_property PACKAGE_PIN B11 [get_ports com_ext_spi_dl_mosi_io]
set_property PACKAGE_PIN D11 [get_ports com_ext_spi_dl_sck_io]
set_property PACKAGE_PIN D9 [get_ports {com_ext_spi_dl_ss_io[0]}]
set_property PACKAGE_PIN J9 [get_ports {com_ext_spi_dl_ss_io[1]}]
set_property PACKAGE_PIN H9 [get_ports {com_ext_spi_dl_ss_io[2]}]

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


###RENAME THE GENERATED CLOCKS
set wiz_clkout1 [get_clocks -of_objects [get_pins Bob_top_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]]
set wiz_clkout2 [get_clocks -of_objects [get_pins Bob_top_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT1]]
# set mmcm_ddr_clkout [get_clocks -of_objects [get_pins Bob_top_i/ddr4/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT1]]
set mmcm_clkout1 [get_clocks -of_objects [get_pins Bob_top_i/ddr4/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT1]]
set xdma_axi_aclk [get_clocks -of_objects [get_pins Bob_top_i/xdma_0/inst/pcie4_ip_i/inst/Bob_top_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_coreclk/O]]

##Set clock groups----------------------------------------------
set_clock_groups -asynchronous -group [get_clocks tdc_lclk] -group [get_clocks refclk] 
set_clock_groups -asynchronous -group [get_clocks refclk] -group [get_clocks sysrefclk]
set_clock_groups -asynchronous -group [get_clocks mmcm_clkout1] -group [get_clocks refclk]

###SET CONSTRAINTS CLK_RST_MNGT
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg2_reg[0]/C}] -to [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/gc_rst_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg0_reg[1]/C}] -to [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_fastdac_rst_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg4_reg[0]/C}] -to [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/ddr_data_rst_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[1]/C}] -to [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/lrst_i_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[0]/C}] -to [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/tdc_rst_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg3_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_rst240_r_reg[0]/D}] 
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg3_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_rst80_r_reg[0]/D}]
# set_false_path -from $mmcm_ddr_clkout -to [get_clocks clk_10]
set_false_path -from [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/fpga_turnkey_reg_mngt_inst/slv_reg0_reg[0]/C}] -to [get_pins {Bob_top_i/clk_rst/clk_rst_mngt/inst/clockchip_sync_r_reg[0]/D}]

### SET CONSTRAINTS DDR_DATA
# set_false_path -from [get_clocks refclk] -to $xdma_axi_aclk
set_false_path -from [get_pins {Bob_top_i/ddr4/mon_ddr_fifos_0/inst/mon_trigger_200_reg/C}] -to [get_pins {Bob_top_i/ddr4/mon_ddr_fifos_0/inst/mon_trigger_250_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/mon_ddr_fifos_0/inst/mon_trigger_250_r_reg[2]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/status_250_valid_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/mon_ddr_fifos_0/inst/status_250_o_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg14_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/mon_ddr_fifos_0/inst/status_200_o_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg13_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/current_dq_gc_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg15_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/current_dq_gc_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg16_reg[*]/D}]
set_false_path -from [get_pins Bob_top_i/ddr4/ddr_data_0/inst/s_axis_tready_gc_200_reg/C] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/s_axis_tready_gc_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/command_enable_r_reg[2]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/current_dq_gc_valid_r_reg[0]/D}]
# set_false_path -from [get_clocks refclk] -to $mmcm_ddr_clkout
# set_false_path -from $xdma_axi_aclk -to $mmcm_ddr_clkout
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg3_reg[0]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/reg_enable_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg0_reg[0]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/start_write_ddr_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg1_reg[0]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/command_enable_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg2_reg[3]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/command_gc_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg2_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/command_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg6_reg[0]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/command_alpha_enable_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg6_reg[1]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/pair_delay_r_reg/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg7_reg[0]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/command_gc_enable_r_reg[0]/D}]

set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg4_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/dq_gc_start_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg5_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/dq_gc_start_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg8_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/threshold_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg9_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/threshold_full_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ddr4/ddr_data_reg_mngt_0/inst/ddr_data_axil_mngt_inst/slv_reg10_reg[*]/C}] -to [get_pins {Bob_top_i/ddr4/ddr_data_0/inst/fiber_delay_r_reg[*]/D}]
###SET CONSTRAINTS TDC
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg0_reg[0]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/enable_axi_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[0]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/reg_enable_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[1]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/reg_enable200_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg1_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/index_stop_bitwise_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg4_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/gate0_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg5_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/gate1_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg6_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/shift_tdc_time_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg7_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/shift_gc_back_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg8_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/command_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg10_reg[0]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/command_enable_r_reg[0]/*/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg2_reg[0]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/start_gc_r_reg[0]/D}]


set_false_path -from [get_pins Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/data_count_valid_o_reg/C] -to [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/data_count_valid_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/click0_count_o_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg15_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/click1_count_o_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg14_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/total_count_o_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg16_reg[*]/D}]

set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg3_reg[*]/C}] -to [get_pins {Bob_top_i/tdc/clk_rst_buffer/tdc_clk_rst_mngt_0/inst/stopa_sim_limit_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[2]/C}] -to [get_pins {Bob_top_i/tdc/clk_rst_buffer/tdc_clk_rst_mngt_0/inst/sim_enable_r_reg[*]/D}]

#set_false_path -from [get_cells Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[0]] -to [get_cells Bob_top_i/tdc/AS6501_IF_0/inst/reg_enable_r_reg[0]]
#set_false_path -from [get_cells Bob_top_i/tdc/tdc_mngt/TDC_REG_MNGT_v1_0_0/inst/TDC_REG_MNGT_v1_0_s_axil_inst/slv_reg9_reg[1]] -to [get_cells Bob_top_i/tdc/AS6501_IF_0/inst/reg_enable200_r_reg[0]]
#set_multicycle_path -setup 2 -from [get_clocks refclk] -to [get_pins Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/s_axis_tdata_reg[*]/CE]
#set_multicycle_path -hold 1 -from [get_clocks refclk] -to [get_pins Bob_top_i/tdc/tdc_mngt/AS6501_IF_0/inst/s_axis_tdata_reg[*]/CE]

###SET CONSTRAINTS FASTDAC
## JESD204B_TX_WRAPPER
set_false_path -through [get_pins Bob_top_i/fastdac/jesd204b_tx_wrapper_0/inst/tx_core_reset] -to [get_pins Bob_top_i/fastdac/jesd204b_tx_wrapper_0/inst/vtx_reset_gt_r_*/PRE]
set _shared_i0 [get_cells Bob_top_i/fastdac/jesd204b_tx_wrapper_0/inst/jesd204b_reg_mngt/slv_reg*_*]
set_false_path -from $_shared_i0 -to [get_clocks refclk]
set_false_path -from [get_clocks refclk] -to $_shared_i0 

## JESD_TRANSPORT
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg1_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/up_offset_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg1_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/shift1_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg2_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_amp_dac1_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg3_reg[0]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/reg_en_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg4_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_dpram_max_addr_seq_dac0_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg4_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_dpram_max_addr_seq_dac1_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg5_reg[0]/C}] -to [get_pins Bob_top_i/fastdac/jesd_transport_0/inst/rng_mode_r_reg/D]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg5_reg[1]/C}] -to [get_pins Bob_top_i/fastdac/jesd_transport_0/inst/dac1_mode_r_reg/D]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg5_reg[2]/C}] -to [get_pins Bob_top_i/fastdac/jesd_transport_0/inst/fb_mode_r_reg/D]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg5_reg[3]/C}] -to [get_pins Bob_top_i/fastdac/jesd_transport_0/inst/insert_zero_mode_r_reg/D]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg5_reg[4]/C}] -to [get_pins Bob_top_i/fastdac/jesd_transport_0/inst/dac0_mode_r_reg/D]

set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg6_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_amp_dac2_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg7_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_dpram_max_addr_rng_dac1_r_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/fastdac_axil_mngt_inst/slv_reg8_reg[*]/C}] -to [get_pins {Bob_top_i/fastdac/jesd_transport_0/inst/division_sp_r_reg[*]/D}]
###SET CONSTRAINTS TTL
## 1-bit CDC
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg2_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_params_240_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg2_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_params_80_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg0_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_trigger_enstep_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg4_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_trigger_enstep_slv1_r_reg[0]/D}]
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg5_reg[0]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_trigger_enstep_slv2_r_reg[0]/D}]

## multi-bit CDC
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[*]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_params_240_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg1_reg[*]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_params_80_reg[*]/D}]
set_false_path -from [get_pins {Bob_top_i/ttl_gate_apd_0/inst/fpga_turnkey_reg_mngt_inst/slv_reg3_reg[*]/C}] -to [get_pins {Bob_top_i/ttl_gate_apd_0/inst/ttl_params_slv_reg[*]/D}]

## CONSTRAINING FOR FPGA FLASH CONFIGURATION
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]