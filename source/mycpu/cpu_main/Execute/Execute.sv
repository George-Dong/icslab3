`include "cpuhead.svh"

module Execute (
	input  content_t     cont,
	output content_t     out_cont,

	input addr_t         cur_pc,
	output addr_t        nxt_pc,

	input word_t 	  	 hi, lo
);

	word_t valA, valB, valC;
	assign valA = cont.val.valA;
	assign valB = cont.val.valB;
	assign valC = cont.val.valC;

	word_t a, b, hi_ans, lo_ans;
	funct_t op;
	
	SelectPC x_SelectPC(.*);
	
	//ALU 
	always_comb begin
		out_cont = cont;
		out_cont.val.valE = '0;
		a = '0;
		b = '0;
		op = FN_SLL;
		if (cont.alu_control.alu_en == 1) begin
			unique case (cont.instr.opcode)
			OP_RTYPE: begin
				unique case (cont.instr.payload.rtype.sfunct)
				FN_SLL: 
					out_cont.val.valE = valB << valC;
				FN_SRL:
					out_cont.val.valE = valB >> valC;
				FN_SRA:
					out_cont.val.valE = $signed(valB) >>> valC;
				FN_ADDU:
					out_cont.val.valE = valA + valB;
				FN_AND:
					out_cont.val.valE = valA & valB;
				FN_OR:
					out_cont.val.valE = valA | valB;
				FN_XOR:
					out_cont.val.valE = valA ^ valB;
				FN_NOR:
					out_cont.val.valE = ~(valA | valB);
				FN_SLT:
					out_cont.val.valE = `SIGNED_CMP(valA, valB);
				FN_SLTU:
					out_cont.val.valE = `UNSIGNED_CMP(valA, valB);
				FN_SUBU:
				    out_cont.val.valE = valA - valB;
				FN_JR:begin 
				end	
				FN_JALR:
					out_cont.val.valE = valB + 32'd8; //TODO:check?
				FN_SLLV:
					out_cont.val.valE = valB << valA;
				FN_SRLV:
					out_cont.val.valE = valB >> valA;
				FN_SRAV:
					out_cont.val.valE = $signed(valB) >>> valA ;
				default: begin
				end
				endcase
			end
			
			OP_ADDIU:
				out_cont.val.valE = valA + valC;
				
			OP_SLTI:
				out_cont.val.valE = `SIGNED_CMP(valA, valC);
				
			OP_SLTIU:
				out_cont.val.valE = `UNSIGNED_CMP(valA, valC);
				
			OP_ANDI:
				out_cont.val.valE = valA & valC;
				
			OP_ORI:
				out_cont.val.valE = valA | valC;
				
			OP_XORI:
				out_cont.val.valE = valA ^ valC;
				
			OP_LUI:
				out_cont.val.valE = valC << 32'd16;
				
			OP_LW, OP_LB, OP_LBU, OP_LH, OP_LHU:
				out_cont.val.valE = valA + valC;
				
			OP_SW, OP_SB, OP_SH:
				out_cont.val.valE = valA + valC;
				
			OP_JAL:
				out_cont.val.valE = valB + 32'd8;

			OP_BTYPE : begin
				unique case (cont.instr.payload.itype.rt) 
					BR_BLTZAL,
					BR_BGEZAL : out_cont.val.valE = valB + 32'd8;
					default : begin
					end
				endcase
			end
			
			default:begin
			end
			
			endcase
		end else if(cont.hilo_reg_control.mult_en == 1)begin
			a = valA;
			b = valB;
			op = cont.instr.payload.rtype.sfunct;
			out_cont.val.hi_data = hi_ans;
			out_cont.val.lo_data = lo_ans;
		end else if (cont.hilo_reg_control.write_reg == 1) begin
			out_cont.val.valE = (cont.hilo_reg_control.hi_read == 1) ? hi : lo; 
		end
	end

	//Mult
	Mult x_Mult(.*);


endmodule
