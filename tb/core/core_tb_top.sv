// Top-level testbench
// Consists of the core, a RAM, and a clock generator
module core_tb_top #(
    parameter  RESET_VECTOR = 32'h0000_0000,    // Value of PC when reset
    parameter  RAM_SIZE = 32'h0010_0000         // RAM size in bytes
)(
    input  logic  rst_n
);

    logic clk;

    // APB bus
    logic         psel;
    logic         penable;
    logic         pready;
    logic [31:0]  paddr;
    logic         pwrite;
    logic [31:0]  pwdata;
    logic  [3:0]  pwstrb;
    logic [31:0]  prdata;
    logic         pslverr;

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
        .pslverr       (pslverr)
    );

    // --------------------- RAM ----------------------
    ram #(
        .RAM_SIZE      (RAM_SIZE)
    ) u_ram(
        .clk           (clk),
        .psel          (psel),
        .penable       (penable),
        .pready        (pready),
        .paddr         (paddr),
        .pwrite        (pwrite),
        .pwdata        (pwdata),
        .pwstrb        (pwstrb),
        .prdata        (prdata),
        .pslverr       (pslverr)
    );

    // ------------------- Clock gen ------------------
    initial begin
        forever begin
            clk = 1'b1;
            #500ns;
            clk = 1'b0;
            #500ns;
        end
    end

endmodule
