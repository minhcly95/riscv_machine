module uart_loopback(
    // Inward interface
    input  logic  in_tx,
    output logic  in_rx,
    // Outward interface
    output logic  out_tx,
    input  logic  out_rx,
    // Configurations
    input  logic  cfg_loopback
);

    always_comb begin
        if (cfg_loopback) begin
            in_rx  = in_tx;
            out_tx = 1'b1;
        end
        else begin
            in_rx  = out_rx;
            out_tx = in_tx;
        end
    end

endmodule
