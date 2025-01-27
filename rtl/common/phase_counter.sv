// This is similar to a static_counter,
// but it flips the phase every wrap around.
module phase_counter #(
    parameter  WIDTH  = 8,
    parameter  START  = 0,
    parameter  END    = 2**WIDTH - 1,
    parameter  STRIDE = 1
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              srst,
    input  logic              en,
    output logic [WIDTH-1:0]  count,
    output logic              phase,
    output logic              last
);

    static_counter #(
        .WIDTH   (WIDTH),
        .START   (START),
        .END     (END),
        .STRIDE  (STRIDE)
    ) u_counter(
        .clk     (clk),
        .rst_n   (rst_n),
        .srst    (srst),
        .en      (en),
        .count   (count),
        .last    (last)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)         phase <= 1'b0;
        else if (srst)      phase <= 1'b0;
        else if (en & last) phase <= ~phase;
    end

endmodule
