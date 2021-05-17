`include "cpuhead.svh"

module Decode (
    input  content_t   cont,
    output content_t   out_cont,

	input  content_t   E_cont,
	input  content_t   M_cont,
	output regidx_t    ra1,ra2,
	input  word_t      rd1,rd2,
	//input word_t 	   hi, lo,
	output logic       hazzard
);
	reg_control_t        reg_control;
	alu_control_t        alu_control;
	mem_control_t        mem_control;
	hilo_reg_control_t 	 hilo_reg_control;
	instr_t           	 instr;
	instr_type_t         instr_type;
	extension_control_t  extension_control;
	val_t                val;
	word_t               valA, valB, valC;
	

	assign instr = cont.instr;
	
	Control x_Control(.*);

	
	assign ra1 = reg_control.read1_en ? reg_control.ra1 : 0;
	assign ra2 = reg_control.read2_en ? reg_control.ra2 : 0;

	
	//hazard detect
	assign hazzard = ((E_cont.reg_control.target_id == ra1) || (E_cont.reg_control.target_id == ra2)) && E_cont.reg_control.write_en && E_cont.mem_control.read_en;

	//extension 
	always_comb begin
	   valC = '0;
		if(extension_control.extension_en) begin
			if(extension_control.extension == ZERO_EXTENSION) begin
				valC = `ZERO_EXTEND(instr.payload.itype.imm, 32);
			end else begin
				valC = `SIGN_EXTEND(instr.payload.itype.imm, 32);
			end
		end
	end
	

	//fowarding
	always_comb begin
		if(E_cont.reg_control.target_id == ra1 && E_cont.reg_control.write_en) begin
			valA = E_cont.val.valE;
		end else if(M_cont.reg_control.target_id == ra1 && M_cont.reg_control.write_en) begin
			valA = M_cont.mem_control.read_en ? M_cont.val.valM : M_cont.val.valE;
		end else begin
			valA = rd1;
		end
		
		if(E_cont.reg_control.target_id == ra2 && E_cont.reg_control.write_en) begin
			valB = E_cont.val.valE;
		end else if(M_cont.reg_control.target_id == ra2 && M_cont.reg_control.write_en) begin
			valB = M_cont.mem_control.read_en ? M_cont.val.valM : M_cont.val.valE;
		end else begin
			valB = rd2;
		end
	end
	


	//assign val
	always_comb begin
		val = '0;
		unique case(instr_type)
		T_RTYPE: begin
			val.valA = valA;
			val.valB = instr.payload.rtype.sfunct == FN_JALR ? cont.pc : valB;
			val.valC = `ZERO_EXTEND(instr.payload.rtype.shamt, 32); //shamt
			
		end
		
		T_ITYPE: begin
			val.valA = valA;
			val.valB = instr.opcode == OP_BTYPE ? cont.pc : valB;
			val.valC = valC;
		end
		
		T_LITYPE: begin
			val.valA = `ZERO_EXTEND(instr.payload.index ,32);
			val.valB = cont.pc;
		end
		default begin
		end
		endcase
	end
	
	
	//assign out_cont
    always_comb begin
		out_cont = cont;
		out_cont.instr = instr;
		out_cont.reg_control = reg_control;
		out_cont.alu_control = alu_control;
		out_cont.mem_control = mem_control;
		out_cont.hilo_reg_control = hilo_reg_control;
		out_cont.instr_type = instr_type;
		out_cont.extension_control = extension_control;
		out_cont.val = val;
    end


	wire _unused_ok = &{1'b0,
						E_cont[384:317],
						E_cont[74:34],
						M_cont[384:317],
						M_cont[74:34],
                        1'b0};


endmodule
