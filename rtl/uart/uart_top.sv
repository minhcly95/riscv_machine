module uart_top(
    input  logic         clk,
    input  logic         rst_n,
    // APB slave
    input  logic         psel,
    input  logic         penable,
    output logic         pready,
    input  logic [11:0]  paddr,
    input  logic         pwrite,
    input  logic [31:0]  pwdata,
    input  logic  [3:0]  pwstrb,
    output logic [31:0]  prdata,
    output logic         pslverr,
    // UART I/O
    output logic         tx,
    input  logic         rx,
    // Interrupt output
    output logic         uart_int
);

    import uart_pkg::*;

    // APB/Register interface
    logic [2:0]   reg_addr;
    logic         reg_read;
    logic         reg_write;
    logic [7:0]   reg_wdata;
    logic [7:0]   reg_rdata;
    logic         reg_err;
    // TX FIFO
    logic         thr_valid;
    logic         thr_ready;
    logic [7:0]   thr_data;
    // TX
    logic         tx_valid;
    logic         tx_ready;
    logic [7:0]   tx_data;
    // RX FIFO
    logic         rhr_valid;
    logic         rhr_ready;
    logic [7:0]   rhr_data;
    rx_err_s      rhr_err;
    logic         rx_overrun;
    logic         rx_fifo_err;
    // RX
    logic         rx_valid;
    logic [7:0]   rx_data;
    rx_err_s      rx_err;
    // Clock generator
    logic         div_clk_en;
    // INTC
    int_code_e    int_code;
    logic         int_rx_line_status;
    logic         int_rx_data_ready;
    logic         int_rx_timeout;
    logic         int_tx_fifo_empty;
    // RX timer
    logic         rd_rhr;
    // Configurations
    word_len_e    cfg_word_len;
    logic         cfg_stop_bit;
    logic         cfg_parity_en;
    logic         cfg_even_parity;
    logic         cfg_force_parity;
    logic         cfg_set_break;
    logic         cfg_fifo_enable;
    logic         cfg_rx_reset;
    logic         cfg_tx_reset;
    fifo_trig_e   cfg_fifo_trig;
    logic [15:0]  cfg_div_const;
    int_en_s      cfg_int_en;

    // ---------------- APB interface -----------------
    uart_apb u_apb(
        .psel       (psel),
        .penable    (penable),
        .pready     (pready),
        .paddr      (paddr),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .pwstrb     (pwstrb),
        .prdata     (prdata),
        .pslverr    (pslverr),
        .reg_addr   (reg_addr),
        .reg_read   (reg_read),
        .reg_write  (reg_write),
        .reg_wdata  (reg_wdata),
        .reg_rdata  (reg_rdata),
        .reg_err    (reg_err)
    );

    // ---------------- Register file -----------------
    uart_reg u_uart_reg(
        .clk                 (clk),
        .rst_n               (rst_n),
        .reg_addr            (reg_addr),
        .reg_read            (reg_read),
        .reg_write           (reg_write),
        .reg_wdata           (reg_wdata),
        .reg_rdata           (reg_rdata),
        .reg_err             (reg_err),
        .thr_valid           (thr_valid),
        .thr_ready           (thr_ready),
        .thr_data            (thr_data),
        .tx_ready            (tx_ready),
        .rhr_valid           (rhr_valid),
        .rhr_ready           (rhr_ready),
        .rhr_data            (rhr_data),
        .rhr_err             (rhr_err),
        .rx_overrun          (rx_overrun),
        .rx_fifo_err         (rx_fifo_err),
        .int_code            (int_code),
        .int_rx_line_status  (int_rx_line_status),
        .rd_rhr              (rd_rhr),
        .cfg_word_len        (cfg_word_len),
        .cfg_stop_bit        (cfg_stop_bit),
        .cfg_parity_en       (cfg_parity_en),
        .cfg_even_parity     (cfg_even_parity),
        .cfg_force_parity    (cfg_force_parity),
        .cfg_set_break       (cfg_set_break),
        .cfg_fifo_enable     (cfg_fifo_enable),
        .cfg_rx_reset        (cfg_rx_reset),
        .cfg_tx_reset        (cfg_tx_reset),
        .cfg_fifo_trig       (cfg_fifo_trig),
        .cfg_div_const       (cfg_div_const),
        .cfg_int_en          (cfg_int_en)
    );

    // ---------------------- TX ----------------------
    uart_tx u_tx(
        .clk               (clk),
        .rst_n             (rst_n),
        .tx                (tx),
        .div_clk_en        (div_clk_en),
        .tx_valid          (tx_valid),
        .tx_ready          (tx_ready),
        .tx_data           (tx_data),
        .cfg_word_len      (cfg_word_len),
        .cfg_stop_bit      (cfg_stop_bit),
        .cfg_parity_en     (cfg_parity_en),
        .cfg_even_parity   (cfg_even_parity),
        .cfg_force_parity  (cfg_force_parity),
        .cfg_set_break     (cfg_set_break)
    );

    // ------------------- TX FIFO --------------------
    uart_tx_fifo u_tx_fifo(
        .clk              (clk),
        .rst_n            (rst_n),
        .thr_valid        (thr_valid),
        .thr_ready        (thr_ready),
        .thr_data         (thr_data),
        .tx_valid         (tx_valid),
        .tx_ready         (tx_ready),
        .tx_data          (tx_data),
        .cfg_fifo_enable  (cfg_fifo_enable),
        .cfg_tx_reset     (cfg_tx_reset)
    );

    // ---------------------- RX ----------------------
    uart_rx u_rx(
        .clk               (clk),
        .rst_n             (rst_n),
        .rx                (rx),
        .div_clk_en        (div_clk_en),
        .rx_valid          (rx_valid),
        .rx_data           (rx_data),
        .rx_err            (rx_err),
        .cfg_word_len      (cfg_word_len),
        .cfg_parity_en     (cfg_parity_en),
        .cfg_even_parity   (cfg_even_parity),
        .cfg_force_parity  (cfg_force_parity)
    );

    // ------------------- RX FIFO --------------------
    uart_rx_fifo u_rx_fifo(
        .clk                (clk),
        .rst_n              (rst_n),
        .rx_valid           (rx_valid),
        .rx_data            (rx_data),
        .rx_err             (rx_err),
        .rhr_valid          (rhr_valid),
        .rhr_ready          (rhr_ready),
        .rhr_data           (rhr_data),
        .rhr_err            (rhr_err),
        .cfg_fifo_enable    (cfg_fifo_enable),
        .cfg_rx_reset       (cfg_rx_reset),
        .cfg_fifo_trig      (cfg_fifo_trig),
        .rx_overrun         (rx_overrun),
        .rx_fifo_err        (rx_fifo_err),
        .int_rx_data_ready  (int_rx_data_ready)
    );

    // --------------- Clock generator ----------------
    uart_clock_gen u_clock_gen(
        .clk            (clk),
        .rst_n          (rst_n),
        .div_clk_en     (div_clk_en),
        .cfg_div_const  (cfg_div_const)
    );

    // ------------- Interrupt controller -------------
    uart_intc u_intc(
        .int_rx_line_status  (int_rx_line_status),
        .int_rx_data_ready   (int_rx_data_ready),
        .int_rx_timeout      (int_rx_timeout),
        .int_tx_fifo_empty   (int_tx_fifo_empty),
        .int_code            (int_code),
        .uart_int            (uart_int),
        .cfg_int_en          (cfg_int_en)
    );

    assign int_tx_fifo_empty = ~tx_valid;

    // ------------------- RX timer -------------------
    uart_rx_timer u_rx_timer(
        .clk              (clk),
        .rst_n            (rst_n),
        .div_clk_en       (div_clk_en),
        .rx_valid         (rx_valid),
        .rhr_valid        (rhr_valid),
        .rd_rhr           (rd_rhr),
        .int_rx_timeout   (int_rx_timeout),
        .cfg_word_len     (cfg_word_len),
        .cfg_stop_bit     (cfg_stop_bit),
        .cfg_parity_en    (cfg_parity_en),
        .cfg_fifo_enable  (cfg_fifo_enable)
    );

endmodule
