module core_controller (
    input  logic                  clk,
    input  logic                  rst_n,
    // To FETCH stage
    output logic                  fetch_stage_valid,
    input  logic                  fetch_stage_ready,
    // To EXEC stage
    output logic                  exec_stage_valid,
    input  logic                  exec_stage_ready,
    output logic                  exec_phase,
    input  core_pkg::ctrl_path_e  ctrl_path,
    // To MEM stage
    output logic                  mem_stage_valid,
    input  logic                  mem_stage_ready,
    // To Write-back mux
    output logic                  reg_d_en,
    // To CSR
    output logic                  csr_en,
    output logic                  instr_done,
    // To Trap handler
    output logic                  check_interrupt,
    // From Trap handler
    input  logic                  exception_valid,
    input  logic                  m_interrupt_valid,
    input  logic                  s_interrupt_valid
);

    import core_pkg::*;

    // State definition
    typedef enum logic [2:0] {
        IDLE,
        FETCH_0,
        FETCH_1,
        EXEC_0,
        MEM_0,
        EXEC_1,
        MEM_1
    } state_e;

    state_e curr_state;
    state_e next_state;

    logic   is_mem_op;
    logic   two_phase;

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) curr_state <= IDLE;
        else        curr_state <= next_state;
    end

    // Transition
    always_comb begin
        if (exception_valid | m_interrupt_valid | s_interrupt_valid)
            // Go back to FETCH immediately after an exception
            next_state = FETCH_0;
        else
            case (curr_state)
                IDLE:    next_state = FETCH_0;
                FETCH_0: next_state = FETCH_1;
                FETCH_1: next_state = fetch_stage_ready ? EXEC_0 : FETCH_1;
                EXEC_0:  next_state = exec_stage_ready  ? (is_mem_op ? MEM_0  : FETCH_0) : EXEC_0;
                MEM_0:   next_state = mem_stage_ready   ? (two_phase ? EXEC_1 : FETCH_0) : MEM_0;
                EXEC_1:  next_state = exec_stage_ready  ? MEM_1   : EXEC_1;
                MEM_1:   next_state = mem_stage_ready   ? FETCH_0 : MEM_1;
                default: next_state = IDLE;
            endcase
    end

    // Control path decode
    always_comb begin
        case (ctrl_path)
            CTRL_MEM: begin
                is_mem_op = 1'b1;
                two_phase = 1'b0;
            end
            CTRL_AMO: begin
                is_mem_op = 1'b1;
                two_phase = 1'b1;
            end
            default: begin
                is_mem_op = 1'b0;
                two_phase = 1'b0;
            end
        endcase
    end

    // Output
    assign check_interrupt   = (curr_state == FETCH_0);
    assign fetch_stage_valid = (curr_state == FETCH_0) | (curr_state == FETCH_1);
    assign exec_stage_valid  = (curr_state == EXEC_0) | (curr_state == EXEC_1);
    assign mem_stage_valid   = (curr_state == MEM_0)  | (curr_state == MEM_1);
    assign exec_phase        = (curr_state == EXEC_1) | (curr_state == MEM_1);

    // Write register when no exception and
    // If CTRL_MEM or CTRL_AMO: end of MEM_0 stage
    // If CTRL_EXEC: end of EXEC_0 stage
    always_comb begin
        if (exception_valid)
            reg_d_en = 1'b0;
        else if (is_mem_op)
            reg_d_en = (curr_state == MEM_0)  & mem_stage_ready;
        else
            reg_d_en = (curr_state == EXEC_0) & exec_stage_ready;
    end

    // Access CSR in EXEC phase
    assign csr_en = exec_stage_valid & exec_stage_ready;

    // Instruction is retired when the next state is FETCH
    // but not due to an exception
    assign instr_done = (curr_state != FETCH_0) & (next_state == FETCH_0) & ~exception_valid;

endmodule
