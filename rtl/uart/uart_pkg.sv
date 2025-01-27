package uart_pkg;

    // --------------------- Enum ---------------------
    typedef enum logic [3:0] {
        INT_NONE           = 4'b0001,
        INT_RX_LINE_STATUS = 4'b0110,
        INT_RX_DATA_READY  = 4'b0100,
        INT_RX_TIMEOUT     = 4'b1100,
        INT_THR_EMPTY      = 4'b0010,
        INT_MODEM_STATUS   = 4'b0000
    } int_code_e;

    typedef enum logic [1:0] {
        WORD_LEN_5 = 2'b00,
        WORD_LEN_6 = 2'b01,
        WORD_LEN_7 = 2'b10,
        WORD_LEN_8 = 2'b11
    } word_len_e;

    typedef enum logic [1:0] {
        FIFO_TRIG_1  = 2'b00,
        FIFO_TRIG_4  = 2'b01,
        FIFO_TRIG_8  = 2'b10,
        FIFO_TRIG_14 = 2'b11
    } fifo_trig_e;

    // -------------------- Struct --------------------
    typedef struct packed {
        logic  break_int;
        logic  frame_err;
        logic  parity_err;
    } rx_err_s;

    typedef struct packed {
        logic  modem_status;
        logic  rx_line_status;
        logic  thr_empty;
        logic  rx_data_ready;
    } int_en_s;

endpackage
