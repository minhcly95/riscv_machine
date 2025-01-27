module uart_clock_gen(
    input  logic         clk,
    input  logic         rst_n,
    // Divided clock (16 * baud rate)
    output logic         div_clk_en,
    // Configurations
    input  logic [15:0]  cfg_div_const
);

    // We reset the count to (div_const - 1) every cycle
    // and let it count down to 0 to trigger another reset.
    settable_counter #(
        .WIDTH      (16),
        .START      (0),
        .END        (0),
        .STRIDE     (-1)
    ) u_counter(
        .clk        (clk),
        .rst_n      (rst_n),
        .srst       (1'b0),
        .en         (1'b1),
        .count      (),
        .last       (div_clk_en),
        .set_valid  (div_clk_en),
        .set_value  (cfg_div_const - 1'b1)
    );

endmodule
