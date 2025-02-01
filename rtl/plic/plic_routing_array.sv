module plic_routing_array #(
    parameter  SRC_N   = 1,     // Number of sources
    parameter  TGT_N   = 1,     // Number of targets
    parameter  PRIO_W  = 1      // Priority width
)(
    // From Gateway
    input  logic [SRC_N:0]                int_pending,
    // To Notifier
    output logic [TGT_N-1:0][PRIO_W-1:0]  max_prio,
    // To Claim controller
    output logic [TGT_N-1:0][4:0]         max_src,
    // Configurations
    input  logic [SRC_N:0][PRIO_W-1:0]    cfg_int_prio,
    input  logic [TGT_N-1:0][SRC_N:0]     cfg_int_enable
);

    genvar i;
    genvar j;

    logic [TGT_N-1:0][SRC_N:0][PRIO_W-1:0]  prio_array;
    logic [SRC_N:0][4:0]                    src_array;  // This array is shared

    // Prepare the arrays
    generate
        for (i = 0; i < SRC_N+1; i++)
            for (j = 0; j < TGT_N; j++)
                assign prio_array[j][i] = (cfg_int_enable[j][i] & int_pending[i]) ? cfg_int_prio[i] : PRIO_W'(0);
    endgenerate

    generate for (i = 0; i < SRC_N+1; i++)
        assign src_array[i] = 5'(i);
    endgenerate

    // Find the max priority and source
    generate
        for (j = 0; j < TGT_N; j++) begin: g_tgt
            max_finder #(
                .CH_N   (SRC_N+1),
                .VAL_W  (PRIO_W),
                .PLD_W  (5)
            ) u_max(
                .i_val  (prio_array[j]),
                .i_pld  (src_array),
                .o_val  (max_prio[j]),
                .o_pld  (max_src[j])
            );
        end
    endgenerate
    
endmodule
