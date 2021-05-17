`include "cpuhead.svh"

module Memory(
	input content_t cont,
	output content_t out_cont,
	
	output dbus_req_t dreq,
    input  dbus_resp_t dresp
);

	logic to_mem, valid;

	assign to_mem = (cont.mem_control.write_en | cont.mem_control.read_en) ? 1'b1 : 1'b0;
	assign valid = to_mem & (cont.mem_control.read_en ? ~dresp.data_ok : 1);

	msize_t msize;
	strobe_t strobe;
	word_t req_data, resp_data/* verilator lint_off UNOPTFLAT */, data;
	i2 addr;

	parameter i24 bits_24 = 24'b111111_111111_111111_111111;
	parameter i16 bits_16 = 16'b1111_1111_1111_1111;

	assign data = dresp.data;
	assign addr = out_cont.val.valE[1:0];

	always_comb begin
		strobe = '0;
		msize = MSIZE4;
		req_data = out_cont.val.valB;
		resp_data = '0;

		if(cont.mem_control.read_en) begin	
			unique case (cont.instr.opcode)
				OP_LW : begin 
					msize = MSIZE4;
					resp_data = dresp.data;
				end
				OP_LH : begin
					msize = MSIZE2; 
					resp_data = (addr == 2'b00) ? ((data[15]==1'b0) ? ({16'b0, data[15:0]}) : ({bits_16, data[15:0]})) 
												: ((data[31]==1'b0) ? ({16'b0, data[31:16]}) : ({bits_16, data[31:16]}));
					//resp_data = (addr == 2'b00) ? data : `SIGN_EXTEND(data[31:16], 32);
				end 
				OP_LHU : begin
					msize = MSIZE2; 
					//resp_data = (addr == 2'b00) ? dresp.data : `ZERO_EXTEND(dresp.data[31:16], 32);
					resp_data = (addr == 2'b00) ? `ZERO_EXTEND(dresp.data[15:0], 32) : `ZERO_EXTEND(dresp.data[31:16], 32);
				end
				OP_LB : begin
					msize = MSIZE1;
					unique case (addr)
						2'b00 : resp_data = (data[7]==1'b0) ? ({24'b0, data[7:0]}) : ({bits_24, data[7:0]});
						//2'b01 : resp_data =`SIGN_EXTEND(dresp.data[15:8], 32);
						2'b01 : resp_data = (data[15]==1'b0) ? ({24'b0, data[15:8]}) : ({bits_24, data[15:8]});
						//2'b10 : resp_data =`SIGN_EXTEND(dresp.data[23:16], 32);
						2'b10 : resp_data = (data[23]==1'b0) ? ({24'b0, data[23:16]}) : ({bits_24, data[23:16]});
						//2'b11 : resp_data =`SIGN_EXTEND(dresp.data[31:24], 32);
						2'b11 : resp_data = (data[31]==1'b0) ? ({24'b0, data[31:24]}) : ({bits_24, data[31:24]});
					endcase 
				end 
				OP_LBU : begin
					msize = MSIZE1;
					unique case (addr)
						2'b00 : resp_data =`ZERO_EXTEND(dresp.data[7:0], 32);
						2'b01 : resp_data =`ZERO_EXTEND(dresp.data[15:8], 32);
						2'b10 : resp_data =`ZERO_EXTEND(dresp.data[23:16], 32);
						2'b11 : resp_data =`ZERO_EXTEND(dresp.data[31:24], 32);
					endcase 
				end
				default : begin
				end
			endcase
		end	
		else if(cont.mem_control.write_en) begin
			unique case (cont.instr.opcode)
				OP_SW :  begin
					strobe = 4'b1111;
					req_data = out_cont.val.valB;
					msize = MSIZE4;
				end
				OP_SH : begin
					strobe = (addr == 2'b00) ? 4'b0011 : 4'b1100;
					//req_data = (addr == 2'b00) ? {out_cont.val.valB[31:16]} : {out_cont.val.valB[15:0], 16'b0};
					//req_data = (addr == 2'b00) ? {16'b0, out_cont.val.valB[31:16]} : {out_cont.val.valB[15:0], 16'b0};
					req_data = (addr == 2'b00) ? {16'b0, out_cont.val.valB[15:0]} : {out_cont.val.valB[15:0], 16'b0};
					msize = MSIZE2;
				end
				OP_SB : begin
					msize = MSIZE1;
					unique case (addr)
						2'b00 : begin
							strobe = 4'b0001;
							req_data = {24'b0, out_cont.val.valB[7:0]};
						end
						2'b01 : begin
							strobe = 4'b0010;
							req_data = {16'b0, out_cont.val.valB[7:0], 8'b0};
						end
						2'b10 : begin
							strobe = 4'b0100;
							req_data = {8'b0, out_cont.val.valB[7:0], 16'b0};
						end
						2'b11 : begin
							strobe = 4'b1000;
							req_data = {out_cont.val.valB[7:0], 24'b0};
						end
					endcase
				end
				default : begin end
			endcase
		end
	end

	//dreq
	assign dreq = valid ? '{valid, out_cont.val.valE, msize, strobe, req_data} : '0;

	//out_cont
	always_comb begin
		out_cont = cont;
        if (cont.mem_control.read_en == 1) begin
            out_cont.val.valM = dresp.data_ok ? resp_data : 32'b0;
        end
	end
	
	wire _unused_ok = &{1'b0,
						dresp[33],
						1'b0};    


endmodule