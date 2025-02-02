// This module outputs the maximum value with its corresponding payload.
// If there is a tie, the first channel with max value wins.
// This is a recursive implementation of the max_finder.
module max_finder_recur #(
    parameter  CH_N  = 2,   // Number of channels
    parameter  VAL_W = 1,   // Value width
    parameter  PLD_W = 1    // Payload width
)(
    // Inputs
    input  logic [CH_N-1:0][VAL_W-1:0]  i_val,
    input  logic [CH_N-1:0][PLD_W-1:0]  i_pld,
    // Outputs
    output logic [VAL_W-1:0]            o_val,
    output logic [PLD_W-1:0]            o_pld
);

    localparam HI_N = CH_N / 2;
    localparam LO_N = CH_N - HI_N;

    generate
        if (CH_N == 1) begin : g_single
            // Single channel, just output directly
            assign o_val = i_val;
            assign o_pld = i_pld;
        end
        else begin : g_multi

            logic [VAL_W-1:0]  lo_val;
            logic [VAL_W-1:0]  hi_val;

            logic [PLD_W-1:0]  lo_pld;
            logic [PLD_W-1:0]  hi_pld;

            // Recursively find max of 2 halves
            max_finder_recur #(
                .CH_N   (LO_N),
                .VAL_W  (VAL_W),
                .PLD_W  (PLD_W)
            ) u_lo(
                .i_val  (i_val[LO_N-1:0]),
                .i_pld  (i_pld[LO_N-1:0]),
                .o_val  (lo_val),
                .o_pld  (lo_pld)
            );

            max_finder_recur #(
                .CH_N   (HI_N),
                .VAL_W  (VAL_W),
                .PLD_W  (PLD_W)
            ) u_hi(
                .i_val  (i_val[CH_N-1:LO_N]),
                .i_pld  (i_pld[CH_N-1:LO_N]),
                .o_val  (hi_val),
                .o_pld  (hi_pld)
            );

            // Combine the results
            always_comb begin
                if (lo_val >= hi_val) begin
                    o_val = lo_val;
                    o_pld = lo_pld;
                end
                else begin
                    o_val = hi_val;
                    o_pld = hi_pld;
                end
            end

        end
    endgenerate

endmodule
