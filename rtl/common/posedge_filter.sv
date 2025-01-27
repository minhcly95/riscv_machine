module posedge_filter(
    input  logic  clk,
    input  logic  rst_n,
    input  logic  data,
    output logic  pe
);
    logic last_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) last_data <= 1'b1;
        else        last_data <= data;
    end

    assign pe = ~last_data & data;

endmodule
