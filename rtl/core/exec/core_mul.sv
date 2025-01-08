module core_mul (
    // Op select
    input  core_pkg::mul_op_e    mul_op,
    // Input
    input  logic [31:0]          src_a,
    input  logic [31:0]          src_b,
    // Output
    output logic [31:0]          mul_result
);

    import core_pkg::*;

    logic a_signed;
    logic b_signed;

    // We decompose a = {i, m} and b = {j, n}
    // i and j are 1-bit, m and n are 31-bit
    logic        i;
    logic [30:0] m;
    logic        j;
    logic [30:0] n;

    logic [1:0]  ij_prod;
    logic [32:0] in_prod;
    logic [32:0] jm_prod;
    logic [63:0] mn_prod;
    logic [63:0] full_prod;

    // Decompose the multiplicands
    assign {i, m} = src_a;
    assign {j, n} = src_b;

    // Multiply the components
    assign ij_prod = {1'b0, i & j};
    assign in_prod = {2'b0, {31{i}} & n};
    assign jm_prod = {2'b0, {31{j}} & m};
    assign mn_prod = m * n;

    // For signed multiplicands, we flip the signs of the products
    // related to the corresponding sign bits.
    assign full_prod =
        mn_prod +
        {(a_signed            ? -in_prod : in_prod), 31'b0} +
        {(b_signed            ? -jm_prod : jm_prod), 31'b0} +
        {(a_signed ^ b_signed ? -ij_prod : ij_prod), 62'b0};

    // Decode mul_op
    always_comb begin
        case (mul_op)
            MUL_MUL: begin
                a_signed   = 1'b0;
                b_signed   = 1'b0;
                mul_result = full_prod[31:0];
            end
            MUL_MULH: begin
                a_signed   = 1'b1;
                b_signed   = 1'b1;
                mul_result = full_prod[63:32];
            end
            MUL_MULHSU: begin
                a_signed   = 1'b1;
                b_signed   = 1'b0;
                mul_result = full_prod[63:32];
            end
            MUL_MULHU: begin
                a_signed   = 1'b0;
                b_signed   = 1'b0;
                mul_result = full_prod[63:32];
            end
        endcase
    end

endmodule
