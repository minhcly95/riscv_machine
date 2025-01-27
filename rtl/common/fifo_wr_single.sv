// Like fifo_wr, but DEPTH = 1
module fifo_wr_single #(
    parameter  WIDTH = 1,
    parameter  SKID  = 0    // SKID means w_valid = 1 right when r_ready = 1
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              srst,
    // Write port
    output logic              w_valid,
    input  logic              w_ready,
    input  logic [WIDTH-1:0]  w_data,
    // Read port
    output logic              r_valid,
    input  logic              r_ready,
    output logic [WIDTH-1:0]  r_data
);

    logic [WIDTH-1:0]  mem;

    logic              w_phase;
    logic              r_phase;

    logic              w_valid_pre_skid;

    // Phase control
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                 w_phase <= 1'b0;
        else if (srst)              w_phase <= 1'b0;
        else if (w_valid & w_ready) w_phase <= ~w_phase;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                 r_phase <= 1'b0;
        else if (srst)              r_phase <= 1'b0;
        else if (r_valid & r_ready) r_phase <= ~r_phase;
    end

    // Write port
    always_ff @(posedge clk) begin
        if (w_valid & w_ready)
            mem <= w_data;
    end

    // Read port
    assign r_data = mem;

    // Valid conditions
    assign w_valid_pre_skid = w_phase == r_phase;
    assign r_valid          = r_phase != w_phase;

    generate
        if (SKID)
            assign w_valid = w_valid_pre_skid | r_ready;
        else
            assign w_valid = w_valid_pre_skid;
    endgenerate

endmodule
