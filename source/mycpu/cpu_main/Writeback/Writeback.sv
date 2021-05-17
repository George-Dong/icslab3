`include "cpuhead.svh"

module Writeback(
	input  content_t   cont,
	output content_t   out_cont,

	output regidx_t    wa3,
	output word_t      wd3,
	output logic       write_enable

);
	
	always_comb begin
		write_enable = 0;
		wa3 = '0;
		wd3 = '0;

		if (cont.reg_control.write_en) begin 
			write_enable = 1;
			wa3 = cont.reg_control.target_id;
			wd3 = cont.mem_control.read_en ? cont.val.valM : cont.val.valE;
		end
	end
	
	assign out_cont = cont;

endmodule
