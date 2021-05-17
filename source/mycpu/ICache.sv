`include "common.svh"

module ICache (
    input logic clk, resetn,

    input  ibus_req_t  ireq,
    output ibus_resp_t iresp,
    output cbus_req_t  icreq,
    input  cbus_resp_t icresp,
    input i1 uncachedI
);
    // simply use DCache as ICache
    //logic uncachedI;
    //assign uncachedI = 0;
    DCache proxy(
        .dreq(`IREQ_TO_DREQ(ireq)),
        .dresp(iresp),
        .dcreq(icreq),
        .dcresp(icresp),
        .uncachedD(uncachedI),
        .*
    );
endmodule
