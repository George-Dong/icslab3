`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq;
    ibus_resp_t iresp;

    dbus_req_t  dreq;
    dbus_resp_t dresp;

    cbus_req_t  icreq,  dcreq;
    cbus_resp_t icresp, dcresp;

    i1 uncachedD;
    i1 uncachedI;

/*
    assign uncachedD = 0;
    assign uncachedI = 0;

    MyCore core(.*);
    IBusToCBus icvt(.*);
    DBusToCBus dcvt(.*);

    cbus_req_t  oreq_temp;

    typedef logic [31:0] paddr_t;
    typedef logic [31:0] vaddr_t;

    paddr_t paddr;
    vaddr_t vaddr;

    assign vaddr = oreq_temp.addr;
    assign paddr[27:0] = vaddr[27:0];

    always_comb begin
        unique case (vaddr[31:28])
            4'h8: paddr[31:28] = 4'b0; // kseg0
            4'h9: paddr[31:28] = 4'b1; // kseg0
            4'ha: paddr[31:28] = 4'b0; // kseg1
            4'hb: paddr[31:28] = 4'b1; // kseg1
            default: paddr[31:28] = vaddr[31:28]; // useg, ksseg, kseg3
        endcase
    end

    always_comb begin
        oreq = oreq_temp;
        oreq.addr = paddr;
    end

    CBusArbiter mux(
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
        .oreq(oreq_temp),
        .*
    );

*/

    //uncached dectect
    always_comb begin
        uncachedD = 0;
        uncachedI = 0; 
        unique case (dreq.addr[31:28])
            4'ha, 4'hb : begin
                uncachedD = 1;
            end
            default : begin
            end
        endcase
        unique case (ireq.addr[31:28])
            4'ha, 4'hb : begin
                uncachedI = 1;
            end
            default : begin
            end
        endcase
    end

    //addr translation
    cbus_req_t  oreq_temp;

    typedef logic [31:0] paddr_t;
    typedef logic [31:0] vaddr_t;

    paddr_t paddr;
    vaddr_t vaddr;

    assign vaddr = oreq_temp.addr;
    assign paddr[27:0] = vaddr[27:0];

    always_comb begin
        unique case (vaddr[31:28])
            4'h8: paddr[31:28] = 4'b0; // kseg0
            4'h9: paddr[31:28] = 4'b1; // kseg0
            4'ha: paddr[31:28] = 4'b0; // kseg1
            4'hb: paddr[31:28] = 4'b1; // kseg1
            default: paddr[31:28] = vaddr[31:28]; // useg, ksseg, kseg3
        endcase
    end

    always_comb begin
        oreq = oreq_temp;
        oreq.addr = paddr;
    end

    //CbusArbiter
    CBusArbiter mux(
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
        .oreq(oreq_temp),
        .*
    );

    MyCore core(.*);
    ICache icvt(.*);
    DCache dcvt(.*);



    logic _unused_ok = &{ext_int};

endmodule
