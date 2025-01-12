module flope #(
    parameter  WIDTH   = 1
)(
    input  logic              clk,
    input  logic              en,
    input  logic [WIDTH-1:0]  d,
    output logic [WIDTH-1:0]  q
);

    always_ff @(posedge clk) begin
        if (en) q <= d;
    end

endmodule
