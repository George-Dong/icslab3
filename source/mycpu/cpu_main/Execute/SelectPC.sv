`include "cpuhead.svh"

module SelectPC (
	input content_t  cont,
	input addr_t     cur_pc,
	output addr_t    nxt_pc
);

	logic[17:0] offset;
    assign offset = {cont.val.valC[15:0], 2'b0};
	
	addr_t pcplus4, pcplus8, pcbranch, pcjump;
    assign pcplus4 = cur_pc + 4;
    assign pcplus8 = cont.pc + 8;
    assign pcbranch = cont.pc + 4 + `SIGN_EXTEND(offset, 32);
    assign pcjump[31:28] = cont.pc[31:28]; 
	assign pcjump[27:0] = {cont.val.valA[25:0], 2'b00};

	always_comb begin
		
		unique case(cont.instr.opcode)
		
		OP_BEQ: begin
			nxt_pc = cont.val.valA == cont.val.valB ? pcbranch : pcplus8;
		end
		
		OP_BNE: begin
			nxt_pc = cont.val.valA != cont.val.valB ? pcbranch : pcplus8;
		end
		
		OP_BGTZ: begin
			nxt_pc = $signed(0) < $signed(cont.val.valA) ? pcbranch : pcplus8;
			//nxt_pc = `SIGNED_CMP(0, cont.val.valA) ? pcbranch : pcplus8;
		end//TODO:check the cmp logic

		OP_BLEZ: begin
			//nxt_pc = ~`SIGNED_CMP(0, cont.val.valA) ? pcbranch : pcplus8;
			nxt_pc = $signed(0) >= $signed(cont.val.valA) ? pcbranch : pcplus8;
		
		end//TODO:check the cmp logic

		OP_BTYPE: begin
			unique case (cont.instr.payload.itype.rt)
				BR_BLTZ, BR_BLTZAL : begin 
					nxt_pc = $signed(cont.val.valA) < $signed(0) ? pcbranch : pcplus8;
					//nxt_pc = `SIGNED_CMP(cont.val.valA, 0) ? pcbranch : pcplus8;  
				end
				BR_BGEZ, BR_BGEZAL : begin 
					nxt_pc = $signed(cont.val.valA) >= $signed(0) ? pcbranch : pcplus8;
				end
				default : begin
				end
			endcase
		end

		OP_J, OP_JAL: begin 
			nxt_pc = pcjump;
		end

		OP_RTYPE : begin
			unique case (cont.instr.payload.rtype.sfunct)
				FN_JR, FN_JALR : begin
					nxt_pc = cont.val.valA;
				end

				default : nxt_pc = pcplus4;
			endcase
		end

		default: nxt_pc = pcplus4;
		endcase
		
		/*	
		if (cont.instr.opcode == OP_RTYPE && cont.instr.payload.rtype.sfunct == FN_JR) begin
			nxt_pc = cont.val.valA;
		end*/
		
	end
	
	wire _unused_ok = &{1'b0,
                        cont[320:317],
						cont[92:87],
						cont[86:0],
                        1'b0};
	
endmodule
