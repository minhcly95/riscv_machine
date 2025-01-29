module one_hot_mux #(
    parameter  CH_N  = 4,   // Number of channels
    parameter  PLD_W = 1    // Width of the payload
)(
    // Select signal (one-hot)
    input  logic [CH_N-1:0]             sel,
    // In payloads
    input  logic [CH_N-1:0][PLD_W-1:0]  in_pld,
    // Out payload
    output logic [PLD_W-1:0]            out_pld
);

    genvar i;
    genvar j;

    // Selected payload
    logic [PLD_W-1:0][CH_N-1:0]  sel_pld;

    generate
        for (i = 0; i < CH_N; i++)
            for (j = 0; j < PLD_W; j++)
                assign sel_pld[j][i] = in_pld[i][j] & sel[i];
    endgenerate

    // Reduce each bit
    generate for (j = 0; j < PLD_W; j++)
        assign out_pld[j] = |sel_pld[j];
    endgenerate

endmodule
