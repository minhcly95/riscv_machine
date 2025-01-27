module settable_counter #(
    parameter  WIDTH  = 8,
    parameter  START  = 0,
    parameter  END    = 2**WIDTH - 1,
    parameter  STRIDE = 1,
    parameter  WRAP   = 0   // If set, the counter goes back to START after END is reached
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              srst,
    input  logic              en,
    output logic [WIDTH-1:0]  count,
    output logic              last,
    input  logic              set_valid,
    input  logic [WIDTH-1:0]  set_value
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)         count <= WIDTH'(START);
        else if (srst)      count <= WIDTH'(START);
        else if (set_valid) count <= set_value;
        else if (en) begin
            if (last)       count <= WRAP ? WIDTH'(START) : count;
            else            count <= count + WIDTH'(STRIDE);
        end
    end

    assign last = (count == WIDTH'(END));

endmodule
