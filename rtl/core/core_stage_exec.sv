module core_stage_exec (
    input  logic                  clk,
    // From Controller
    input  logic                  exec_stage_valid,
    output logic                  exec_stage_ready,
    input  logic                  exec_phase,
    output core_pkg::ctrl_path_e  ctrl_path,
    // From Reg file
    output logic  [4:0]           reg_a_id,
    input  logic [31:0]           reg_a_value,
    output logic  [4:0]           reg_b_id,
    input  logic [31:0]           reg_b_value,
    output logic  [4:0]           reg_d_id,
    // From FETCH stage
    input  logic [31:0]           instr,
    input  logic [31:0]           pc,
    // To FETCH stage
    output logic                  pc_new_valid,
    output logic [31:0]           pc_new,
    // From/to MEM stage
    output logic [31:0]           mem_addr,
    output logic [31:0]           mem_wdata,
    output core_pkg::mem_dir_e    mem_dir,
    output core_pkg::mem_size_e   mem_size,
    output core_pkg::mem_rsv_e    mem_rsv,
    input  logic                  mem_rsv_valid,
    input  logic [31:0]           mem_last_rdata,
    // To Write-back mux
    output core_pkg::wb_src_e     wb_src,
    output logic [31:0]           exec_result,
    // To CSR
    output logic [11:0]           csr_id,
    output logic                  csr_read,
    output logic                  csr_write,
    input  logic [31:0]           csr_rdata,
    output logic [31:0]           csr_wdata,
    output logic                  mret,
    // To Trap handler
    output logic                  ex_ecall,
    output logic                  ex_ebreak,
    output logic                  ex_exec_illegal_instr,
    output logic                  ex_instr_misaligned,
    output logic                  ex_load_misaligned,
    output logic                  ex_store_misaligned
);

    import core_pkg::*;

    // Handshake
    logic          exec_done;

    // Control signals
    ctrl_path_e    pre_ctrl_path;
    imm_type_e     imm_type;
    exec_src_e     exec_src;
    alu_op_e       alu_op;
    mul_op_e       mul_op;
    div_op_e       div_op;
    exec_engine_e  exec_engine;
    pc_src_e       pc_src;
    br_type_e      br_type;
    mem_src_e      mem_src;
    logic          sc;

    // Immediate value
    logic [31:0]   imm_val;

    // EXEC sources
    logic [31:0]   src_a;
    logic [31:0]   src_b;

    // EXEC results
    logic [31:0]   alu_result;
    logic [31:0]   mul_result;
    logic [31:0]   div_result;

    logic [31:0]   last_alu_result;

    // Branch target
    logic [31:0]   br_target;

    // To FETCH
    logic          in_pc_new_valid;

    // Exception condition
    logic          ecall;
    logic          ebreak;
    logic          illegal_instr;
    logic          is_mem_op;
    logic          mem_addr_misaligned;

    // ------------------ Controller ------------------
    // Always ready
    assign exec_stage_ready = 1'b1;
    assign exec_done        = exec_stage_valid & exec_stage_ready;

    // ------------------- Decoder --------------------
    core_decoder u_decoder(
        .instr          (instr),
        .exec_phase     (exec_phase),
        .ctrl_path      (pre_ctrl_path),
        .imm_type       (imm_type),
        .exec_src       (exec_src),
        .alu_op         (alu_op),
        .mul_op         (mul_op),
        .div_op         (div_op),
        .exec_engine    (exec_engine),
        .wb_src         (wb_src),
        .pc_src         (pc_src),
        .br_type        (br_type),
        .mem_src        (mem_src),
        .mem_dir        (mem_dir),
        .mem_size       (mem_size),
        .mem_rsv        (mem_rsv),
        .sc             (sc),
        .csr_id         (csr_id),
        .csr_read       (csr_read),
        .csr_write      (csr_write),
        .ecall          (ecall),
        .ebreak         (ebreak),
        .mret           (mret),
        .illegal_instr  (illegal_instr)
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

    // ---------------- EXEC Source -------------------
    core_exec_src_sel u_exec_src_sel(
        .exec_src        (exec_src),
        .reg_a_value     (reg_a_value),
        .reg_b_value     (reg_b_value),
        .imm_val         (imm_val),
        .pc              (pc),
        .mem_last_rdata  (mem_last_rdata),
        .csr_rdata       (csr_rdata),
        .src_a           (src_a),
        .src_b           (src_b)
    );

    // -------------------- ALU -----------------------
    core_alu u_alu(
        .alu_op       (alu_op),
        .src_a        (src_a),
        .src_b        (src_b),
        .alu_result   (alu_result)
    );

    // -------------------- MUL -----------------------
    core_mul u_mul(
        .mul_op       (mul_op),
        .src_a        (src_a),
        .src_b        (src_b),
        .mul_result   (mul_result)
    );

    // -------------------- DIV -----------------------
    core_div u_div(
        .div_op       (div_op),
        .src_a        (src_a),
        .src_b        (src_b),
        .div_result   (div_result)
    );

    // -----------------Engine select -----------------
    core_exec_engine_sel u_exec_engine_sel(
        .exec_engine    (exec_engine),
        .alu_result     (alu_result),
        .mul_result     (mul_result),
        .div_result     (div_result),
        .csr_rdata      (csr_rdata),
        .mem_rsv_valid  (mem_rsv_valid),
        .exec_result    (exec_result)
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
    core_mem_src_sel u_mem_src_sel(
        .mem_src          (mem_src),
        .reg_b_value      (reg_b_value),
        .alu_result       (alu_result),
        .last_alu_result  (last_alu_result),
        .mem_addr         (mem_addr),
        .mem_wdata        (mem_wdata)
    );

    // -------------- Control path mod ----------------
    // If instr is SC, we modify the ctrl_path based on mem_rsv_valid
    assign ctrl_path = (sc & ~mem_rsv_valid) ? CTRL_EXEC : pre_ctrl_path;

    // --------------- Last ALU result ----------------
    // Only store the last ALU result in first phase
    flope #(
        .WIDTH  (32)
    ) u_last_alu_result(
        .clk    (clk),
        .en     (exec_stage_valid & exec_stage_ready & ~exec_phase),
        .d      (alu_result),
        .q      (last_alu_result)
    );

    // ----------------- CSR output -------------------
    assign csr_wdata = alu_result;

    // ----------------- Exceptions -------------------
    // Load/store address needs to be aligned with access size
    core_misaligned_calc u_misaligned_calc(
        .mem_size             (mem_size),
        .mem_addr_offset      (mem_addr[1:0]),
        .mem_addr_misaligned  (mem_addr_misaligned)
    );

    assign is_mem_op = (ctrl_path == CTRL_MEM) | (ctrl_path == CTRL_AMO);

    assign ex_instr_misaligned   = pc_new_valid & (|pc_new[1:0]);
    assign ex_load_misaligned    = exec_done & is_mem_op & mem_addr_misaligned & (mem_dir == MEM_READ);
    assign ex_store_misaligned   = exec_done & is_mem_op & mem_addr_misaligned & (mem_dir == MEM_WRITE);
    assign ex_ecall              = exec_done & ecall;
    assign ex_ebreak             = exec_done & ebreak;
    assign ex_exec_illegal_instr = exec_done & illegal_instr;

endmodule
