module uart_intc(
    // Interrupt sources
    input  logic                 int_rx_line_status,
    input  logic                 int_rx_data_ready,
    input  logic                 int_rx_timeout,
    input  logic                 int_tx_fifo_empty,
    // Interrupt output
    output uart_pkg::int_code_e  int_code,
    output logic                 uart_int,
    // Configurations
    input  uart_pkg::int_en_s    cfg_int_en
);

    import uart_pkg::*;

    logic final_rx_line_status = int_rx_line_status & cfg_int_en.rx_line_status;
    logic final_rx_data_ready  = int_rx_data_ready  & cfg_int_en.rx_data_ready;
    logic final_rx_timeout     = int_rx_timeout     & cfg_int_en.rx_data_ready;
    logic final_tx_fifo_empty  = int_tx_fifo_empty  & cfg_int_en.thr_empty;

    always_comb begin
        if (final_rx_line_status)     int_code = INT_RX_LINE_STATUS;
        else if (final_rx_data_ready) int_code = INT_RX_DATA_READY;
        else if (final_rx_timeout)    int_code = INT_RX_TIMEOUT;
        else if (final_tx_fifo_empty) int_code = INT_THR_EMPTY;
        else                          int_code = INT_NONE;
    end

    assign uart_int = |{
        final_rx_line_status,
        final_rx_data_ready,
        final_rx_timeout,
        final_tx_fifo_empty
    };

endmodule
