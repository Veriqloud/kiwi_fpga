// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module fifo_alpha_out (
  m_aclk,
  s_aclk,
  s_aresetn,
  s_axis_tvalid,
  s_axis_tready,
  s_axis_tdata,
  s_axis_tuser,
  m_axis_tvalid,
  m_axis_tready,
  m_axis_tdata,
  m_axis_tuser,
  axis_prog_full,
  axis_prog_empty
);

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 master_aclk CLK" *)
  (* X_INTERFACE_MODE = "slave master_aclk" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME master_aclk, ASSOCIATED_BUSIF M_AXIS:M_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN , ASSOCIATED_PORT , ASSOCIATED_RESET , INSERT_VIP 0" *)
  input m_aclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 slave_aclk CLK" *)
  (* X_INTERFACE_MODE = "slave slave_aclk" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME slave_aclk, ASSOCIATED_BUSIF S_AXIS:S_AXI, ASSOCIATED_RESET s_aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN , ASSOCIATED_PORT , INSERT_VIP 0" *)
  input s_aclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 slave_aresetn RST" *)
  (* X_INTERFACE_MODE = "slave slave_aresetn" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME slave_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
  input s_aresetn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
  (* X_INTERFACE_MODE = "slave S_AXIS" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXIS, TDATA_NUM_BYTES 16, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 4, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, CLK_DOMAIN , LAYERED_METADATA undef, INSERT_VIP 0" *)
  input s_axis_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
  output s_axis_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
  input [127:0]s_axis_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TUSER" *)
  input [3:0]s_axis_tuser;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
  (* X_INTERFACE_MODE = "master M_AXIS" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS, TDATA_NUM_BYTES 16, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 4, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, CLK_DOMAIN , LAYERED_METADATA undef, INSERT_VIP 0" *)
  output m_axis_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
  input m_axis_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
  output [127:0]m_axis_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TUSER" *)
  output [3:0]m_axis_tuser;
  (* X_INTERFACE_IGNORE = "true" *)
  output axis_prog_full;
  (* X_INTERFACE_IGNORE = "true" *)
  output axis_prog_empty;

  // stub module has no contents

endmodule
