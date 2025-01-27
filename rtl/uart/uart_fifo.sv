module uart_fifo #(
    parameter  WIDTH = 8
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        srst,
    // Push port
    input  logic        push_valid,
    output logic        push_ready,
    input  logic [7:0]  push_data,
    // Pop port
    output logic        pop_valid,
    input  logic        pop_ready,
    output logic [7:0]  pop_data,
    // Status
    output logic [4:0]  push_cnt,
    output logic [4:0]  pop_cnt,
    // Configurations
    input  logic        cfg_fifo_enable
);

    localparam DEPTH = 16;  // Must be fixed to 16

    logic [DEPTH-1:0][WIDTH-1:0]  mem;

    // We use double-cover pointer (pointer with phase)
    // to control the fifo, so max_cnt = 2 * depth.
    // If fifo is enabled, cnt increases by 1 per entry.
    // Otherwise, cnt increases by 16 per entry.
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)              push_cnt <= 5'd0;
        else if (srst)           push_cnt <= 5'd0;
        else if (push_valid & push_ready) begin
            if (cfg_fifo_enable) push_cnt <= push_cnt + 5'd1;
            else                 push_cnt <= push_cnt + 5'(DEPTH);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)              pop_cnt <= 5'd0;
        else if (srst)           pop_cnt <= 5'd0;
        else if (pop_valid & pop_ready) begin
            if (cfg_fifo_enable) pop_cnt <= pop_cnt + 5'd1;
            else                 pop_cnt <= pop_cnt + 5'(DEPTH);
        end
    end

    // Push port
    always_ff @(posedge clk) begin
        if (push_valid & push_ready)
            mem[push_cnt[3:0]] <= push_data;
    end

    // Pop port
    assign pop_data = mem[pop_cnt[3:0]];

    // Valid conditions
    assign push_ready = push_cnt != (pop_cnt + 5'(DEPTH));
    assign pop_valid  = push_cnt != pop_cnt;

endmodule
