module uart_tx_fifo(
    input  logic        clk,
    input  logic        rst_n,
    // Push port
    input  logic        thr_valid,
    output logic        thr_ready,
    input  logic [7:0]  thr_data,
    // Pop port
    output logic        tx_valid,
    input  logic        tx_ready,
    output logic [7:0]  tx_data,
    // Configurations
    input  logic        cfg_fifo_enable,
    input  logic        cfg_tx_reset
);

    uart_fifo #(
        .WIDTH            (8)
    ) u_fifo(
        .clk              (clk),
        .rst_n            (rst_n),
        .srst             (cfg_tx_reset),
        .push_valid       (thr_valid),
        .push_ready       (thr_ready),
        .push_data        (thr_data),
        .pop_valid        (tx_valid),
        .pop_ready        (tx_ready),
        .pop_data         (tx_data),
        .push_cnt         (),
        .pop_cnt          (),
        .cfg_fifo_enable  (cfg_fifo_enable)
    );

endmodule
