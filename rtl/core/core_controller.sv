module core_controller (
    input  logic  clk,
    input  logic  rst_n,
    // To FETCH stage
    output logic  fetch_stage_valid,
    input  logic  fetch_stage_ready,
    // To EXEC stage
    output logic  exec_stage_valid,
    input  logic  exec_stage_ready,
    input  logic  mem_op,
    // To MEM stage
    output logic  mem_stage_valid,
    input  logic  mem_stage_ready,
    // To Write-back mux
    output logic  reg_d_en
);

    // State definition
    typedef enum logic [1:0] {
        IDLE,
        FETCH,
        EXEC,
        MEM
    } state_e;

    // State machine
    state_e curr_state;
    state_e next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) curr_state <= IDLE;
        else        curr_state <= next_state;
    end

    // Transition
    // If mem_op:  FETCH -> EXEC -> MEM -> FETCH
    // If ~mem_op: FETCH -> EXEC -> FETCH
    always_comb begin
        case (curr_state)
            IDLE:    next_state = FETCH;
            FETCH:   next_state = fetch_stage_ready ? EXEC : FETCH;
            EXEC:    next_state = exec_stage_ready  ? (mem_op ? MEM : FETCH) : EXEC;
            MEM:     next_state = mem_stage_ready   ? FETCH : MEM;
        endcase
    end

    // Output
    assign fetch_stage_valid = (curr_state == FETCH);
    assign exec_stage_valid  = (curr_state == EXEC);
    assign mem_stage_valid   = (curr_state == MEM);

    // Write register when
    // If mem_op:  end of MEM stage
    // If ~mem_op: end of EXEC stage
    always_comb begin
        if (mem_op)
            reg_d_en = mem_stage_valid & mem_stage_ready;
        else
            reg_d_en = exec_stage_valid & exec_stage_ready;
    end

endmodule
