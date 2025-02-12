// A simple memory model with APB interface
module ram #(
    parameter  RAM_SIZE  = 32'h0010_0000,    // RAM size in bytes
    parameter  ADDR_W    = 32,
    parameter  READ_ONLY = 0
)(
    input  logic               clk,
    // APB slave
    input  logic               psel,
    input  logic               penable,
    output logic               pready,
    input  logic [ADDR_W-1:0]  paddr,
    input  logic               pwrite,
    input  logic [31:0]        pwdata,
    input  logic [3:0]         pwstrb,
    output logic [31:0]        prdata,
    output logic               pslverr
);

    localparam WORD_SIZE   = 4;                     // One word in 4 bytes
    localparam WORD_CNT    = RAM_SIZE / WORD_SIZE;  // RAM size in words
    localparam WORD_CNT_BW = $clog2(WORD_CNT);
    localparam RAM_SIZE_BW = $clog2(RAM_SIZE);

    logic [31:0]             mem_array [WORD_CNT];
    logic [WORD_CNT_BW-1:0]  word_addr;

    // Control: always read on enable
    assign pready = psel & penable;

    // Word address
    assign word_addr = WORD_CNT_BW'(paddr[ADDR_W-1:2]);

    // Write interface
    always_ff @(posedge clk) begin
        if (pready & pwrite & ~pslverr) begin
            if (pwstrb[0]) mem_array[word_addr][0  +: 8] <= pwdata[0  +: 8];
            if (pwstrb[1]) mem_array[word_addr][8  +: 8] <= pwdata[8  +: 8];
            if (pwstrb[2]) mem_array[word_addr][16 +: 8] <= pwdata[16 +: 8];
            if (pwstrb[3]) mem_array[word_addr][24 +: 8] <= pwdata[24 +: 8];
        end
    end

    // Read interface
    assign prdata = mem_array[word_addr];

    // Error when out-of-range
    assign pslverr = |paddr[ADDR_W-1:RAM_SIZE_BW] | (READ_ONLY & pwrite);

endmodule
