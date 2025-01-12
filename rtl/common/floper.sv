module floper #(
    parameter  WIDTH   = 1,
    parameter  RST_VAL = WIDTH'(0)
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              en,
    input  logic [WIDTH-1:0]  d,
    output logic [WIDTH-1:0]  q
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)  q <= RST_VAL;
        else if (en) q <= d;
    end

endmodule
