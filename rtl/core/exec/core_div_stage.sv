// A stage of the restoring division algorithm.
// We assume a >= 0 and b >= 0.
// If a - b >= 0, then r = a - b and q = 1. Otherwise, r = a and q = 0.
module core_div_stage (
    input  logic [31:0]  a,
    input  logic [31:0]  b,
    output logic [31:0]  r,
    output logic         q
);

    logic [32:0] diff;

    assign diff = {1'b0, a} - b;
    assign q    = ~diff[32];
    assign r    = q ? diff[31:0] : a;

endmodule
