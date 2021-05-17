`include "cpuhead.svh"

module Fetch (
    input  addr_t      nxt_pc,
    output content_t   out_cont,
    input logic resetn,

    output ibus_req_t ireq,
    input  ibus_resp_t iresp
);
	
    logic valid;
    assign valid = ~iresp.data_ok;

    always_comb begin
        ireq = '{valid, resetn ? nxt_pc : 32'hbfbffffc};
        out_cont = '0;
        out_cont.pc = nxt_pc;
        out_cont.instr = iresp.data_ok ? iresp.data : 32'b0;
    end

    wire _unused_ok = &{1'b0,
                        iresp[33],
                        1'b0};    

endmodule
