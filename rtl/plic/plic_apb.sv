module plic_apb(
    // APB slave
    input  logic         psel,
    input  logic         penable,
    output logic         pready,
    input  logic [25:0]  paddr,
    input  logic         pwrite,
    input  logic [31:0]  pwdata,
    input  logic [3:0]   pwstrb,
    output logic [31:0]  prdata,
    output logic         pslverr,
    // Register interface
    output logic [25:0]  reg_addr,
    output logic         reg_read,
    output logic         reg_write,
    output logic [31:0]  reg_wdata,
    input  logic [31:0]  reg_rdata
);

    // No wait states
    assign pready    = 1'b1;

    // Forwarding
    assign reg_addr  = paddr;
    assign reg_wdata = pwdata;
    assign prdata    = reg_rdata;

    // Read/write conditions
    assign reg_read  = psel & penable & ~pwrite & ~pslverr;
    assign reg_write = psel & penable &  pwrite & ~pslverr;

    // Error condition
    // We don't accept unaligned accesses and partial writes
    assign pslverr   = (|paddr[1:0]) | (~&pwstrb);

endmodule
