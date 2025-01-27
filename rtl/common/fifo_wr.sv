module fifo_wr #(
    parameter  WIDTH = 1,
    parameter  DEPTH = 4,
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

    localparam PTR_W = $clog2(DEPTH);

    logic [DEPTH-1:0][WIDTH-1:0]  mem;

    logic [PTR_W-1:0]  w_ptr;
    logic [PTR_W-1:0]  r_ptr;

    logic              w_phase;
    logic              r_phase;

    logic              w_valid_pre_skid;

    // Pointers
    phase_counter #(
        .WIDTH   (PTR_W),
        .END     (DEPTH-1)
    ) u_w_counter(
        .clk     (clk),
        .rst_n   (rst_n),
        .srst    (srst),
        .en      (w_valid & w_ready),
        .count   (w_ptr),
        .phase   (w_phase),
        .last    ()
    );

    phase_counter #(
        .WIDTH   (PTR_W),
        .END     (DEPTH-1)
    ) u_r_counter(
        .clk     (clk),
        .rst_n   (rst_n),
        .srst    (srst),
        .en      (r_valid & r_ready),
        .count   (r_ptr),
        .phase   (r_phase),
        .last    ()
    );

    // Write port
    always_ff @(posedge clk) begin
        if (w_valid & w_ready)
            mem[w_ptr] <= w_data;
    end

    // Read port
    assign r_data = mem[r_ptr];

    // Valid conditions
    assign w_valid_pre_skid = {w_phase, w_ptr} != {~r_phase, r_ptr};
    assign r_valid          = {r_phase, r_ptr} != { w_phase, w_ptr};

    generate
        if (SKID)
            assign w_valid = w_valid_pre_skid | r_ready;
        else
            assign w_valid = w_valid_pre_skid;
    endgenerate

endmodule
