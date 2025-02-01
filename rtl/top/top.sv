// Top-level environment
// Consists of:
// - RISCV core
// - APB fabric
// - RAM
// - UART
module top #(
    parameter  RESET_VECTOR = 32'h0000_0000,    // Value of PC when reset
    parameter  RAM_SIZE = 32'h0010_0000         // RAM size in bytes
)(
    input  logic  clk,
    input  logic  rst_n,
    // UART I/O
    output logic  tx,
    input  logic  rx
);

    localparam RAM_ADDR_W  = 31;
    localparam UART_ADDR_W = 12;
    localparam PLIC_ADDR_W = 26;

    // Core -> Fabric
    logic                    core_i_psel;
    logic                    core_i_penable;
    logic                    core_i_pready;
    logic [31:0]             core_i_paddr;
    logic                    core_i_pwrite;
    logic [31:0]             core_i_pwdata;
    logic [3:0]              core_i_pwstrb;
    logic [31:0]             core_i_prdata;
    logic                    core_i_pslverr;
    // Fabric -> RAM
    logic                    ram_t_psel;
    logic                    ram_t_penable;
    logic                    ram_t_pready;
    logic [RAM_ADDR_W-1:0]   ram_t_paddr;
    logic                    ram_t_pwrite;
    logic [31:0]             ram_t_pwdata;
    logic [3:0]              ram_t_pwstrb;
    logic [31:0]             ram_t_prdata;
    logic                    ram_t_pslverr;
    // Fabric -> UART
    logic                    uart_t_psel;
    logic                    uart_t_penable;
    logic                    uart_t_pready;
    logic [UART_ADDR_W-1:0]  uart_t_paddr;
    logic                    uart_t_pwrite;
    logic [31:0]             uart_t_pwdata;
    logic [3:0]              uart_t_pwstrb;
    logic [31:0]             uart_t_prdata;
    logic                    uart_t_pslverr;
    // Fabric -> PLIC
    logic                    plic_t_psel;
    logic                    plic_t_penable;
    logic                    plic_t_pready;
    logic [PLIC_ADDR_W-1:0]  plic_t_paddr;
    logic                    plic_t_pwrite;
    logic [31:0]             plic_t_pwdata;
    logic [3:0]              plic_t_pwstrb;
    logic [31:0]             plic_t_prdata;
    logic                    plic_t_pslverr;

    // Interrupt sources
    logic                    uart_int;

    // Interrupt targets
    logic                    int_m_ext;

    // --------------------- Core ---------------------
    core_top #(
        .RESET_VECTOR  (RESET_VECTOR)
    ) u_core(
        .clk           (clk),
        .rst_n         (rst_n),
        .psel          (core_i_psel),
        .penable       (core_i_penable),
        .pready        (core_i_pready),
        .paddr         (core_i_paddr),
        .pwrite        (core_i_pwrite),
        .pwdata        (core_i_pwdata),
        .pwstrb        (core_i_pwstrb),
        .prdata        (core_i_prdata),
        .pslverr       (core_i_pslverr),
        .int_m_ext     (int_m_ext)
    );

    // -------------------- Fabric --------------------
    apb_fabric #(
        .RAM_ADDR_W      (RAM_ADDR_W),
        .UART_ADDR_W     (UART_ADDR_W),
        .PLIC_ADDR_W     (PLIC_ADDR_W)
    ) u_apb_fabric(
        .core_i_psel     (core_i_psel),
        .core_i_penable  (core_i_penable),
        .core_i_pready   (core_i_pready),
        .core_i_paddr    (core_i_paddr),
        .core_i_pwrite   (core_i_pwrite),
        .core_i_pwdata   (core_i_pwdata),
        .core_i_pwstrb   (core_i_pwstrb),
        .core_i_prdata   (core_i_prdata),
        .core_i_pslverr  (core_i_pslverr),
        .ram_t_psel      (ram_t_psel),
        .ram_t_penable   (ram_t_penable),
        .ram_t_pready    (ram_t_pready),
        .ram_t_paddr     (ram_t_paddr),
        .ram_t_pwrite    (ram_t_pwrite),
        .ram_t_pwdata    (ram_t_pwdata),
        .ram_t_pwstrb    (ram_t_pwstrb),
        .ram_t_prdata    (ram_t_prdata),
        .ram_t_pslverr   (ram_t_pslverr),
        .uart_t_psel     (uart_t_psel),
        .uart_t_penable  (uart_t_penable),
        .uart_t_pready   (uart_t_pready),
        .uart_t_paddr    (uart_t_paddr),
        .uart_t_pwrite   (uart_t_pwrite),
        .uart_t_pwdata   (uart_t_pwdata),
        .uart_t_pwstrb   (uart_t_pwstrb),
        .uart_t_prdata   (uart_t_prdata),
        .uart_t_pslverr  (uart_t_pslverr),
        .plic_t_psel     (plic_t_psel),
        .plic_t_penable  (plic_t_penable),
        .plic_t_pready   (plic_t_pready),
        .plic_t_paddr    (plic_t_paddr),
        .plic_t_pwrite   (plic_t_pwrite),
        .plic_t_pwdata   (plic_t_pwdata),
        .plic_t_pwstrb   (plic_t_pwstrb),
        .plic_t_prdata   (plic_t_prdata),
        .plic_t_pslverr  (plic_t_pslverr)
    );

    // --------------------- RAM ----------------------
    ram #(
        .RAM_SIZE      (RAM_SIZE),
        .ADDR_W        (RAM_ADDR_W)
    ) u_ram(
        .clk           (clk),
        .psel          (ram_t_psel),
        .penable       (ram_t_penable),
        .pready        (ram_t_pready),
        .paddr         (ram_t_paddr),
        .pwrite        (ram_t_pwrite),
        .pwdata        (ram_t_pwdata),
        .pwstrb        (ram_t_pwstrb),
        .prdata        (ram_t_prdata),
        .pslverr       (ram_t_pslverr)
    );

    // -------------------- UART ----------------------
    uart_top u_uart(
        .clk       (clk),
        .rst_n     (rst_n),
        .psel      (uart_t_psel),
        .penable   (uart_t_penable),
        .pready    (uart_t_pready),
        .paddr     (uart_t_paddr),
        .pwrite    (uart_t_pwrite),
        .pwdata    (uart_t_pwdata),
        .pwstrb    (uart_t_pwstrb),
        .prdata    (uart_t_prdata),
        .pslverr   (uart_t_pslverr),
        .tx        (tx),
        .rx        (rx),
        .uart_int  (uart_int)
    );

    // -------------------- PLIC ----------------------
    plic_top #(
        .SRC_N    (1),  // 1 interrupt source
        .TGT_N    (1),  // 1 interrupt target
        .PRIO_W   (2)   // 4-level (2-bit) priority
    ) u_plic_top(
        .clk      (clk),
        .rst_n    (rst_n),
        .psel     (plic_t_psel),
        .penable  (plic_t_penable),
        .pready   (plic_t_pready),
        .paddr    (plic_t_paddr),
        .pwrite   (plic_t_pwrite),
        .pwdata   (plic_t_pwdata),
        .pwstrb   (plic_t_pwstrb),
        .prdata   (plic_t_prdata),
        .pslverr  (plic_t_pslverr),
        .int_src  ({
            uart_int    // Source 1
        }),
        .int_tgt  ({
            int_m_ext   // Target 0
        })
    );


endmodule
