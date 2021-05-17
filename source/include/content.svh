`ifndef __CONTENT_SVH__
`define __CONTENT_SVH__

`include "common.svh"

/* Part 1 instructions */

typedef i5  shamt_t;
typedef i16 imm_t;
typedef i26 long_imm_t;

parameter i32 INSTR_NOP = 32'b0;

// opcode: bit 31~26
typedef enum i6 {
    OP_BNE   = 6'b000101,
    OP_RTYPE = 6'b000000,
    OP_BTYPE = 6'b000001, //BGEZ, BLTZ
    OP_J     = 6'b000010,
    OP_JAL   = 6'b000011,
    OP_BEQ   = 6'b000100,
    OP_BLEZ  = 6'b000110,
    OP_BGTZ  = 6'b000111,
    OP_ADDI  = 6'b001000,
    OP_ADDIU = 6'b001001,
    OP_SLTI  = 6'b001010,
    OP_SLTIU = 6'b001011,
    OP_ANDI  = 6'b001100,
    OP_ORI   = 6'b001101,
    OP_XORI  = 6'b001110,
    OP_LUI   = 6'b001111,
    OP_COP0  = 6'b010000,
    OP_LB    = 6'b100000,
    OP_LH    = 6'b100001,
    OP_LW    = 6'b100011,
    OP_LBU   = 6'b100100,
    OP_LHU   = 6'b100101,
    OP_SB    = 6'b101000,
    OP_SH    = 6'b101001,
    OP_SW    = 6'b101011
} opcode_t /* verilator public */;

// funct, for SPECIAL instructions: bit 5~0
typedef enum i6 {
    FN_SLL     = 6'b000000,
    FN_SRL     = 6'b000010,
    FN_SRA     = 6'b000011,
    FN_SRLV    = 6'b000110,
    FN_SRAV    = 6'b000111,
    FN_SLLV    = 6'b000100,
    FN_JR      = 6'b001000,
    FN_JALR    = 6'b001001,
    FN_SYSCALL = 6'b001100,
    FN_BREAK   = 6'b001101,
    FN_MFHI    = 6'b010000,
    FN_MTHI    = 6'b010001,
    FN_MFLO    = 6'b010010,
    FN_MTLO    = 6'b010011,
    FN_MULT    = 6'b011000,
    FN_MULTU   = 6'b011001,
    FN_DIV     = 6'b011010,
    FN_DIVU    = 6'b011011,
    FN_ADD     = 6'b100000,
    FN_ADDU    = 6'b100001,
    FN_SUB     = 6'b100010,
    FN_SUBU    = 6'b100011,
    FN_AND     = 6'b100100,
    FN_OR      = 6'b100101,
    FN_XOR     = 6'b100110,
    FN_NOR     = 6'b100111,
    FN_SLT     = 6'b101010,
    FN_SLTU    = 6'b101011
} funct_t /* verilator public */;

// branch type, for REGIMM instructions
typedef enum i5 {
    BR_BLTZ   = 5'b00000,
    BR_BGEZ   = 5'b00001,
    BR_BLTZAL = 5'b10000,
    BR_BGEZAL = 5'b10001
} btype_t /* verilator public */;

typedef enum i2{
	T_ITYPE, T_RTYPE, T_LITYPE
} instr_type_t;

// general-purpose registers
typedef enum i5 {
    R0, AT, V0, V1, A0, A1, A2, A3,
    T0, T1, T2, T3, T4, T5, T6, T7,
    S0, S1, S2, S3, S4, S5, S6, S7,
    T8, T9, K0, K1, GP, SP, FP, RA
} regid_t /* verilator public */;

typedef enum logic{
	ZERO_EXTENSION, SIGN_EXTENSION
} extension_t;
/**
 * MIPS instruction formats
 */

typedef struct packed {
    regidx_t  rs;
    regidx_t  rt;
    regidx_t  rd;
    shamt_t   shamt;
    funct_t   sfunct;
} rtype_instr_t;

typedef struct packed {
    regidx_t  rs;
    regidx_t  rt;
    imm_t     imm;
} itype_instr_t;

typedef struct packed {
    opcode_t opcode;
    union packed {
        rtype_instr_t   rtype;
        itype_instr_t   itype;
        long_imm_t      index;  // J-type
    } payload;
} instr_t;



/* Part 2 pipeline registers */

typedef struct packed{
	word_t   valA;  //ALU_A
	word_t   valB;  //ALU_B
	word_t   valC;  //immediate num
	word_t   valE;
	word_t   valM;
    word_t   hi_data;
    word_t   lo_data;
}val_t;

typedef struct packed{
	regidx_t target_id;
	logic    write_en;
	regidx_t ra1, ra2;
	logic    read1_en, read2_en;
}reg_control_t;

typedef struct packed {
    logic hi_write;
    logic lo_write;
    logic hi_read;
    logic lo_read;
    logic write_reg;
    logic mult_en;
}hilo_reg_control_t;

typedef struct packed{
	addr_t   target_addr;
	logic    write_en;
	logic    read_en;
}mem_control_t;

typedef struct packed{
	logic    alu_en;
}alu_control_t;

typedef struct packed{
	logic    branch_en;
	logic    branch_taken;
	addr_t   branch_pc;
}branch_control_t;

typedef struct packed{
	logic        extension_en;
	extension_t  extension;
}extension_control_t;

typedef struct packed {
    addr_t                pc;
    instr_t               instr;
	instr_type_t          instr_type;
	extension_control_t   extension_control;
	val_t                 val;
	reg_control_t         reg_control;
    hilo_reg_control_t    hilo_reg_control;
	branch_control_t      branch_control;
	alu_control_t         alu_control;
	mem_control_t         mem_control;
} content_t;

parameter addr_t PC_RESET = 32'hbfc00000;

/* Part 3 system defines*/

`define IMPL_Cxx(S, M) \
    M M``_inst(.out(out_ctx[S]), .*); \
    assign {out_ireq[S], out_dreq[S]} = '0;
