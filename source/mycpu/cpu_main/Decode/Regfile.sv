`include "cpuhead.svh"

module Regfile(
    input logic clk, resetn,
 
    input regidx_t ra1, ra2, wa3,
    input word_t wd3,
    output word_t rd1, rd2,
    
    input logic write_enable
);
    word_t [31:1] regs, regs_nxt;

    always_ff @(posedge clk) begin
		if (resetn) begin
			regs[31:1] <= regs_nxt[31:1]; 
		end else begin
			regs[31:1] <= '0;
		end
    end
    for (genvar i = 1; i <= 31; i ++) begin
        always_comb begin
            regs_nxt[i[4:0]] = regs[i[4:0]];
            if (wa3 == i[4:0] && write_enable) begin
                regs_nxt[i[4:0]] = wd3;
            end
        end
    end


    assign rd1 = (ra1 == 5'b0) ? '0 : regs_nxt[ra1]; 
    assign rd2 = (ra2 == 5'b0) ? '0 : regs_nxt[ra2]; 

endmodule