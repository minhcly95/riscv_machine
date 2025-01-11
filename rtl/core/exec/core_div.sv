module core_div (
    // Op select
    input  core_pkg::div_op_e    div_op,
    // Input
    input  logic [31:0]          src_a,
    input  logic [31:0]          src_b,
    // Output
    output logic [31:0]          div_result
);

    import core_pkg::*;

    genvar i;

    logic         sign_op;
    logic         sign_a;
    logic         sign_b;

    logic [31:0]  pos_a;
    logic [31:0]  pos_b;
    logic [31:0]  pos_q;
    logic [31:0]  pos_r;

    logic [31:0]  stage_a [32];
    logic [31:0]  stage_r [32];
    logic [31:0]  q;
    logic [31:0]  r;

    // Decode div_op
    always_comb begin
        case (div_op)
            DIV_DIV: begin
                sign_op    = 1'b1;
                div_result = q;
            end
            DIV_DIVU: begin
                sign_op    = 1'b0;
                div_result = q;
            end
            DIV_REM: begin
                sign_op    = 1'b1;
                div_result = r;
            end
            DIV_REMU: begin
                sign_op    = 1'b0;
                div_result = r;
            end
        endcase
    end

    // We make sure the inputs of the array divider are positive.
    // Then, we adjust the signs of the outputs accordingly.
    assign sign_a = sign_op & src_a[31];
    assign sign_b = sign_op & src_b[31];

    assign pos_a = sign_a ? (-src_a) : src_a;
    assign pos_b = sign_b ? (-src_b) : src_b;

    assign q = ((sign_a ^ sign_b) & (|src_b)) ? (-pos_q) : pos_q;
    assign r = sign_a ? (-pos_r) : pos_r;

    // First a is the MSbit of pos_a
    assign stage_a[0] = {31'b0, pos_a[31]};

    // Array divider
    generate for (i = 0; i < 32; i++)
        core_div_stage u_div_stage(
            .a  (stage_a[i]),
            .b  (pos_b),
            .r  (stage_r[i]),
            .q  (pos_q[31-i])
        );
    endgenerate

    // Shift left and append the next digit for each stage
    generate for (i = 1; i < 32; i++)
        assign stage_a[i] = {stage_r[i-1][30:0], pos_a[31-i]};
    endgenerate

    // Last r is the remainder
    assign pos_r = stage_r[31];

endmodule
