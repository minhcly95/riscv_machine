module uart_rx_fifo(
    input  logic                  clk,
    input  logic                  rst_n,
    // Push port
    input  logic                  rx_valid,
    input  logic [7:0]            rx_data,
    input  uart_pkg::rx_err_s     rx_err,
    // Pop port
    output logic                  rhr_valid,
    input  logic                  rhr_ready,
    output logic [7:0]            rhr_data,
    output uart_pkg::rx_err_s     rhr_err,
    // Configurations
    input  logic                  cfg_fifo_enable,
    input  logic                  cfg_rx_reset,
    input  uart_pkg::fifo_trig_e  cfg_fifo_trig,
    // Status
    output logic                  rx_overrun,
    output logic                  rx_fifo_err,
    output logic                  int_rx_data_ready
);

    import uart_pkg::*;

    logic            rx_ready;

    logic [4:0]      push_cnt;
    logic [4:0]      pop_cnt;

    logic [4:0]      fifo_length;
    logic [4:0]      trigger_level;

    rx_err_s [15:0]  mem_rx_err;

    uart_fifo #(
        .WIDTH            (8)
    ) u_fifo(
        .clk              (clk),
        .rst_n            (rst_n),
        .srst             (cfg_rx_reset),
        .push_valid       (rx_valid),
        .push_ready       (rx_ready),
        .push_data        (rx_data),
        .pop_valid        (rhr_valid),
        .pop_ready        (rhr_ready),
        .pop_data         (rhr_data),
        .push_cnt         (push_cnt),
        .pop_cnt          (pop_cnt),
        .cfg_fifo_enable  (cfg_fifo_enable)
    );

    // We don't output rx_ready since the RX assumes that
    // the FIFO always has enough space.
    // If not, then an overrun error occurs.
    assign rx_overrun = rx_valid & ~rx_ready;

    // FIFO trigger
    always_comb begin
        case (cfg_fifo_trig)
            FIFO_TRIG_1:  trigger_level = 5'd1;
            FIFO_TRIG_4:  trigger_level = 5'd4;
            FIFO_TRIG_8:  trigger_level = 5'd8;
            FIFO_TRIG_14: trigger_level = 5'd14;
        endcase
    end

    // In non-FIFO mode, fifo_length is either 0 or 16.
    // So if there's data ready, length > trigger in all fifo_trig configs.
    assign fifo_length = push_cnt - pop_cnt;
    assign int_rx_data_ready = fifo_length >= trigger_level;

    // We use another table to keep track of the errors.
    // This table will reuse the push_cnt and pop_cnt.
    // On push, it stores the errors.
    // On pop, it clears the entry to zero.
    generate for (genvar i = 0; i < 16; i++)
        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n)                                                mem_rx_err[i] <= '0;
            else if (cfg_rx_reset)                                     mem_rx_err[i] <= '0;
            else if (rx_valid  & rx_ready  & (push_cnt[3:0] == 4'(i))) mem_rx_err[i] <= rx_err;
            else if (rhr_valid & rhr_ready & (pop_cnt[3:0]  == 4'(i))) mem_rx_err[i] <= '0;
        end
    endgenerate

    assign rhr_err     = mem_rx_err[pop_cnt[3:0]];
    assign rx_fifo_err = |mem_rx_err;

endmodule
