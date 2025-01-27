module negedge_filter(
    input  logic  clk,
    input  logic  rst_n,
    input  logic  data,
    output logic  ne
);
    logic last_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) last_data <= 1'b0;
        else        last_data <= data;
    end

    assign ne = last_data & ~data;

endmodule
