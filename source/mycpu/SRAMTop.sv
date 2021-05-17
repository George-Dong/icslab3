`include "common.svh"
`include "sramx.svh"

module SRAMTop(
    input logic clk, resetn,

    output logic        inst_sram_en,
    output logic [3 :0] inst_sram_wen,
    output logic [31:0] inst_sram_addr,
    output logic [31:0] inst_sram_wdata,
    input  logic [31:0] inst_sram_rdata,
    output logic        data_sram_en,
    output logic [3 :0] data_sram_wen,
    output logic [31:0] data_sram_addr,
    output logic [31:0] data_sram_wdata,
    input  logic [31:0] data_sram_rdata,

    input i6 ext_int
);
    ibus_req_t   ireq, ireq_temp;
    ibus_resp_t  iresp;
    dbus_req_t   dreq, dreq_temp;
    dbus_resp_t  dresp;
    sramx_req_t  isreq,  dsreq;
    sramx_resp_t isresp, dsresp;

    MyCore core( .ireq(ireq_temp), .dreq(dreq_temp), .*);
    IBusToSRAMx icvt(.*);
    DBusToSRAMx dcvt(.*);

    /**
     * TODO (optional) add address translations for isreq.addr & dsreq.addr :)
     */
     
        typedef logic [31:0] paddr_t;
        typedef logic [31:0] vaddr_t;
        
        paddr_t paddr,paddr2; // physical address
        vaddr_t vaddr,vaddr2; // virtual address
        
        assign vaddr = ireq_temp.addr;
        assign vaddr2 = dreq_temp.addr;
        assign paddr[27:0] = vaddr[27:0];
        assign paddr2[27:0] = vaddr2[27:0];
        always_comb begin
            unique case (vaddr[31:28])
                4'h8: paddr[31:28] = 4'b0; // kseg0
                4'h9: paddr[31:28] = 4'b1; // kseg0
                4'ha: paddr[31:28] = 4'b0; // kseg1
                4'hb: paddr[31:28] = 4'b1; // kseg1
                default: paddr[31:28] = vaddr[31:28]; // useg, ksseg, kseg3
            endcase
            unique case (vaddr2[31:28])
                4'h8: paddr2[31:28] = 4'b0; // kseg0
                4'h9: paddr2[31:28] = 4'b1; // kseg0
                4'ha: paddr2[31:28] = 4'b0; // kseg1
                4'hb: paddr2[31:28] = 4'b1; // kseg1
                default: paddr2[31:28] = vaddr2[31:28]; // useg, ksseg, kseg3
            endcase
        end
        
        always_comb begin
            ireq = ireq_temp;
            ireq.addr = paddr;
            dreq = dreq_temp;
            dreq.addr = paddr2;
        end

    assign inst_sram_en    = isreq.en;
    assign inst_sram_wen   = isreq.wen;
    assign inst_sram_addr  = isreq.addr;
    assign inst_sram_wdata = isreq.wdata;
    assign isresp.rdata    = inst_sram_rdata;

    assign data_sram_en    = dsreq.en;
    assign data_sram_wen   = dsreq.wen;
    assign data_sram_addr  = dsreq.addr;
    assign data_sram_wdata = dsreq.wdata;
    assign dsresp.rdata    = data_sram_rdata;

    logic _unused_ok = &{ext_int};
endmodule
