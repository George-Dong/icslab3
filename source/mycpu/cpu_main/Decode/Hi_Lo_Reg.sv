`include "cpuhead.svh"

module Hi_Lo_Reg (
    input logic clk,
    input logic resetn,

    output word_t hi, lo,
    
    input logic hi_write, lo_write,
    input word_t hi_data, lo_data
);
    word_t hi_new, lo_new;
    always_comb begin
        {hi_new, lo_new} = {hi, lo};
        if (hi_write) begin
            hi_new = hi_data;
        end
        if (lo_write) begin
            lo_new = lo_data;
        end
    end
    always_ff @(posedge clk) begin
        if(resetn) begin
            {hi, lo} <= {hi_new, lo_new};            
        end else begin
            {hi, lo} <= '0;
        end
    end
endmodule
