module uart_rx_timer(
    input  logic                 clk,
    input  logic                 rst_n,
    // Divided clock (16 * baud rate)
    input  logic                 div_clk_en,
    // Inputs
    input  logic                 rx_valid,
    input  logic                 rhr_valid,
    input  logic                 rd_rhr,
    // Interrupt
    output logic                 int_rx_timeout,
    // Configurations
    input  uart_pkg::word_len_e  cfg_word_len,
    input  logic                 cfg_stop_bit,
    input  logic                 cfg_parity_en,
    input  logic                 cfg_fifo_enable
);

    import uart_pkg::*;

    logic [3:0] data_len;
    logic [3:0] frame_len;
    
    // Length calculation
    always_comb begin
        case (cfg_word_len)
            WORD_LEN_5: data_len = 4'd5;
            WORD_LEN_6: data_len = 4'd6;
            WORD_LEN_7: data_len = 4'd7;
            WORD_LEN_8: data_len = 4'd8;
        endcase
    end

    assign frame_len = 4'd2 + data_len + 4'(cfg_stop_bit) + 4'(cfg_parity_en);

    // Counter: counts every div_clk, resets on rx_valid or rd_rhr.
    // Only enabled in FIFO-mode and FIFO is not empty.
    settable_counter #(
        .WIDTH      (10),
        .START      (768),  // Max time = 4 frame * 12 char/frame * 16 clk/char
        .END        (0),
        .STRIDE     (-1)
    ) u_counter(
        .clk        (clk),
        .rst_n      (rst_n),
        .srst       (~cfg_fifo_enable),
        .en         (div_clk_en),
        .count      (),
        .last       (int_rx_timeout),
        .set_valid  (rx_valid | rd_rhr | ~rhr_valid),
        .set_value  ({frame_len, 6'b0})  // 4 frame * frame_len * 16 clk/char
    );

endmodule
