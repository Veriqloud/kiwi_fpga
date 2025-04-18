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

delete_bd_objs [get_bd_nets clk_1] [get_bd_ports clk]
delete_bd_objs [get_bd_nets ddr4/clk_1] [get_bd_pins ddr4/clk]
connect_bd_net [get_bd_pins ddr4/clk200_i] [get_bd_pins ddr4/system_ila_ddr/clk]
validate_bd_design






