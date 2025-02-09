// Top-level testbench
// Consists of the core, a RAM, a clock generator, and a MTIME counter.
module core_tb_top #(
    parameter  RESET_VECTOR = 32'h8000_0000,    // Value of PC when reset
    parameter  RAM_SIZE = 32'h0010_0000         // RAM size in bytes
)(
    input  logic  rst_n,
    // External interrupt
    input  logic  int_m_ext,
    input  logic  mtimer_int
);

    logic clk;

    // APB bus
    logic         psel;
    logic         penable;
    logic         pready;
    logic [33:0]  paddr;
    logic         pwrite;
    logic [31:0]  pwdata;
    logic  [3:0]  pwstrb;
    logic [31:0]  prdata;
    logic         pslverr;

    logic [63:0]  mtime;

    logic         invalid_access;

    // --------------------- Core ---------------------
    core_top #(
        .RESET_VECTOR  (RESET_VECTOR)
    ) u_core(
        .clk           (clk),
        .rst_n         (rst_n),
        .psel          (psel),
        .penable       (penable),
        .pready        (pready),
        .paddr         (paddr),
        .pwrite        (pwrite),
        .pwdata        (pwdata),
        .pwstrb        (pwstrb),
        .prdata        (prdata),
        .pslverr       (pslverr | invalid_access),
        .mtime         (mtime),
        .int_m_ext     (int_m_ext),
        .mtimer_int    (mtimer_int)
    );

    // --------------------- RAM ----------------------
    ram #(
        .RAM_SIZE      (RAM_SIZE),
        .ADDR_W        (31)
    ) u_ram(
        .clk           (clk),
        .psel          (psel),
        .penable       (penable),
        .pready        (pready),
        .paddr         (paddr[30:0]),
        .pwrite        (pwrite),
        .pwdata        (pwdata),
        .pwstrb        (pwstrb),
        .prdata        (prdata),
        .pslverr       (pslverr)
    );

    assign invalid_access = (paddr[33:31] != 3'b001);

    // ------------------- Clock gen ------------------
    initial begin
        forever begin
            clk = 1'b1;
            #500ns;
            clk = 1'b0;
            #500ns;
        end
    end

    // ----------------- MTIME counter ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) mtime <= 64'b0;
        else        mtime <= mtime + 1'b1;
    end


endmodule
