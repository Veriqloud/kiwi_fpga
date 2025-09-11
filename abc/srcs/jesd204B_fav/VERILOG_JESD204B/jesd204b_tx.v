`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Veriqloud`
// Engineer: Fabrice Faveneau
// 
// Create Date: 26.09.2023 17:05:09
// Design Name: Qline_turnkey
// Module Name: jesd204b_tx
// Project Name: kiwiKD
// Target Devices: Opalkelly XEM8310
// Tool Versions: Vivado 2024.2
// Description: Manage link layer of jesd204b protocol
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define_jesd204b.v"

module jesd204b_tx
    #(
        parameter integer p_L  = 4       // number of physical lanes
    )
    (
        input wire                  tx_core_clk,
        input wire                  tx_core_reset,
        
        input wire                  btx_sync_i,
        input wire                  btx_sysref_i,
        // Control parameters
        input wire                  btx_enable_i,
        input wire                  btx_reset_done_i,
        input wire                  bsysref_always_i,
        input wire                  bsysref_required_i,
        // Configurations parameters
        input wire [7:0]            vDID_i,
        input wire [3:0]            vBID_i,
        input wire [3:0]            vADJCNT_i,
        input wire [4:0]            vLID_i,
        input wire                  bPHADJ_i,
        input wire                  bADJDIR_i,
        input wire                  bSCR_i,
        input wire [7:0]            vF_i,
        input wire [4:0]            vK_i,
        input wire [7:0]            vM_i,
        input wire [4:0]            vN_i,
        input wire [1:0]            vCS_i,
        input wire [4:0]            vNp_i,
        input wire [1:0]            vSUBCLASSV_i,
        input wire [4:0]            vS_i,
        input wire [2:0]            vJESDV_i,
        input wire [4:0]            vCF_i,
        input wire                  bHD_i,
        // Axi-s data bus input
        input wire [p_L*32-1:0]     vtx_tdata_i,
        output wire                 btx_tready_o,
        
        // data bus output
        output reg [p_L*32-1:0]     vgt_tdata_o  = 0,
        output reg [p_L*4-1:0]      vgt_charisk_o = 0,
        //output debug
        output blmfc_r
    );

    wire [8-1:0]     vFCHK_i;
    
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    //     Assign ila parameters               //
    /////////////////////////////////////////////
    /////////////////////////////////////////////     
    wire [p_L*8*14-1:0]     v_cfg_ila_s;
    genvar L,M; 
        assign v_cfg_ila_s[1*1*8-1:1*0*8]       = vDID_i;
        assign v_cfg_ila_s[1*2*8-1:1*1*8]       = {vADJCNT_i,vBID_i};
        assign v_cfg_ila_s[1*3*8-1:1*2*8]       = {1'b0,bADJDIR_i,bPHADJ_i,vLID_i[4:0]};
        assign v_cfg_ila_s[1*4*8-1:1*3*8]       = {bSCR_i,1'b0,1'b0,(p_L-1)};
        assign v_cfg_ila_s[1*5*8-1:1*4*8]       = {vF_i};
        assign v_cfg_ila_s[1*6*8-1:1*5*8]       = {vK_i};
        assign v_cfg_ila_s[1*7*8-1:1*6*8]       = {vM_i};
        assign v_cfg_ila_s[1*8*8-1:1*7*8]       = {vCS_i,1'b0,vN_i};
        assign v_cfg_ila_s[1*9*8-1:1*8*8]       = {vSUBCLASSV_i,vNp_i};
        assign v_cfg_ila_s[1*10*8-1:1*9*8]      = {vJESDV_i,vS_i};
        assign v_cfg_ila_s[1*11*8-1:1*10*8]     = {bHD_i,1'b0,1'b0,vCF_i};
        assign v_cfg_ila_s[1*12*8-1:1*11*8]     = 8'h00;
        assign v_cfg_ila_s[1*13*8-1:1*12*8]     = 8'h00;
        assign v_cfg_ila_s[1*14*8-1:1*13*8]     = vFCHK_i[7:0];
        assign vFCHK_i[1*8-1:0*8]   = (p_L-1) + vDID_i + vBID_i + vLID_i[4:0] + bSCR_i + vF_i + vK_i + vM_i + vN_i + vCS_i + vNp_i + vSUBCLASSV_i + vS_i + vJESDV_i + vCF_i + bHD_i;
        if (p_L > 1) begin
            for (L = 1; L < p_L; L = L+1) begin
                for (M = 0; M < 14; M = M+1) begin
                    if (M == 2)
                        assign v_cfg_ila_s[((L)*8*14) + (M+1)*8-1:((L)*8*14)+M*8]  = {1'b0,bADJDIR_i,bPHADJ_i,(vLID_i[4:0] + L)};
                    else
                        if (M == 13)
                            assign v_cfg_ila_s[((L)*8*14) + (M+1)*8-1:((L)*8*14)+M*8]  = vFCHK_i[7:0] + L;
                        else
                            assign v_cfg_ila_s[((L)*8*14) + (M+1)*8-1:((L)*8*14)+M*8]  = v_cfg_ila_s[1*(M+1)*8-1:1*(M)*8]; 
                end 
            end        
        end
    
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    //     Main & ila  state machine           //
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    localparam IDLE = 0, WAIT_FOR_CGS = 1, TX_ILA = 2, TX_DATA = 3;
    reg [3:0]           vtx_mode_state_r;
    localparam  ILA_IDLE = 0,MULTIFRAME_STARTKCHAR = 1, MULTIFRAME_INDEX = 2, MULTIFRAME_ENDKCHAR = 3, 
                SECOND_MULTIFRAME_STARTKCHAR = 4, SECOND_MULTIFRAME_STARTKCONF = 5, SECOND_MULTIFRAME_CONF = 6, END_DATA = 7,
                END_ILA1 = 8, END_ILA2 = 9;
    reg [3:0]           vtx_ila_state_r;
    reg [2:0]           vcpt_multiframe;
    reg [7:0]           vcpt_frame;
    reg [3:0]           vcpt_conf;
    reg [31:0]          vila_counter;
    reg [31:0]          vila_counter_r;
    reg                 blmfc_r;
    reg [2:0]           v4overF;
    (* ASYNC_REG = "TRUE" *) reg [2:0]           vtx_enable_r =0;
    (* ASYNC_REG = "TRUE" *) reg [2:0]           vtx_reset_done_r =0; 
 
    always@(posedge tx_core_clk)
    begin
        vtx_enable_r        <= {vtx_enable_r[1:0],btx_enable_i};
        vtx_reset_done_r    <= {vtx_reset_done_r[1:0],btx_reset_done_i};
    end
    
    always@(posedge tx_core_clk, posedge tx_core_reset)
    begin   
        if (tx_core_reset)
        begin
            vtx_mode_state_r    <= IDLE;
            vtx_ila_state_r     <= ILA_IDLE; 
            vcpt_frame          <= 0;
            vcpt_multiframe     <= 0;
            vcpt_conf           <= 0;
            vila_counter[7:0]   <= 0;
            
        end else begin
            if (vtx_enable_r[2] == 1'b0 || vtx_reset_done_r[2] == 1'b0) begin
                vtx_mode_state_r    <= IDLE;
                vtx_ila_state_r     <= ILA_IDLE;
                vcpt_frame          <= 0;
                vcpt_multiframe     <= 0;
                vcpt_conf           <= 0;
                vila_counter[7:0]   <= 0;
            end else if (btx_sync_i == 1'b0) begin
                vtx_mode_state_r    <= WAIT_FOR_CGS;
                vtx_ila_state_r     <= ILA_IDLE;
                vcpt_frame          <= 0;
                vcpt_multiframe     <= 0;
                vcpt_conf           <= 0;
                vila_counter[7:0]   <= 0;
            end else    
                case (vtx_mode_state_r)
                    IDLE:    
                            vtx_mode_state_r     <= WAIT_FOR_CGS;
                            
                    WAIT_FOR_CGS:    
                            if (btx_sync_i == 1'b1 && blmfc_r == 1'b1)
                                vtx_mode_state_r     <= TX_ILA;
                    TX_ILA:    
                            begin
                                vila_counter[7:0]  <= vila_counter[7:0] + 4;

                                // Frame counter
                                if (vcpt_frame == (vK_i+1-v4overF))
                                    vcpt_frame                      <= 0;
                                else
                                    vcpt_frame                      <= vcpt_frame + v4overF;
                                // ILA frames           
                                case (vtx_ila_state_r)
                                    ILA_IDLE :
                                        vtx_ila_state_r             <= MULTIFRAME_STARTKCHAR;
                                    MULTIFRAME_STARTKCHAR :
                                        vtx_ila_state_r             <= MULTIFRAME_INDEX;
                                    MULTIFRAME_INDEX : begin
                                        if (vcpt_frame == (vK_i+1-v4overF))
                                            vtx_ila_state_r         <= MULTIFRAME_ENDKCHAR;
                                    end        
                                    MULTIFRAME_ENDKCHAR : begin
                                        vcpt_multiframe             <= vcpt_multiframe + 1;
                                        
                                        if (vcpt_multiframe == 3) 
                                                vtx_ila_state_r     <= END_ILA1;  
                                        else 
                                            if (vcpt_multiframe == 0) 
                                                vtx_ila_state_r     <= SECOND_MULTIFRAME_STARTKCHAR;
                                            else
                                                vtx_ila_state_r     <= MULTIFRAME_STARTKCHAR;
                                            
                                    end
                                    SECOND_MULTIFRAME_STARTKCHAR : begin
                                        vtx_ila_state_r             <= SECOND_MULTIFRAME_CONF;
                                        vcpt_conf                   <= vcpt_conf+2;
                                     end
                                    SECOND_MULTIFRAME_STARTKCONF :
                                        vtx_ila_state_r             <= SECOND_MULTIFRAME_CONF;
                                    SECOND_MULTIFRAME_CONF : begin
                                        vcpt_conf                   <= vcpt_conf+4;
                                        if (vcpt_conf == 14-4)
                                            vtx_ila_state_r         <= MULTIFRAME_INDEX;
                                    end
                                    END_ILA1 : begin
                                        vtx_mode_state_r            <= TX_DATA;
                                        vtx_ila_state_r             <= END_ILA1;
                                    end
                             endcase
                         end
                TX_DATA : ;
            endcase
        end                   
    end
    // Alinment counter
    reg [13:0]          vPosition_v;
    reg [1:0]           vPosition_r;
    reg [1:0]           vPosition_2r;

    always  @(*)
    begin
        vila_counter[15:8]      <= vila_counter[7:0] + 1;
        vila_counter[23:16]     <= vila_counter[7:0] + 2;
        vila_counter[31:24]     <= vila_counter[7:0] + 3;
        vPosition_v             = ((vK_i+1)*(vF_i[2:0]+1)*vcpt_multiframe);
        vPosition_r             <= vPosition_v[1:0];
        case(vF_i)
            1 : v4overF         <= 2;
            3 : v4overF         <= 1;
            default :  v4overF  <= 4;
        endcase
    end
    
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    //              Delay signals              //
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    reg [p_L*32-1:0]    vtx_tdata_r;
    reg [7:0]           vtx_sysref_cpt_r;
    always@(posedge tx_core_clk)
    begin
        vila_counter_r      <= vila_counter;
        vPosition_2r        <= vPosition_r;
        vtx_tdata_r         <= vtx_tdata_i;
    end    
    
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    //     Main outputs state machine          //
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    reg [p_L*32-1:0]    vila_data_r;
    reg [p_L*4-1:0]     vila_charisk;
    reg [p_L*32-1:0]    vdata_before_replaced_r = 0;
    reg [p_L*4-1:0]     vdata_charisk_r = 0;
    assign btx_tready_o = vtx_mode_state_r==TX_DATA?1'b1:1'b0;
    genvar I;
    generate
        for (I= 0; I < p_L; I = I+1) begin
        // Output depends only on the state
        always@(posedge tx_core_clk)
        begin          
            case (vtx_mode_state_r)
                IDLE: begin
                    vdata_before_replaced_r[32*I+:32]       <= 0;
                    vdata_charisk_r[4*I+:4]                 <= 0;
                end
                WAIT_FOR_CGS: begin
                    vdata_before_replaced_r[32*I+:32]       <= {`c_SYNC,`c_SYNC,`c_SYNC,`c_SYNC};
                    vdata_charisk_r[4*I+:4]                 <= 4'hF;
                end 
                TX_ILA:  begin
                    vdata_before_replaced_r[32*I+:32]       <= vila_data_r[32*I+:32];
                    vdata_charisk_r[4*I+:4]                 <= vila_charisk[4*I+:4];
                end
                TX_DATA: begin
                    vdata_before_replaced_r[32*I+:32]       <= vtx_tdata_i[32*I+:32];
                    vdata_charisk_r[4*I+:4]                 <= 0;
                end
                default: begin
                    vdata_before_replaced_r[32*I+:32]       <= 0;
                    vdata_charisk_r[4*I+:4]                 <= 0; 
                end                        
            endcase
        end 
        end
    endgenerate 

    /////////////////////////////////////////////
    /////////////////////////////////////////////
    //     Ila outputs state machine           //
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    reg [31:0]          vila_data_temp_v;
    reg [31:0]          temp_r;
    integer K;
    generate
        for (I= 0; I < p_L; I = I+1) begin
        // Output depends only on the state & is different for each lane
            always @ (posedge tx_core_clk) begin
                case (vtx_ila_state_r)
                    ILA_IDLE : begin
                        vila_data_r[32*I+:32]           <= {`c_SYNC,`c_SYNC,`c_SYNC,`c_SYNC};
                        vila_charisk[4*I+:4]            <= 4'hF;
                    end
                    MULTIFRAME_STARTKCHAR : begin
                        temp_r                          = format_vila_data(`c_K_R, 0, vPosition_2r, vila_counter_r,0);
                        vila_data_r[32*I+:32]           <= temp_r[31:0];
                        vila_charisk[4*I+:4]            <= format_vila_charisk(vPosition_2r,0);
                    end
                    MULTIFRAME_INDEX : begin
                        vila_data_r[32*I+:32]           <= vila_counter_r[31:0];
                        vila_charisk[4*I+:4]            <= 0;
                    end
                    MULTIFRAME_ENDKCHAR : begin
                        if (vPosition_2r == 0)
                            vPosition_v                 = 3;
                        else
                            vPosition_v                 = vPosition_2r-1;
                        temp_r                          =  format_vila_data(`c_K_A, 0, vPosition_v, vila_counter_r, 0);       
                        vila_data_r[32*I+:32]           <= temp_r[31:0];
                        vila_charisk[4*I+:4]            <= format_vila_charisk(vPosition_v, 0);
                    end
                    SECOND_MULTIFRAME_STARTKCHAR : begin
                        temp_r                          =  format_vila_data(`c_K_R, `c_K_Q, vPosition_2r, vila_counter_r,1);
                        vila_charisk[4*I+:4]            <= format_vila_charisk(vPosition_2r, 1);                        //vila_charisk[4*I+:4]                    <= 0;
                        vila_data_r[32*I+:32]           <= {v_cfg_ila_s[15:0],temp_r[15:0]};
                    end
                    SECOND_MULTIFRAME_STARTKCONF:  begin
                          vila_data_r[32*I+:32]         <= vila_counter_r[31:0];
                          vila_charisk[4*I+:4]          <= 0;
                    end                       
                    SECOND_MULTIFRAME_CONF : begin
                        for (K=0; K<4; K=K+1)
                            vila_data_r[32*I+K*8+:8]    <= v_cfg_ila_s[I*14*8+(vcpt_conf)*8 +K*8 +: 8];
                            vila_charisk[4*I+:4]        <= 0;
                    end
                endcase        
            end
        end
    endgenerate
    
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    //              Lmfc management            //
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    (* ASYNC_REG = "TRUE" *) reg [2:0]       vtx_sysref_r = 0;
    reg             bfirst_event_detected_int = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0]       btx_sync_r = 0;
    (* ASYNC_REG = "TRUE" *) reg [2:0]       bsysref_required_r = 0;

    always@(posedge tx_core_clk, posedge tx_core_reset)
    begin   
        if (tx_core_reset)
        begin
            blmfc_r                     <= 0;
            vtx_sysref_r                <= 0;
            vtx_sysref_cpt_r            <= 0;
            bfirst_event_detected_int   <= 0;
            bsysref_required_r          <= 0;
            btx_sync_r                  <= 0;
        end else begin
            vtx_sysref_r                <= {vtx_sysref_r[1:0],btx_sysref_i};
            bsysref_required_r          <= {bsysref_required_r[1:0],bsysref_required_i};
            btx_sync_r                  <= {btx_sync_r[0],btx_sync_i};           
            
            if (vtx_enable_r[2]) begin
                if (btx_sync_r[1] && !btx_sync_r[0] && bsysref_required_r[2])
                    // Waiting for a new sysref event
                    bfirst_event_detected_int       <= 0;
                else
                    if (!vtx_sysref_r[2] && vtx_sysref_r[1] && !bfirst_event_detected_int) begin 
                        bfirst_event_detected_int   <= 1;
                        vtx_sysref_cpt_r            <= 0;
                    end else
                        if (bfirst_event_detected_int)
                            if ((vtx_sysref_cpt_r == ((vK_i+1)-v4overF)) || (!vtx_sysref_r[2] && vtx_sysref_r[1] && bsysref_always_i)) begin
                                blmfc_r             <= 1'b1;
                                vtx_sysref_cpt_r    <= 0;
                            end else
                                vtx_sysref_cpt_r    <= vtx_sysref_cpt_r + v4overF;
                             
                if ((vtx_sysref_cpt_r == ((vK_i+1)-v4overF)))
                    blmfc_r                         <= 1'b1;
                else
                    blmfc_r                         <= 1'b0;
            
            end else begin
                bfirst_event_detected_int           <= 0;
                vtx_sysref_cpt_r                    <= 0;
                blmfc_r                             <= 1'b0;
            end
        end 
    end
    
    /////////////////////////////////////////////
    /////////////////////////////////////////////
    // Replacement process whithout scrambling //
    /////////////////////////////////////////////
    /////////////////////////////////////////////

    reg [p_L-1:0]           vprev_byte_replaced_r  = 'hF;
    reg [p_L*8-1:0]         vprev_byte_save;
    reg [p_L*32-1:0]        vtmp_dout_v;
    reg [p_L-1 : 0]         vtmp_replaced_v;
    reg [4*p_L-1:0]         vtmp_charisk_v;
    wire                    end_of_multiframe;
    reg [2:0]               vend_of_multiframe_r;
    reg                     breplaced_enable = 0;
    
    assign end_of_multiframe = vend_of_multiframe_r[2];
    
    always @ (posedge tx_core_clk) begin
        vend_of_multiframe_r    <= {vend_of_multiframe_r[1:0],blmfc_r};
        breplaced_enable        <= (vtx_mode_state_r==TX_DATA)?1'b1:1'b0;
    end

    generate
        for (I= 0; I < p_L; I = I+1) begin
        always @ (posedge tx_core_clk,posedge tx_core_reset)
        begin
            if (tx_core_reset)
            begin
                vprev_byte_replaced_r[I]                    <= 1;
                vgt_tdata_o[32*(I+1)-1 : 32*I]              <= 0;
                vgt_charisk_o[4*(I+1)-1 : 4*I]              <= 0;
            end else begin
            
                vtmp_dout_v[32*(I+1)-1 : 32*I]              = vdata_before_replaced_r[32*(I+1)-1 : 32*I];
                vtmp_replaced_v[I]                          = vprev_byte_replaced_r[I];
                vtmp_charisk_v[4*(I+1)-1 : 4*I]             = vdata_charisk_r[4*(I+1)-1 : 4*I];
                
                // check octets at end of frame
                if (vdata_before_replaced_r[(I*32 + (1*8)-1):(I*32 + (1-1)*8)] == vprev_byte_save[8*(I+1)-1 : 8*I]) 
                    if ((1 == v4overF) && end_of_multiframe) begin
                        vtmp_dout_v[(I*32 + (1*8)-1):I*32 + (0*8)]                  = `c_K_A;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 0]                                     = 1;
                    end else if (!vtmp_replaced_v[I]) begin
                        vtmp_dout_v[(I*32 + (1*8)-1):I*32 + (0*8)]                  = `c_K_F;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 0]                                     = 1;
                    end else
                        vtmp_replaced_v[I]                                          = 0;
                 else
                        vtmp_replaced_v[I]                                          = 0;
                
                if (vdata_before_replaced_r[(I*32 + (2*8)-1):(I*32 + (2-1)*8)] == vdata_before_replaced_r[(I*32 + (1*8)-1):(I*32 + (1-1)*8)])
                    if ((2 == v4overF) && end_of_multiframe) begin
                        vtmp_dout_v[(I*32 + (2*8)-1):I*32 + (1*8)]                  = `c_K_A;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 1]                                     = 1;
                    end else if (!vtmp_replaced_v[I]) begin
                        vtmp_dout_v[(I*32 + (2*8)-1):I*32 + (1*8)]                  = `c_K_F;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 1]                                     = 1;
                    end else
                        vtmp_replaced_v[I]                                          = 0;
                else
                        vtmp_replaced_v[I]                                          = 0;
                 
                 if (vdata_before_replaced_r[(I*32 + (3*8)-1):(I*32 + (3-1)*8)] == vdata_before_replaced_r[(I*32 + (2*8)-1):(I*32 + (2-1)*8)]) 
                    if ((3 == v4overF) && end_of_multiframe) begin
                        vtmp_dout_v[(I*32 + (3*8)-1):I*32 + (2*8)]                  = `c_K_A;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 2]                                     = 1;
                    end else if (!vtmp_replaced_v[I]) begin
                        vtmp_dout_v[(I*32 + (3*8)-1):I*32 + (2*8)]                  = `c_K_F;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 2]                                     = 1;
                    end else
                        vtmp_replaced_v[I]                                          = 0;
                else
                        vtmp_replaced_v[I]                                          = 0;
                        
                if (vdata_before_replaced_r[(I*32 + (4*8)-1):(I*32 + (4-1)*8)] == vdata_before_replaced_r[(I*32 + (3*8)-1):(I*32 + (3-1)*8)]) 
                    if ((4 == v4overF) && end_of_multiframe) begin
                        vtmp_dout_v[(I*32 + (4*8)-1):I*32 + (3*8)]                  = `c_K_A;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 3]                                     = 1;
                    end else if (!vtmp_replaced_v[I]) begin
                        vtmp_dout_v[(I*32 + (4*8)-1):I*32 + (3*8)]                  = `c_K_F;
                        vtmp_replaced_v[I]                                          = 1;
                        vtmp_charisk_v[4*I + 3]                                     = 1;
                    end else
                        vtmp_replaced_v[I]                                          = 0;
               else
                        vtmp_replaced_v[I]                                          = 0;
                        
                // output registers
                if (!breplaced_enable) begin
                    vgt_tdata_o[32*(I+1)-1 : 32*I]              <= vdata_before_replaced_r[32*(I+1)-1 : 32*I];
                    vgt_charisk_o[4*(I+1)-1 : 4*I]              <= vdata_charisk_r[4*(I+1)-1 : 4*I];
                    vprev_byte_save[8*(I+1)-1 : 8*I]            <= vtx_tdata_i[(I*32 + (4*8)-1):(I*32 + (4-1)*8)];
                    vprev_byte_replaced_r[I]                    <= 1;
                end else begin
                    vgt_tdata_o[32*(I+1)-1 : 32*I]              <= vtmp_dout_v[32*(I+1)-1 : 32*I];
                    vgt_charisk_o[4*(I+1)-1 : 4*I]              <= vtmp_charisk_v[4*(I+1)-1 : 4*I];
                    vprev_byte_save[8*(I+1)-1 : 8*I]            <= vdata_before_replaced_r[(32*I+ (4*8)-1):(32*I + (4-1)*8)];
                    vprev_byte_replaced_r[I]                    <= vtmp_replaced_v[I];
                end
            end
        end
    end
