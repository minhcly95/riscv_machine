// This module outputs the maximum value with its corresponding payload.
// If there is a tie, the first channel with max value wins.
// This is a sequential implementation of the max_finder.
module max_finder_seq #(
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

    always_comb begin
        o_val = i_val[0];
        o_pld = i_pld[0];

        for (int i = 1; i < CH_N; i++)
            if (i_val[i] > o_val) begin
                o_val = i_val[i];
                o_pld = i_pld[i];
            end
    end

endmodule
