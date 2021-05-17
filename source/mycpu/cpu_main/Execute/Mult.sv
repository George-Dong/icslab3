`include "cpuhead.svh"

module Mult (
    input word_t a, b,
    input funct_t op,
    output word_t hi_ans, lo_ans
);
    i64 ans;
    i33 lo_temp, hi_temp;

    always_comb begin
        {hi_ans, lo_ans, ans} = '0;
        case (op)
            FN_MULTU: begin
                ans = {32'b0, a} * {32'b0, b};
                hi_ans = ans[63:32]; lo_ans = ans[31:0];
            end
            FN_MULT: begin
                ans = signed'({{32{a[31]}}, a}) * signed'({{32{b[31]}}, b});
                hi_ans = ans[63:32]; lo_ans = ans[31:0];
            end
            FN_MTHI: begin
                hi_ans = a;
            end
            FN_MTLO: begin //FROM rs
                lo_ans = a;
            end
            FN_MFHI: begin //TO rd
                
            end
            FN_MFLO: begin
                
            end
            FN_DIVU: begin
                ans = '0;
                lo_temp = {1'b0, a} / {1'b0, b};
                lo_ans = lo_temp[31:0];
                hi_temp = {1'b0, a} % {1'b0, b};
                hi_ans = hi_temp[31:0];
            end
            FN_DIV: begin
                ans = '0;
                lo_ans = signed'(a) / signed'(b);
                hi_ans = signed'(a) % signed'(b);
            end
            default: begin
                {hi_ans, lo_ans, ans} = '0;
            end
        endcase
    end
    wire _unused_ok = &{1'b0,
                        lo_temp,
                        hi_temp,
						1'b0};    

endmodule
