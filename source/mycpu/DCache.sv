`include "common.svh"

module DCache #(
    parameter int OFFSET_BITS = 4,
    parameter int INDEX_BITS = 2,
    parameter int POSITION_BITS = 2

) (
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  dcreq,
    input  cbus_resp_t dcresp,
    input i1 uncachedD
);


    /* Part 1 Defs and Stores */
    parameter int TAG_BITS = 32 - OFFSET_BITS - INDEX_BITS;
    parameter int INSTR_SIZE = 1 << (OFFSET_BITS-2);
    parameter int INDEX_ROW = 1 << INDEX_BITS;
    parameter int ASSOCIATIVITY = 1 << POSITION_BITS;

    typedef logic[TAG_BITS-1:0] tag_t;
    typedef logic[INDEX_BITS-1:0] index_t;
    typedef logic[OFFSET_BITS-3:0] offset_t; 
    typedef logic [POSITION_BITS-1 : 0] position_t;

    typedef struct packed {
        tag_t tag;
        logic valid;  // cache line 是否有效？
        logic dirty;  // cache line 是否被写入了？
    } meta_t;
    typedef word_t [INSTR_SIZE-1:0] cache_line_t;

    typedef meta_t [ASSOCIATIVITY-1:0] meta_set_t; 
    typedef cache_line_t [ASSOCIATIVITY-1:0] cache_set_t;     

    typedef enum i3 {
        IDLE,
        INVALID,
        FETCH,
        VALID,
        DIRTY,
        READY
    } state_t;


    /* Part 2 Stuff handling */
    state_t state;
    dbus_req_t req;
    offset_t start;

    /* verilator lint_off UNDRIVEN */
    meta_set_t [INDEX_ROW-1:0] meta, meta_nxt;
    cache_set_t [INDEX_ROW-1:0] data /* verilator public_flat_rd */, data_nxt;
    /* verilator lint_on UNDRIVEN */

    // 解析地址
    tag_t tag;
    index_t index;
    offset_t offset;
    assign {tag, index} = dreq.addr[31:OFFSET_BITS]; 
    assign start = dreq.addr[OFFSET_BITS-1:2];

    // 搜索 cache line 
    meta_set_t foo;
    assign foo = meta_nxt[index];

    // 访问 cache line
    i32 cache_data;
    cache_line_t bar;
    assign bar = data[index][position];
    assign cache_data = bar[offset];  


    position_t position;
    i1 HIT, MISS;
    always_comb begin
        position = 2'b00; 
        HIT = 1;
        if (foo[0].tag == tag)
            position = 2'b00;
        else if (foo[1].tag == tag)
            position = 2'b01;
        else if (foo[2].tag == tag)
            position = 2'b10;
        else if (foo[3].tag == tag)
            position = 2'b11;
        else begin  
            HIT = 0;
            if(!foo[0].valid) position = 2'b00;
            else if(!foo[1].valid) position = 2'b01;
            else if(!foo[2].valid) position = 2'b10;
            else if(!foo[3].valid) position = 2'b11;
            else position = tag[1:0];  //replacement implement
        end         
    end
    assign MISS = ~(HIT & foo[position].valid); 
    

    i1 okay, okey;
    assign okay = dcresp.ready && dcresp.last;
    assign okey = state == READY;
    always_comb begin
        if(!uncachedD)begin
            dresp = {okey, okey, cache_data};
        end else begin
            dresp  = {okay, okay, dcresp.data};
        end
    end

    i1 is_dirty;

    for(genvar i = 0; i < INDEX_ROW; ++i)begin
        for(genvar j = 0; j < ASSOCIATIVITY; ++j)begin   
            for(genvar k = 0; k < INSTR_SIZE; ++k)begin
                always_comb begin
                    data_nxt[i][j][k] = data[i][j][k];
                    if(index == i && position == j && offset == k)begin
                        if(state == FETCH) begin
                            data_nxt[i][j][k] = dcresp.data;
                        end else if(state != IDLE && state != DIRTY && (|req.strobe))begin
                            if(req.strobe[0])data_nxt[i][j][k][7:0] = req.data[7:0];
                            if(req.strobe[1])data_nxt[i][j][k][15:8] = req.data[15:8];
                            if(req.strobe[2])data_nxt[i][j][k][23:16] = req.data[23:16];
                            if(req.strobe[3])data_nxt[i][j][k][31:24] = req.data[31:24];
                        end
                    end
                end
            end
            always_comb begin
                meta_nxt[i][j] = meta[i][j];
                if(index == i && position == j && state != IDLE && state != DIRTY)begin
                    meta_nxt[i][j] = {tag, 1'b1, is_dirty};
                end
            end
        end
    end

    /* Part 3 Assign and Update */
    always_comb begin
        if(!uncachedD)begin
            dcreq.valid    = state == FETCH || state == DIRTY;
            dcreq.is_write = state == DIRTY;
            dcreq.size     = MSIZE4;
            dcreq.addr     = req.addr;
            dcreq.strobe   = 4'b1111;
            dcreq.data     = cache_data;
            dcreq.len      = MLEN4;          
        end else begin
            dcreq.valid    =  dreq.valid;
            dcreq.is_write = |dreq.strobe;
            dcreq.size     =  dreq.size;
            dcreq.addr     =  dreq.addr;
            dcreq.strobe   =  dreq.strobe;
            dcreq.data     =  dreq.data;
            dcreq.len      =  MLEN1;
        end
    end

    always_ff @(posedge clk) begin
        if(~resetn) begin
            meta <= '0;
            data <= '0;

            state <= IDLE;
            req <= '0;
            offset <= '0;
            is_dirty <= '0;
        end else begin
            meta <= meta_nxt;
            data <= data_nxt;

            unique case (state)
                IDLE: 
                    if(dreq.valid)begin
                        if(!uncachedD)begin
                            state  <= MISS ? (foo[position].dirty ? DIRTY : INVALID) : VALID;
                            offset <= start;                                    
                            req.addr <= {foo[position].tag, index, start, 2'b00};
                            {req.strobe, req.data} <= {dreq.strobe, dreq.data};
                            is_dirty <= foo[position].dirty | (|dreq.strobe);  
                        end
                    end

                READY: 
                    begin
                        state <= IDLE;
                    end

                INVALID: 
                    if(dreq.valid && !uncachedD)begin
                        state  <= FETCH;
                        req    <= dreq;
                        offset <= start;
                    end

                FETCH: 
                    if(dcresp.ready) begin
                        state  <= dcresp.last ? VALID : FETCH;
                        offset <= offset + 1;
                        is_dirty <= foo[position].dirty | (|req.strobe);
                    end

                VALID: 
                    begin
                        state <= READY;
                    end

                DIRTY: 
                    if(dcresp.ready) begin
                        state  <= dcresp.last ? INVALID : DIRTY;
                        offset <= offset + 1;
                    end
                    
                default: 
                    begin
                        state <= IDLE;
                    end 
                    
            endcase
        end
    end
    
    wire _unused_ok = &{1'b0, 
                        req, 
                        1'b0};
endmodule
