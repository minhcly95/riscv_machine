module static_counter #(
    parameter  WIDTH  = 8,
    parameter  START  = 0,
    parameter  END    = 2**WIDTH - 1,
    parameter  STRIDE = 1
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              en,
    output logic [WIDTH-1:0]  count,
    output logic              last
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)   count <= START;
        else if (en) begin
            if (last) count <= START;
            else      count <= count + STRIDE;
        end
    end

    assign last = (count == END);

endmodule
