module core_top #(
    parameter  RESET_VECTOR = 32'h0000_0000
)(
    input  logic         clk,
    input  logic         rst_n,
    // APB master
    output logic         psel,
    output logic         penable,
    input  logic         pready,
    output logic [31:0]  paddr,
    output logic         pwrite,
    output logic [31:0]  pwdata,
    output logic  [3:0]  pwstrb,
    input  logic [31:0]  prdata,
    input  logic         pslverr
);

    import core_pkg::*;

    // Controller stages
    logic         fetch_stage_valid;
    logic         fetch_stage_ready;
    logic         exec_stage_valid;
    logic         exec_stage_ready;
    logic         mem_op;
    logic         mem_stage_valid;
    logic         mem_stage_ready;

    // FETCH-EXEC interface
    logic [31:0]  instr;
    logic [31:0]  pc;
    logic         pc_new_valid;
    logic [31:0]  pc_new;

    // EXEC-MEM interface
    logic [31:0]  mem_addr;
    logic [31:0]  mem_wdata;
    mem_dir_e     mem_dir;
    mem_size_e    mem_size;

    // Reg file interface
    logic  [4:0]  reg_a_id;
    logic [31:0]  reg_a_value;
    logic  [4:0]  reg_b_id;
    logic [31:0]  reg_b_value;
    logic  [4:0]  reg_d_id;
    logic         reg_d_en;
    logic         reg_d_write;
    logic [31:0]  reg_d_value;

    // Write-back mux inputs
    wb_src_e      wb_src;
    logic [31:0]  pc_plus_4;
    logic [31:0]  alu_result;
    logic [31:0]  mem_rdata;

    // I-mem interface
    logic         imem_valid;
    logic         imem_ready;
    logic [31:0]  imem_addr;
    logic [31:0]  imem_rdata;

    // D-mem interface
    logic         dmem_valid;
    logic         dmem_ready;
    logic [31:0]  dmem_addr;
    logic         dmem_write;
    logic [31:0]  dmem_wdata;
    logic  [3:0]  dmem_wstrb;
    logic [31:0]  dmem_rdata;

    // ------------------ Controller ------------------
    core_controller u_controller(
        .clk                (clk),
        .rst_n              (rst_n),
        .fetch_stage_valid  (fetch_stage_valid),
        .fetch_stage_ready  (fetch_stage_ready),
        .exec_stage_valid   (exec_stage_valid),
        .exec_stage_ready   (exec_stage_ready),
        .mem_op             (mem_op),
        .mem_stage_valid    (mem_stage_valid),
        .mem_stage_ready    (mem_stage_ready),
        .reg_d_en           (reg_d_en)
    );

    // ----------------- FETCH stage ------------------
    core_stage_fetch #(
        .RESET_VECTOR       (RESET_VECTOR)
    ) u_stage_fetch(
        .clk                (clk),
        .rst_n              (rst_n),
        .fetch_stage_valid  (fetch_stage_valid),
        .fetch_stage_ready  (fetch_stage_ready),
        .instr              (instr),
        .pc                 (pc),
        .pc_new_valid       (pc_new_valid),
        .pc_new             (pc_new),
        .pc_plus_4          (pc_plus_4),
        .imem_valid         (imem_valid),
        .imem_ready         (imem_ready),
        .imem_addr          (imem_addr),
        .imem_rdata         (imem_rdata)
    );

    // ------------------ EXEC stage ------------------
    core_stage_exec u_stage_exec(
        .exec_stage_valid   (exec_stage_valid),
        .exec_stage_ready   (exec_stage_ready),
        .mem_op             (mem_op),
        .reg_a_id           (reg_a_id),
        .reg_a_value        (reg_a_value),
        .reg_b_id           (reg_b_id),
        .reg_b_value        (reg_b_value),
        .reg_d_id           (reg_d_id),
        .instr              (instr),
        .pc                 (pc),
        .pc_new_valid       (pc_new_valid),
        .pc_new             (pc_new),
        .mem_addr           (mem_addr),
        .mem_wdata          (mem_wdata),
        .mem_dir            (mem_dir),
        .mem_size           (mem_size),
        .wb_src             (wb_src),
        .alu_result         (alu_result)
    );

    // ------------------- MEM stage ------------------
    core_stage_mem u_stage_mem(
        .mem_stage_valid    (mem_stage_valid),
        .mem_stage_ready    (mem_stage_ready),
        .mem_addr           (mem_addr),
        .mem_wdata          (mem_wdata),
        .mem_dir            (mem_dir),
        .mem_size           (mem_size),
        .mem_rdata          (mem_rdata),
        .dmem_valid         (dmem_valid),
        .dmem_ready         (dmem_ready),
        .dmem_addr          (dmem_addr),
        .dmem_write         (dmem_write),
        .dmem_wdata         (dmem_wdata),
        .dmem_wstrb         (dmem_wstrb),
        .dmem_rdata         (dmem_rdata)
    );

    // ------------------- Reg file -------------------
    core_reg_file u_reg_file(
        .clk                (clk),
        .reg_a_id           (reg_a_id),
        .reg_a_value        (reg_a_value),
        .reg_b_id           (reg_b_id),
        .reg_b_value        (reg_b_value),
        .reg_d_id           (reg_d_id),
        .reg_d_en           (reg_d_en),
        .reg_d_write        (reg_d_write),
        .reg_d_value        (reg_d_value)
    );

    // -------------- Memory interface ----------------
    core_mem_if u_mem_if(
        .clk                (clk),
        .rst_n              (rst_n),
        .imem_valid         (imem_valid),
        .imem_ready         (imem_ready),
        .imem_addr          (imem_addr),
        .imem_rdata         (imem_rdata),
        .dmem_valid         (dmem_valid),
        .dmem_ready         (dmem_ready),
        .dmem_addr          (dmem_addr),
        .dmem_write         (dmem_write),
        .dmem_wdata         (dmem_wdata),
        .dmem_wstrb         (dmem_wstrb),
        .dmem_rdata         (dmem_rdata),
        .psel               (psel),
        .penable            (penable),
        .pready             (pready),
        .paddr              (paddr),
        .pwrite             (pwrite),
        .pwdata             (pwdata),
        .pwstrb             (pwstrb),
        .prdata             (prdata),
        .pslverr            (pslverr)
    );

    // --------------- Write-back mux -----------------
    core_wb_mux u_wb_mux(
        .pc_plus_4          (pc_plus_4),
        .wb_src             (wb_src),
        .alu_result         (alu_result),
        .mem_rdata          (mem_rdata),
        .reg_d_write        (reg_d_write),
        .reg_d_value        (reg_d_value)
    );

endmodule
