module apb_fabric #(
    parameter  RAM_ADDR_W  = 31,
    parameter  UART_ADDR_W = 12,
    parameter  PLIC_ADDR_W = 26
)(
    // Core -> Fabric
    input  logic                    core_i_psel,
    input  logic                    core_i_penable,
    output logic                    core_i_pready,
    input  logic [31:0]             core_i_paddr,
    input  logic                    core_i_pwrite,
    input  logic [31:0]             core_i_pwdata,
    input  logic [3:0]              core_i_pwstrb,
    output logic [31:0]             core_i_prdata,
    output logic                    core_i_pslverr,
    // Fabric -> RAM: 0x0000_0000 -> 0x7fff_ffff (31-bit)
    output logic                    ram_t_psel,
    output logic                    ram_t_penable,
    input  logic                    ram_t_pready,
    output logic [RAM_ADDR_W-1:0]   ram_t_paddr,
    output logic                    ram_t_pwrite,
    output logic [31:0]             ram_t_pwdata,
    output logic [3:0]              ram_t_pwstrb,
    input  logic [31:0]             ram_t_prdata,
    input  logic                    ram_t_pslverr,
    // Fabric -> UART: 0x8000_0000 -> 0x8000_0fff (12-bit)
    output logic                    uart_t_psel,
    output logic                    uart_t_penable,
    input  logic                    uart_t_pready,
    output logic [UART_ADDR_W-1:0]  uart_t_paddr,
    output logic                    uart_t_pwrite,
    output logic [31:0]             uart_t_pwdata,
    output logic [3:0]              uart_t_pwstrb,
    input  logic [31:0]             uart_t_prdata,
    input  logic                    uart_t_pslverr,
    // Fabric -> PLIC: 0x9000_0000 -> 0x93ff_ffff (26-bit)
    output logic                    plic_t_psel,
    output logic                    plic_t_penable,
    input  logic                    plic_t_pready,
    output logic [PLIC_ADDR_W-1:0]  plic_t_paddr,
    output logic                    plic_t_pwrite,
    output logic [31:0]             plic_t_pwdata,
    output logic [3:0]              plic_t_pwstrb,
    input  logic [31:0]             plic_t_prdata,
    input  logic                    plic_t_pslverr
);

    logic  dec_ram;
    logic  dec_uart;
    logic  dec_plic;
    logic  dec_invalid;

    // Memmory map decode logic
    assign dec_ram     = (core_i_paddr[31:31] == 1'h0);
    assign dec_uart    = (core_i_paddr[31:12] == 20'h80000);
    assign dec_plic    = (core_i_paddr[31:26] == 6'b100100);
    assign dec_invalid = ~|{dec_ram, dec_uart, dec_plic};

    // PSEL
    assign ram_t_psel     = core_i_psel & dec_ram;
    assign uart_t_psel    = core_i_psel & dec_uart;
    assign plic_t_psel    = core_i_psel & dec_plic;

    // Request signals are shared
    assign ram_t_penable  = core_i_penable;
    assign ram_t_paddr    = core_i_paddr[RAM_ADDR_W-1:0];
    assign ram_t_pwrite   = core_i_pwrite;
    assign ram_t_pwdata   = core_i_pwdata;
    assign ram_t_pwstrb   = core_i_pwstrb;

    assign uart_t_penable = core_i_penable;
    assign uart_t_paddr   = core_i_paddr[UART_ADDR_W-1:0];
    assign uart_t_pwrite  = core_i_pwrite;
    assign uart_t_pwdata  = core_i_pwdata;
    assign uart_t_pwstrb  = core_i_pwstrb;

    assign plic_t_penable = core_i_penable;
    assign plic_t_paddr   = core_i_paddr[PLIC_ADDR_W-1:0];
    assign plic_t_pwrite  = core_i_pwrite;
    assign plic_t_pwdata  = core_i_pwdata;
    assign plic_t_pwstrb  = core_i_pwstrb;

    // Response signals are muxed
    one_hot_mux #(
        .CH_N     (4),
        .PLD_W    (32 + 1 + 1)  // prdata + pslverr + pready
    ) u_resp_mux(
        .sel      ({dec_ram, dec_uart, dec_plic, dec_invalid}),
        .in_pld   ({
            {ram_t_prdata,  ram_t_pslverr,  ram_t_pready},
            {uart_t_prdata, uart_t_pslverr, uart_t_pready},
            {plic_t_prdata, plic_t_pslverr, plic_t_pready},
            {32'd0,         1'b1,           1'b1}
        }),
        .out_pld  ({core_i_prdata, core_i_pslverr, core_i_pready})
    );

endmodule
