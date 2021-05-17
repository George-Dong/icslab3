`include "cpuhead.svh"

module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    output dbus_req_t  dreq,
    input  ibus_resp_t iresp,
    input  dbus_resp_t dresp
);
        
    /*Part 1 pipeline registers*/
    content_t d_reg, e_reg, m_reg, w_reg, debug_reg;
    content_t f_out, d_out, e_out, m_out, w_out;
    content_t d_reg_in, e_reg_in, m_reg_in, w_reg_in, debug_reg_in;

	content_t reset_context, E_cont, M_cont, reset_context1;
	
    assign E_cont = e_out;
    assign M_cont = m_out;


	/*Part 2 pipeline stage varibles*/
	logic write_enable, hazzard;
    logic hi_write, lo_write;
	regidx_t ra1, ra2, wa3;
	word_t rd1, rd2, wd3, hi, lo;
    word_t hi_data, lo_data;
	addr_t nxt_pc, cur_pc;
    
    assign cur_pc = d_reg.pc;
    assign hi_write = E_cont.hilo_reg_control.hi_write;
    assign lo_write = E_cont.hilo_reg_control.lo_write;
    assign hi_data = E_cont.val.hi_data;
    assign lo_data = E_cont.val.lo_data;

    /*Part 3 special cases dealing*/

    always_comb begin
         reset_context = '0;
         reset_context.pc = 32'hbfc00000;
         reset_context1 = '0;
         reset_context1.pc = 32'hbfbffffc;

            d_reg_in = f_out;
            e_reg_in = d_out;
            m_reg_in = e_out;
            w_reg_in = m_out;
            debug_reg_in = w_out;

        if(~x_Memory.dresp.data_ok & x_Memory.to_mem) begin
            //F depends on E
            d_reg_in = d_out;
            e_reg_in = e_out;
            m_reg_in = m_out;
            w_reg_in = reset_context;
            debug_reg_in = w_out;
        end else if (~x_Fetch.iresp.data_ok) begin
            //F do not need to consider
            d_reg_in = d_out;
            e_reg_in = e_out;
            m_reg_in = reset_context;
            w_reg_in = m_out;
            debug_reg_in = w_out;
        end else if(hazzard) begin
            d_reg_in = hazzard ? d_out : f_out;
            e_reg_in = hazzard ? reset_context : d_out;
            m_reg_in = e_out;
            w_reg_in = m_out;
            debug_reg_in = w_out;
        end else begin

        end
    end


    /*Part 4 module instance*/
    Fetch x_Fetch           (.out_cont(f_out), .*); 
	Decode x_Decode         (.cont(d_reg), .out_cont(d_out), .*);
	Execute x_Execute       (.cont(e_reg), .out_cont(e_out), .*);
	Memory x_Memory         (.cont(m_reg), .out_cont(m_out), .*);
    Writeback x_Writeback   (.cont(w_reg), .out_cont(w_out), .*);
    Regfile x_Regfile(.*);
    Hi_Lo_Reg x_Hi_Lo_Reg(.*);


    /*Part 5 stage impl*/
    always_ff @(posedge clk) begin
        if (resetn) begin
            d_reg <= d_reg_in; 
            e_reg <= e_reg_in;
            m_reg <= m_reg_in; 
            w_reg <= w_reg_in;
            debug_reg <= debug_reg_in;
        end else begin
            d_reg <= reset_context1;
            e_reg <= reset_context1;
            m_reg <= reset_context;
            w_reg <= reset_context;
            debug_reg <= reset_context;
        end
     end


    /*Part 6 debug signals*/
    `define verilator_OP_LOAD debug_reg.instr.opcode == OP_LW \
            ||  debug_reg.instr.opcode == OP_LH \
            ||  debug_reg.instr.opcode == OP_LHU\
            ||  debug_reg.instr.opcode == OP_LB \
            ||  debug_reg.instr.opcode == OP_LBU


    addr_t   debug_wb_pc /* verilator public_flat_rd */;
    strobe_t debug_wb_rf_wen /* verilator public_flat_rd */;
    regidx_t debug_wb_rf_wnum /* verilator public_flat_rd */;
    word_t   debug_wb_rf_wdata /* verilator public_flat_rd */;

    assign debug_wb_pc        = debug_reg.pc;
    assign debug_wb_rf_wen   = debug_reg.reg_control.write_en ? 4'b1111 : 4'b0000;
    assign debug_wb_rf_wnum  = debug_reg.reg_control.target_id;
    assign debug_wb_rf_wdata = `verilator_OP_LOAD ? debug_reg.val.valM : debug_reg.val.valE;
    


	wire _unused_ok = &{1'b0,
                        debug_reg,
                        1'b0};    

    
endmodule
