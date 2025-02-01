module plic_notifier #(
    parameter  PRIO_W = 1       // Priority width
)(
    // From Routing array
    input  logic [PRIO_W-1:0]  max_prio,
    // To Interrupt target
    output logic               int_tgt,
    // Configurations
    input  logic [PRIO_W-1:0]  cfg_threshold
);

    assign int_tgt = (max_prio > cfg_threshold);

endmodule
