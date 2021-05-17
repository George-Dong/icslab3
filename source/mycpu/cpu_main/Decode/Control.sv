`include "cpuhead.svh"

module Control(
	input  instr_t           instr,
	output reg_control_t        reg_control,
	output alu_control_t        alu_control,
	output mem_control_t        mem_control,
	output instr_type_t      	instr_type,
	output hilo_reg_control_t 	hilo_reg_control,
	output extension_control_t  extension_control
);

	logic HILO_TYPE_READREG, HILO_TYPE_WRITEREG;
	funct_t R_funct;

	assign R_funct = instr.payload.rtype.sfunct;
	assign HILO_TYPE_READREG = (R_funct==FN_MULTU) || (R_funct==FN_MULT) 
					 || (R_funct==FN_MTHI) || (R_funct==FN_MTLO) 
					 || (R_funct==FN_DIVU) || (R_funct==FN_DIVU); 
		
	assign HILO_TYPE_WRITEREG = (R_funct==FN_MFHI) || (R_funct==FN_MFLO);

	always_comb begin
		reg_control = '0;
		alu_control = '0;
		mem_control = '0;
		hilo_reg_control = '0;
		instr_type = T_ITYPE;	
		extension_control.extension_en = 0;
		extension_control.extension = ZERO_EXTENSION;
		if(instr == INSTR_NOP) begin
		end
		
		else begin 
			unique case(instr.opcode)
			OP_RTYPE: begin
				instr_type = T_RTYPE;				
				reg_control.target_id = instr.payload.rtype.rd;
				reg_control.ra1 = instr.payload.rtype.rs;
				reg_control.ra2 = instr.payload.rtype.rt;
				reg_control.read1_en = 1;
				reg_control.read2_en = 1;

				alu_control.alu_en = 0;
				reg_control.write_en = 1;
				//TODO instr like JR does not need write_en
				unique case (R_funct)
					FN_JR : begin
						reg_control.write_en = 0;
					end
					default : begin
						
					end
				endcase

				unique case (R_funct)
					FN_MULTU, FN_MULT, FN_DIV, FN_DIVU : begin
						reg_control.write_en = 0;
						hilo_reg_control.hi_write = 1;
						hilo_reg_control.lo_write = 1;
						hilo_reg_control.mult_en = 1;
					end
					FN_MTHI : begin
						hilo_reg_control.hi_write = 1;
						reg_control.write_en = 0;
						hilo_reg_control.mult_en = 1;
					end
					FN_MTLO : begin
						hilo_reg_control.lo_write = 1;
						reg_control.write_en = 0;
						hilo_reg_control.mult_en = 1;
					end
					FN_MFHI : begin
						hilo_reg_control.write_reg = 1;
						hilo_reg_control.hi_read = 1;
					end
					FN_MFLO : begin
						hilo_reg_control.write_reg = 1;
						hilo_reg_control.lo_read = 1;
					end
					default : begin
						alu_control.alu_en = 1;
					end
				endcase
			end

			OP_ANDI, OP_ORI, 
			OP_XORI, OP_LUI: begin
				reg_control.target_id = instr.payload.itype.rt;
				reg_control.write_en = 1;
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.read1_en = 1; 
				alu_control.alu_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = ZERO_EXTENSION;
				instr_type = T_ITYPE;
			end
			
			OP_ADDIU, OP_SLTIU, 
			OP_ADDI, OP_SLTI: begin
				reg_control.target_id = instr.payload.rtype.rt;
				reg_control.write_en = 1;
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.read1_en = 1; 
				alu_control.alu_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = SIGN_EXTENSION;
				instr_type = T_ITYPE;
			end
			
			OP_BEQ, OP_BNE: begin
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.ra2 = instr.payload.itype.rt;
				reg_control.read1_en = 1;
				reg_control.read2_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = ZERO_EXTENSION;
				//branch_control.branch_en = 1;
				instr_type = T_ITYPE;
			end
			
			OP_BGTZ, OP_BLEZ: begin
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.read1_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = ZERO_EXTENSION; 
				instr_type = T_ITYPE;
			end

			OP_BTYPE : begin
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.read1_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = ZERO_EXTENSION; 
				instr_type = T_ITYPE;
				unique case (instr.payload.itype.rt) 
					BR_BLTZAL,
					BR_BGEZAL : begin
						reg_control.write_en = 1;
						alu_control.alu_en = 1;
						reg_control.read2_en = 1;
						reg_control.target_id = 5'd31;
					end
					default : begin
					end
				endcase

			end
			OP_J: begin
				//branch_control.branch_en = 1;
				instr_type = T_LITYPE;
			end
			
			OP_JAL: begin
				instr_type = T_LITYPE;
				reg_control.write_en = 1;
				reg_control.target_id = 5'd31;
				alu_control.alu_en = 1;
			end
			
			OP_LW, OP_LB, OP_LBU, OP_LH, OP_LHU: begin
				reg_control.target_id = instr.payload.itype.rt;
				reg_control.write_en = 1;
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.read1_en = 1;
				alu_control.alu_en = 1;
				mem_control.read_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = ZERO_EXTENSION;
				instr_type = T_ITYPE;
			end
			
			OP_SW, OP_SB, OP_SH: begin
				reg_control.ra1 = instr.payload.itype.rs;
				reg_control.ra2 = instr.payload.itype.rt;
				reg_control.read1_en = 1;
				reg_control.read2_en = 1;
				alu_control.alu_en = 1;
				mem_control.write_en = 1;
				extension_control.extension_en = 1;
				extension_control.extension = ZERO_EXTENSION;
				instr_type = T_ITYPE;
			end
			
			default: begin
			end
			endcase 
	end
	end
	wire _unused_ok = &{1'b0,
						HILO_TYPE_READREG,
						HILO_TYPE_WRITEREG,
                        1'b0};

endmodule
