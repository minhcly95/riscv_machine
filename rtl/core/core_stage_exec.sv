module core_stage_exec (
    // From Controller
    input  logic                 exec_stage_valid,
    output logic                 exec_stage_ready,
    output logic                 mem_op,
    // From Reg file
    output logic  [4:0]          reg_a_id,
    input  logic [31:0]          reg_a_value,
    output logic  [4:0]          reg_b_id,
    input  logic [31:0]          reg_b_value,
    output logic  [4:0]          reg_d_id,
    // From FETCH stage
    input  logic [31:0]          instr,
    input  logic [31:0]          pc,
    // To FETCH stage
    output logic                 pc_new_valid,
    output logic [31:0]          pc_new,
    // To MEM stage
    output logic [31:0]          mem_addr,
    output logic [31:0]          mem_wdata,
    output core_pkg::mem_dir_e   mem_dir,
    output core_pkg::mem_size_e  mem_size,
    // To Write-back mux
    output core_pkg::wb_src_e    wb_src,
    output logic [31:0]          alu_result
);

    import core_pkg::*;

    // Control signals
    imm_type_e    imm_type;
    alu_src_e     alu_src;
    alu_op_e      alu_op;
    pc_src_e      pc_src;
    br_type_e     br_type;
    logic         ecall;

    // Immediate value
    logic [31:0]  imm_val;

    // ALU sources
    logic [31:0]  src_a;
    logic [31:0]  src_b;

    // Branch target
    logic [31:0]  br_target;

    // To FETCH
    logic         in_pc_new_valid;

    // ------------------ Controller ------------------
    // Hang when opcode is ECALL
    assign exec_stage_ready = ~ecall;

    // ------------------- Decoder --------------------
    core_decoder u_decoder(
        .instr        (instr),
        .imm_type     (imm_type),
        .alu_src      (alu_src),
        .alu_op       (alu_op),
        .wb_src       (wb_src),
        .pc_src       (pc_src),
        .br_type      (br_type),
        .mem_op       (mem_op),
        .mem_dir      (mem_dir),
        .mem_size     (mem_size),
        .ecall        (ecall)
    );

    assign reg_d_id = instr[11:7];
    assign reg_a_id = instr[19:15];
    assign reg_b_id = instr[24:20];

    // ------------------ Imm parser ------------------
    core_imm_parser u_imm_parser(
        .instr        (instr),
        .imm_type     (imm_type),
        .imm_val      (imm_val)
    );

    // ----------------- ALU Source -------------------
    core_alu_src_sel u_alu_src_sel(
        .alu_src      (alu_src),
        .reg_a_value  (reg_a_value),
        .reg_b_value  (reg_b_value),
        .imm_val      (imm_val),
        .pc           (pc),
        .src_a        (src_a),
        .src_b        (src_b)
    );

    // -------------------- ALU -----------------------
    core_alu u_alu(
        .alu_op       (alu_op),
        .src_a        (src_a),
        .src_b        (src_b),
        .alu_result   (alu_result)
    );

    // ---------------- Branch & Jump -----------------
    assign br_target = pc + imm_val;

    core_pc_new_sel u_pc_new_sel(
        .pc_src        (pc_src),
        .br_type       (br_type),
        .alu_result    (alu_result),
        .br_target     (br_target),
        .pc_new_valid  (in_pc_new_valid),
        .pc_new        (pc_new)
    );

    assign pc_new_valid = in_pc_new_valid & exec_stage_valid & exec_stage_ready;

    // ------------------ MEM stage -------------------
    assign mem_addr  = alu_result;
    assign mem_wdata = reg_b_value;

endmodule
