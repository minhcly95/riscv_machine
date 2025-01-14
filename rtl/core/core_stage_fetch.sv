module core_stage_fetch #(
    parameter  RESET_VECTOR = 32'h0000_0000
)(
    input  logic         clk,
    input  logic         rst_n,
    // From Controller
    input  logic         fetch_stage_valid,
    output logic         fetch_stage_ready,
    // To EXEC stage
    output logic [31:0]  instr,
    output logic [31:0]  pc,
    // From EXEC stage
    input  logic         pc_new_valid,
    input  logic [31:0]  pc_new,
    // To Write-back mux
    output logic [31:0]  pc_plus_4,
    // Memory interface
    output logic         imem_valid,
    input  logic         imem_ready,
    output logic [31:0]  imem_addr,
    input  logic [31:0]  imem_rdata
);

    logic        fetch_done;
    logic [31:0] curr_pc;

    // Handshake
    assign imem_valid        = fetch_stage_valid;
    assign fetch_stage_ready = imem_ready;
    assign fetch_done        = fetch_stage_valid & fetch_stage_ready;

    // PC register
    // Increases by 4 every FETCH cycle
    // or gets updated with new value from EXEC.
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)            curr_pc <= RESET_VECTOR;
        else if (fetch_done)   curr_pc <= curr_pc + 4;
        else if (pc_new_valid) curr_pc <= pc_new;
    end

    // Store the old PC for the EXEC stage
    // since the curr_pc is PC + 4 after fetch_done
    always_ff @(posedge clk) begin
        if (fetch_done) pc <= curr_pc;
    end

    // PC + 4 is actually curr_pc after fetch_done
    assign pc_plus_4 = curr_pc;

    // Address to I-mem is the current PC (before fetch_done)
    assign imem_addr = curr_pc;

    // I-mem data is buffered in instr
    always_ff @(posedge clk) begin
        if (fetch_done) instr <= imem_rdata;
    end

endmodule
