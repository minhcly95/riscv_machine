module uart_tx(
    input  logic                 clk,
    input  logic                 rst_n,
    // Serial output
    output logic                 tx,
    // Divided clock (16 * baud rate)
    input  logic                 div_clk_en,
    // Input
    input  logic                 tx_valid,
    output logic                 tx_ready,
    input  logic [7:0]           tx_data,
    // Configurations
    input  uart_pkg::word_len_e  cfg_word_len,
    input  logic                 cfg_stop_bit,
    input  logic                 cfg_parity_en,
    input  logic                 cfg_even_parity,
    input  logic                 cfg_force_parity,
    input  logic                 cfg_set_break
);

    import uart_pkg::*;

    // State definition
    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP_1,
        STOP_2
    } state_e;

    // State machine
    state_e     curr_state;
    state_e     next_state;

    // Start condition
    logic       start_frame;

    // Output bits
    logic       data_bit;
    logic       parity_bit;

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

    // ---------------- State machine -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) curr_state <= IDLE;
        else        curr_state <= next_state;
    end

    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE:    if (tx_valid)                      next_state = START;
            START:   if (uart_clk_en)                   next_state = DATA;
            DATA:    if (uart_clk_en & data_count_last) next_state = cfg_parity_en ? PARITY : STOP_1;
            PARITY:  if (uart_clk_en)                   next_state = STOP_1;
            STOP_1:  if (uart_clk_en)                   next_state = cfg_stop_bit ? STOP_2 : IDLE;
            STOP_2:  if (uart_clk_en)                   next_state = IDLE;
            default:                                    next_state = IDLE;
        endcase
    end

    always_comb begin
        tx_ready     = 1'b0;
        start_frame  = 1'b0;
        shift_reg_en = 1'b0;
        case (curr_state)
            IDLE: begin
                tx_ready       = 1'b1;
                start_frame    = tx_valid;
            end
            DATA: shift_reg_en = uart_clk_en;
            default: ;
        endcase
    end

    // ------------------ TX output -------------------
    always_comb begin
        if (cfg_set_break) tx = 1'b0;
        else begin
            case (curr_state)
                IDLE:      tx = 1'b1;
                START:     tx = 1'b0;
                DATA:      tx = data_bit;
                PARITY:    tx = parity_bit;
                STOP_1:    tx = 1'b1;
                STOP_2:    tx = 1'b1;
                default:   tx = 1'b1;
            endcase
        end
    end

    // -------------- UART clock control --------------
    always_comb begin
        case (curr_state)
            START,
            DATA,
            PARITY,
            STOP_1,
            STOP_2:  uart_clk_count_en = 1'b1;
            default: uart_clk_count_en = 1'b0;
        endcase
    end

    static_counter #(
        .WIDTH   (4),
        .END     (15)
    ) u_uart_clk_counter(
        .clk     (clk),
        .rst_n   (rst_n),
        .srst    (1'b0),
        .en      (div_clk_en & uart_clk_count_en),
        .count   (),
        .last    (uart_clk_last)
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
        if (start_frame)       shift_reg <= tx_data;
        else if (shift_reg_en) shift_reg <= {1'b0, shift_reg[7:1]};
    end

    assign data_bit = shift_reg[0];

    // -------------- Parity calculation --------------
    always_ff @(posedge clk) begin
        if (start_frame)       parity_acc <= ~cfg_even_parity;
        else if (shift_reg_en) parity_acc <= parity_acc ^ data_bit;
    end

    always_comb begin
        if (cfg_force_parity)
            parity_bit = ~cfg_even_parity;
        else
            parity_bit = parity_acc;
    end

endmodule
