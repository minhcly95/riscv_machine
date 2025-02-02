// This module outputs the maximum value with its corresponding payload.
// If there is a tie, the first channel with max value wins.
module max_finder #(
    parameter  CH_N  = 2,   // Number of channels
    parameter  VAL_W = 1,   // Value width
    parameter  PLD_W = 1,   // Payload width
    parameter  RECUR = 1    // Use recursive implementation
)(
    // Inputs
    input  logic [CH_N-1:0][VAL_W-1:0]  i_val,
    input  logic [CH_N-1:0][PLD_W-1:0]  i_pld,
    // Outputs
    output logic [VAL_W-1:0]            o_val,
    output logic [PLD_W-1:0]            o_pld
);

    generate
        if (RECUR) begin: g_recur
            max_finder_recur #(
                .CH_N   (CH_N),
                .VAL_W  (VAL_W),
                .PLD_W  (PLD_W)
            ) u_impl(
                .i_val  (i_val),
                .i_pld  (i_pld),
                .o_val  (o_val),
                .o_pld  (o_pld)
            );
        end
        else begin: g_seq
            max_finder_seq #(
                .CH_N   (CH_N),
                .VAL_W  (VAL_W),
                .PLD_W  (PLD_W)
            ) u_impl(
                .i_val  (i_val),
                .i_pld  (i_pld),
                .o_val  (o_val),
                .o_pld  (o_pld)
            );
        end
    endgenerate

endmodule
