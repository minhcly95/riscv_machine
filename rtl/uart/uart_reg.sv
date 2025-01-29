module uart_reg(
    input  logic                  clk,
    input  logic                  rst_n,
    // APB access
    input  logic [2:0]            reg_addr,
    input  logic                  reg_read,
    input  logic                  reg_write,
    input  logic [7:0]            reg_wdata,
    output logic [7:0]            reg_rdata,
    output logic                  reg_err,
    // TX FIFO
    output logic                  thr_valid,
    input  logic                  thr_ready,
    output logic [7:0]            thr_data,
    input  logic                  tx_ready,
    // RX FIFO
    input  logic                  rhr_valid,
    output logic                  rhr_ready,
    input  logic [7:0]            rhr_data,
    input  uart_pkg::rx_err_s     rhr_err,
    input  logic                  rx_overrun,
    input  logic                  rx_fifo_err,
    // INTC
    input  uart_pkg::int_code_e   int_code,
    output logic                  int_rx_line_status,
    // RX Timer
    output logic                  rd_rhr,   // Assert when RHR is read
    // Configurations
    output uart_pkg::word_len_e   cfg_word_len,
    output logic                  cfg_stop_bit,
    output logic                  cfg_parity_en,
    output logic                  cfg_even_parity,
    output logic                  cfg_force_parity,
    output logic                  cfg_set_break,
    output logic                  cfg_fifo_enable,
    output logic                  cfg_rx_reset,
    output logic                  cfg_tx_reset,
    output uart_pkg::fifo_trig_e  cfg_fifo_trig,
    output logic [15:0]           cfg_div_const,
    output uart_pkg::int_en_s     cfg_int_en,
    output logic                  cfg_loopback
);

    import uart_pkg::*;

    // Interrupt enable
    int_en_s     ier_value;

    // FIFO control
    logic        fcr_fifo_enable;
    fifo_trig_e  fcr_fifo_trig;

    // Line control
    word_len_e   lcr_word_len;
    logic        lcr_stop_bit;
    logic        lcr_parity_en;
    logic        lcr_even_parity;
    logic        lcr_force_parity;
    logic        lcr_set_break;
    logic        lcr_dlab;

    // Modem control
    logic        mcr_dtr;
    logic        mcr_rts;
    logic        mcr_out1;
    logic        mcr_out2;
    logic        mcr_loopback;

    // Line status
    logic        lsr_overrun_err;
    rx_err_s     lsr_rx_err;
    logic        lsr_cleared;

    // Scratchpad
    logic [7:0]  spr_value;

    // Divisor latch
    logic [7:0]  dll_value;
    logic [7:0]  dlm_value;

    // Decoding logic
    logic        wr_thr;
    logic        wr_ier;
    logic        wr_fcr;
    logic        wr_lcr;
    logic        wr_mcr;
    logic        rd_lcs;
    logic        wr_spr;
    logic        wr_dll;
    logic        wr_dlm;

    // ------------------- Decoder --------------------
    always_comb begin
        rd_rhr  = 1'b0;
        wr_thr  = 1'b0;
        wr_ier  = 1'b0;
        wr_fcr  = 1'b0;
        wr_lcr  = 1'b0;
        wr_mcr  = 1'b0;
        rd_lcs  = 1'b0;
        wr_spr  = 1'b0;
        wr_dll  = 1'b0;
        wr_dlm  = 1'b0;
        reg_err = 1'b0;

        case (reg_addr)
            3'd0: begin
                rd_rhr  = reg_read  & ~lcr_dlab;
                wr_thr  = reg_write & ~lcr_dlab;
                wr_dll  = reg_write &  lcr_dlab;
            end
            3'd1: begin
                wr_ier  = reg_write & ~lcr_dlab;
                wr_dlm  = reg_write &  lcr_dlab;
            end
            3'd2: begin
                wr_fcr  = reg_write;
            end
            3'd3: begin
                wr_lcr  = reg_write;
            end
            3'd4: begin
                wr_mcr  = reg_write;
            end
            3'd5: begin
                rd_lcs  = reg_read;
                reg_err = reg_write;    // Reg 5 is read-only
            end
            3'd6: begin
                reg_err = reg_write;    // Reg 6 is read-only
            end
            3'd7: begin
                wr_spr  = reg_write;
            end
        endcase
    end

    // ------------------ Read data -------------------
    always_comb begin
        case (reg_addr)
            3'd0: begin
                if (lcr_dlab) reg_rdata = dll_value;
                else          reg_rdata = rhr_valid ? rhr_data : 8'd0;  // Mask RHR if no data
            end
            3'd1: begin
                if (lcr_dlab) reg_rdata = dlm_value;
                else          reg_rdata = {4'b0, ier_value};
            end
            3'd2: reg_rdata = {fcr_fifo_enable, fcr_fifo_enable, 2'b0, int_code};
            3'd3: reg_rdata = {lcr_dlab, lcr_set_break, lcr_force_parity, lcr_even_parity, lcr_parity_en, lcr_stop_bit, lcr_word_len};
            3'd4: reg_rdata = {3'b0, mcr_loopback, mcr_out2, mcr_out1, mcr_rts, mcr_dtr};
            3'd5: reg_rdata = {rx_fifo_err & fcr_fifo_enable, thr_ready & tx_ready, thr_ready, lsr_rx_err, lsr_overrun_err, rhr_valid};
            3'd6: reg_rdata = 8'd0;
            3'd7: reg_rdata = spr_value;
        endcase
    end

    // ---------------- Read actions ------------------
    // Pop RHR on read
    assign rhr_ready = rd_rhr;

    // Clear LSR on read
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)          lsr_overrun_err <= 1'b0;
        else if (rx_overrun) lsr_overrun_err <= 1'b1;
        else if (rd_lcs)     lsr_overrun_err <= 1'b0;
    end

    // Clear LSR on read and update on RHR read
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                     lsr_cleared <= 1'b0;
        else if (rhr_valid & rhr_ready) lsr_cleared <= 1'b0;
        else if (rd_lcs)                lsr_cleared <= 1'b1;
    end

    assign lsr_rx_err         = lsr_cleared ? '0 : rhr_err;
    assign int_rx_line_status = |{lsr_rx_err, lsr_overrun_err};

    // ---------------- Write actions -----------------
    // Push THR on write (ignore thr_ready)
    assign thr_valid = wr_thr;
    assign thr_data  = reg_wdata;

    // Store IER
    floper #(
        .WIDTH    (4),
        .RST_VAL  (4'b0000)
    ) u_ier_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_ier),
        .d        (reg_wdata[3:0]),
        .q        (ier_value)
    );
    
    // Store FCR and reset
    floper #(
        .WIDTH    (3),
        .RST_VAL  (3'b000)
    ) u_fcr_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_fcr),
        .d        ({reg_wdata[7:6], reg_wdata[0]}),
        .q        ({fcr_fifo_trig, fcr_fifo_enable})
    );

    assign cfg_rx_reset = wr_fcr & reg_wdata[1];
    assign cfg_tx_reset = wr_fcr & reg_wdata[2];

    // Store LCR
    floper #(
        .WIDTH    (8),
        .RST_VAL  (8'b00000011)
    ) u_lcr_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_lcr),
        .d        (reg_wdata),
        .q        ({lcr_dlab, lcr_set_break, lcr_force_parity, lcr_even_parity, lcr_parity_en, lcr_stop_bit, lcr_word_len})
    );

    // Store MCR
    floper #(
        .WIDTH    (5),
        .RST_VAL  (5'b00000)
    ) u_mcr_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_mcr),
        .d        (reg_wdata[4:0]),
        .q        ({mcr_loopback, mcr_out2, mcr_out1, mcr_rts, mcr_dtr})
    );

    // Store SPR
    floper #(
        .WIDTH    (8),
        .RST_VAL  (8'd0)
    ) u_spr_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_spr),
        .d        (reg_wdata),
        .q        (spr_value)
    );

    // Store DLL
    floper #(
        .WIDTH    (8),
        .RST_VAL  (8'd1)
    ) u_dll_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_dll),
        .d        (reg_wdata),
        .q        (dll_value)
    );

    // Store DLM
    floper #(
        .WIDTH    (8),
        .RST_VAL  (8'd0)
    ) u_dlm_flop(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_dlm),
        .d        (reg_wdata),
        .q        (dlm_value)
    );

    // ---------------- Output wiring -----------------
    assign cfg_word_len     = lcr_word_len;
    assign cfg_stop_bit     = lcr_stop_bit;
    assign cfg_parity_en    = lcr_parity_en;
    assign cfg_even_parity  = lcr_even_parity;
    assign cfg_force_parity = lcr_force_parity;
    assign cfg_set_break    = lcr_set_break;
    assign cfg_fifo_enable  = fcr_fifo_enable;
    assign cfg_fifo_trig    = fcr_fifo_trig;
    assign cfg_div_const    = {dlm_value, dll_value};
    assign cfg_int_en       = ier_value;
    assign cfg_loopback     = mcr_loopback;

endmodule