endgenerate
    
     
    function [3:0]  format_vila_charisk; 
    input [2:0]     vposition_i;
    input           bdouble_en;
    reg [3:0]       vila_charik_temp_v;
    integer         iila_vila_charisk;
    begin
        for (iila_vila_charisk=0;iila_vila_charisk<4;iila_vila_charisk=iila_vila_charisk+1)
            if (iila_vila_charisk == vposition_i) 
                vila_charik_temp_v[iila_vila_charisk]       = 1'b1;
            else
                if (iila_vila_charisk == (vposition_i+1) && bdouble_en == 1'b1)
                    vila_charik_temp_v[iila_vila_charisk]   = 1'b1;
                else
                    vila_charik_temp_v[iila_vila_charisk]   = 1'b0;
        format_vila_charisk    = vila_charik_temp_v;
    end
    endfunction
    
    function [31:0] format_vila_data; 
    input [7:0]     vk_char0;
    input [7:0]     vk_char1;
    input [2:0]     vposition;
    input [31:0]    vila_counter;
    input           bdouble_en;
    reg [31:0]      vila_data_temp_v;
    integer         iila_vila_data;
    begin
        for (iila_vila_data=0;iila_vila_data<4;iila_vila_data=iila_vila_data+1)
            if (iila_vila_data == vposition) begin 
                vila_data_temp_v[iila_vila_data*8+:8]       = vk_char0;
            end else
                if (iila_vila_data == (vposition+1) && bdouble_en == 1'b1) begin
                    vila_data_temp_v[iila_vila_data*8+:8]   = vk_char1;
                end else
                    vila_data_temp_v[iila_vila_data*8+:8]   = vila_counter[iila_vila_data*8+:8];
               
        format_vila_data    = {vila_data_temp_v};
    end
    endfunction         
endmodule
