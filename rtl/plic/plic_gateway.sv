module plic_gateway #(
    parameter  SRC_ID  = 1      // Source ID of this gateway
)(
    input  logic        clk,
    input  logic        rst_n,
    // Interrupt source
    input  logic        int_src,
    // Interrupt pending status
    output logic        int_pending,
    // Claim interface
    input  logic        claim_valid,
    input  logic [4:0]  claim_src,
    input  logic [4:0]  claim_tgt,
    // Complete interface
    input  logic        complete_valid,
    input  logic [4:0]  complete_src,
    input  logic [4:0]  complete_tgt
);

    logic        claim_match;
    logic        complete_match;

    logic        claimed;
    logic [4:0]  claimed_tgt;

    // Claim/Complete conditions
    assign claim_match    = claim_valid    & (claim_src    == 5'(SRC_ID));
    assign complete_match = complete_valid & (complete_src == 5'(SRC_ID)) & (complete_tgt == claimed_tgt);

    // Claim/Complete status
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)              claimed <= 1'b0;
        else if (claim_match)    claimed <= 1'b1;
        else if (complete_match) claimed <= 1'b0;
    end

    // Store claim_tgt to compare to complete_tgt later
    always_ff @(posedge clk) begin
        if (claim_match) claimed_tgt <= claim_tgt;
    end

    // Interrupt is pending only when unclaimed
    assign int_pending = int_src & ~claimed;

endmodule
