module uart_rx(
    input  logic                 clk,
    input  logic                 rst_n,
    // Serial input
    input  logic                 rx,
    // Divided clock (16 * baud rate)
    input  logic                 div_clk_en,
    // Output
    output logic                 rx_valid,
    output logic [7:0]           rx_data,
    output uart_pkg::rx_err_s    rx_err,
    // Configurations
    input  uart_pkg::word_len_e  cfg_word_len,
    input  logic                 cfg_parity_en,
    input  logic                 cfg_even_parity,
    input  logic                 cfg_force_parity
);

    import uart_pkg::*;

    // State definition
    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP
    } state_e;

    // State machine
    state_e     curr_state;
    state_e     next_state;

    // Start condition
    logic       falling_edge;
    logic       start_frame;

    // Clock counter (uart_clk freq = div_clk freq / 16)
    logic       uart_clk_count_en;
    logic       uart_clk_last;
    logic       uart_clk_en;

    // Data phase helper
    logic [2:0] data_len;
    logic       data_count_last;

    // Shift register
    logic [7:0] shift_reg;
    logic       shift_reg_en;

    // Parity accumulator
    logic       parity_acc;
    logic       parity_en;
    logic       parity_err;

    // Break condition
    logic       all_zeros;

    // ---------------- State machine -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) curr_state <= IDLE;
        else        curr_state <= next_state;
    end

    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE:    if (falling_edge)                  next_state = START;
            START:   if (uart_clk_en)                   next_state = rx ? IDLE : DATA;
            DATA:    if (uart_clk_en & data_count_last) next_state = cfg_parity_en ? PARITY : STOP;
            PARITY:  if (uart_clk_en)                   next_state = STOP;
            STOP:    if (uart_clk_en)                   next_state = IDLE;
            default:                                    next_state = IDLE;
        endcase
    end

    always_comb begin
        rx_valid          = 1'b0;
        start_frame       = 1'b0;
        shift_reg_en      = 1'b0;
        parity_en         = 1'b0;
        case (curr_state)
            IDLE:   start_frame  = falling_edge;
            DATA:   shift_reg_en = uart_clk_en;
            PARITY: parity_en    = uart_clk_en;
            STOP:   rx_valid     = uart_clk_en;
            default: ;
        endcase
    end

    // ---------------- Start condition ---------------
    negedge_filter u_rx_negedge_filter(
        .clk    (clk),
        .rst_n  (rst_n),
        .data   (rx),
        .ne     (falling_edge)
    );

    // -------------- UART clock control --------------
    always_comb begin
        case (curr_state)
            START,
            DATA,
            PARITY,
            STOP:    uart_clk_count_en = 1'b1;
            default: uart_clk_count_en = 1'b0;
        endcase
    end

    // We set the first count to 7 to align the sample time
    // at the center of a bit.
    settable_counter #(
        .WIDTH      (4),
        .START      (15),
        .END        (0),
        .STRIDE     (-1),
        .WRAP       (1)
    ) u_uart_clk_counter(
        .clk        (clk),
        .rst_n      (rst_n),
        .srst       (1'b0),
        .en         (div_clk_en & uart_clk_count_en),
        .count      (),
        .last       (uart_clk_last),
        .set_valid  (start_frame),
        .set_value  (4'd7)
    );

    assign uart_clk_en = div_clk_en & uart_clk_last;

    // ----------------- Data counter -----------------
    always_comb begin
        case (cfg_word_len)
            WORD_LEN_5: data_len = 3'd4;
            WORD_LEN_6: data_len = 3'd5;
            WORD_LEN_7: data_len = 3'd6;
            WORD_LEN_8: data_len = 3'd7;
        endcase
    end

    settable_counter #(
        .WIDTH      (3),
        .START      (7),
        .END        (0),
        .STRIDE     (-1)
    ) u_data_counter(
        .clk        (clk),
        .rst_n      (rst_n),
        .srst       (1'b0),
        .en         (shift_reg_en),
        .count      (),
        .last       (data_count_last),
        .set_valid  (start_frame),
        .set_value  (data_len)
    );

    // ---------------- Shift register ----------------
    always_ff @(posedge clk) begin
        if (start_frame)       shift_reg <= 8'd0;
        else if (shift_reg_en) shift_reg <= {rx, shift_reg[7:1]};
    end

    // ------------------ Data output -----------------
    always_comb begin
        case (cfg_word_len)
            WORD_LEN_5: rx_data = {3'd0, shift_reg[7:3]};
            WORD_LEN_6: rx_data = {2'd0, shift_reg[7:2]};
            WORD_LEN_7: rx_data = {1'd0, shift_reg[7:1]};
            WORD_LEN_8: rx_data = shift_reg;
        endcase
    end

    // -------------- Parity calculation --------------
    always_ff @(posedge clk) begin
        if (start_frame)       parity_acc <= ~cfg_even_parity;
        else if (shift_reg_en) parity_acc <= parity_acc ^ rx;
    end

    always_ff @(posedge clk) begin
        if (start_frame)
            parity_err <= 1'b0;
        else if (cfg_parity_en & parity_en) begin
            if (cfg_force_parity)
                parity_err <= (rx == cfg_even_parity);
            else
                parity_err <= (rx == parity_acc);
        end
    end

    assign rx_err.parity_err = parity_err;

    // ----------------- Frame error ------------------
    // All the rx_* signals are returned when rx_valid = 1,
    // which happens when the stop bit is sampled.
    // Thus, we can return the stop bit directly
    // without storing it in a flop.
    assign rx_err.frame_err = ~rx;

    // --------------- Break condition ----------------
    always_ff @(posedge clk) begin
        if (start_frame)      all_zeros <= 1'b1;
        else if (uart_clk_en) all_zeros <= all_zeros & ~rx;
    end

    // We need to and ~rx for the stop bit
    // since rx_valid = 1 right at the stop bit.
    assign rx_err.break_int = all_zeros & ~rx;

endmodule
