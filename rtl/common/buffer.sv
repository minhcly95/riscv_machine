// This is a more sensible wrapper of fifo_wr
// where input valid and ready direction is swapped.
module buffer #(
    parameter  WIDTH = 1,
    parameter  DEPTH = 4,
    parameter  SKID  = 0    // SKID means push_ready = 1 right when pop_ready = 1
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              srst,
    // Push port
    input  logic              push_valid,
    output logic              push_ready,
    input  logic [WIDTH-1:0]  push_data,
    // Pop port
    output logic              pop_valid,
    input  logic              pop_ready,
    output logic [WIDTH-1:0]  pop_data
);

    generate
        if (DEPTH == 1) begin : g_single
            fifo_wr_single #(
                .WIDTH    (WIDTH),
                .SKID     (SKID)
            ) u_fifo_wr_single(
                .clk      (clk),
                .rst_n    (rst_n),
                .srst     (srst),
                .w_valid  (push_ready),
                .w_ready  (push_valid),
                .w_data   (push_data),
                .r_valid  (pop_valid),
                .r_ready  (pop_ready),
                .r_data   (pop_data)
            );
        end
        else begin : g_normal
            fifo_wr #(
                .WIDTH    (WIDTH),
                .DEPTH    (DEPTH),
                .SKID     (SKID)
            ) u_fifo_wr(
                .clk      (clk),
                .rst_n    (rst_n),
                .srst     (srst),
                .w_valid  (push_ready),
                .w_ready  (push_valid),
                .w_data   (push_data),
                .r_valid  (pop_valid),
                .r_ready  (pop_ready),
                .r_data   (pop_data)
            );
        end
    endgenerate

endmodule