`define IMPL_CIx(S, M) \
    M M``_inst(.out(out_ctx[S]), .ireq(out_ireq[S]), .*); \
    assign out_dreq[S] = '0;
`define IMPL_CxD(S, M) \
    M M``_inst(.out(out_ctx[S]), .dreq(out_dreq[S]), .*); \
    assign out_ireq[S] = '0;

// it's generally rare that an instruction interacts with
// both instruction cache and data cache simultaneously...
`define IMPL_CID(S, M) \
    M M``_inst(.out(out_ctx[S]), .ireq(out_ireq[S]), .dreq(out_dreq[S]), .*);


`define SIGN_EXTEND(imm, width) \
    {{(((width) - 1) - $high(imm)){imm[$high(imm)]}}, imm}
    
`define ZERO_EXTEND(imm, width) \
    {{(((width) - 1) - $high(imm)){1'b0}}, imm}

`define FORMAT_ITYPE(opcode, rs, rt, imm, instr) \
    opcode_t opcode; \
    creg_addr_t rs, rt; \
    imm_t imm; \
    assign {opcode, rs, rt, imm} = instr;
`define FORMAT_RTYPE(rs, rt, rd, shamt, funct, instr) \
    creg_addr_t rs, rt, rd; \
    shamt_t shamt; \
    funct_t funct; \
    assign {rs, rt, rd, shamt, funct} = instr.payload;

`define ITYPE_RS ctx.instr.payload.itype.rs
`define ITYPE_RT ctx.instr.payload.itype.rt
`define ITYPE_IMM ctx.instr.payload.itype.imm

`define MEM_WAIT(resp, self, step1, step2) \
    if (resp.addr_ok && resp.data_ok) \
        out.state = step2; \
    else if (resp.addr_ok) \
        out.state = step1; \
    else \
        out.state = self;

`define SIGNED_CMP(a, b) \
    {31'b0, ($signed(a) < $signed(b))}
`define UNSIGNED_CMP(a, b) \
    {31'b0, ({1'b0, (a)} < {1'b0, (b)})}

`define THROW(ecode) \
    begin \
        out.state = S_EXCEPTION; \
        out.args.exception.code = ecode; \
        out.args.exception.delayed = ctx.delayed; \
        out.target_id = R0;  /* cancel writeback */ \
        out.delayed = 0;     /* cancel branch */ \
    end
`define ADDR_ERROR(ecode, vaddr) \
    begin \
        out.args.exception.bad_vaddr = vaddr; \
        `THROW(ecode) \
    end
`define FATAL \
    begin out.state = S_UNKNOWN; end



`endif
