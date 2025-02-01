module plic_claim_ctrl #(
    parameter  TGT_N   = 1      // Number of targets
)(
    // From Routing array
    input  logic [TGT_N-1:0][4:0]  max_src,
    // Input
    input  logic [4:0]             claim_tgt,
    // Output
    output logic [4:0]             claim_src
);

    assign claim_src = (claim_tgt < TGT_N) ? max_src[claim_tgt] : 5'b0;

endmodule
