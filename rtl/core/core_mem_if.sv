module core_mem_if (
    input  logic         clk,
    input  logic         rst_n,
    // From FETCH stage
    input  logic         imem_valid,
    output logic         imem_ready,
    input  logic [31:0]  imem_addr,
    output logic [31:0]  imem_rdata,
    output logic         imem_err,
    // From MEM stage
    input  logic         dmem_valid,
    output logic         dmem_ready,
    input  logic [31:0]  dmem_addr,
    input  logic         dmem_write,
    input  logic [31:0]  dmem_wdata,
    input  logic  [3:0]  dmem_wstrb,
    output logic [31:0]  dmem_rdata,
    output logic         dmem_err,
    // APB master
    output logic         psel,
    output logic         penable,
    input  logic         pready,
    output logic [31:0]  paddr,
    output logic         pwrite,
    output logic [31:0]  pwdata,
    output logic  [3:0]  pwstrb,
    input  logic [31:0]  prdata,
    input  logic         pslverr
);

    // Handshake
    // Although there are 2 input interfaces,
    // no arbiter is needed since FETCH and MEM do not coexist.
    assign psel       = imem_valid | dmem_valid;
    assign imem_ready = imem_valid & pready & penable;
    assign dmem_ready = dmem_valid & pready & penable;

    // PENABLE flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       penable <= 1'b0;
        else if (psel & penable & pready) penable <= 1'b0;
        else                              penable <= psel;
    end

    // APB request
    assign paddr  = dmem_valid ? dmem_addr : imem_addr;
    assign pwrite = dmem_valid ? dmem_write : 1'b0;     // I-mem only reads
    assign pwdata = dmem_wdata;
    assign pwstrb = dmem_wstrb;

    // APB response
    assign imem_rdata = prdata;
    assign imem_err   = pslverr;

    assign dmem_rdata = prdata;
    assign dmem_err   = pslverr;

    // Assertion: imem_valid and dmem_valid are mutually exclusive
    A_SingleValid: assert property (@(posedge clk) disable iff (~rst_n)
        ~(imem_valid & dmem_valid)
    );

endmodule
