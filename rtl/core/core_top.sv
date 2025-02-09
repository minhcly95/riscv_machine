module core_top #(
    parameter  RESET_VECTOR = 32'h0000_0000
)(
    input  logic         clk,
    input  logic         rst_n,
    // APB master
    output logic         psel,
    output logic         penable,
    input  logic         pready,
    output logic [33:0]  paddr,
    output logic         pwrite,
    output logic [31:0]  pwdata,
    output logic  [3:0]  pwstrb,
    input  logic [31:0]  prdata,
    input  logic         pslverr,
    // MTIME direct input
    input  logic [63:0]  mtime,
    // External interrupt
    input  logic         int_m_ext,
    input  logic         mtimer_int
);

    import core_pkg::*;

    // Controller stages
    logic         fetch_stage_valid;
    logic         fetch_stage_ready;
    logic         exec_stage_valid;
    logic         exec_stage_ready;
    logic         exec_phase;
    ctrl_path_e   ctrl_path;
    logic         mem_stage_valid;
    logic         mem_stage_ready;
    logic         instr_done;
    logic         check_interrupt;

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
    mem_rsv_e     mem_rsv;
    logic         mem_rsv_valid;
    logic [31:0]  mem_last_rdata;

    // Reg file interface
    logic  [4:0]  reg_a_id;
    logic [31:0]  reg_a_value;
    logic  [4:0]  reg_b_id;
    logic [31:0]  reg_b_value;
    logic  [4:0]  reg_d_id;
    logic         reg_d_en;
    logic         reg_d_write;
    logic [31:0]  reg_d_value;

    // CSR interface
    logic         csr_en;
    logic [11:0]  csr_id;
    logic         csr_read;
    logic         csr_write;
    logic [31:0]  csr_rdata;
    logic [31:0]  csr_wdata;
    logic         mret;
    logic         sret;
    logic         wfi;
    logic         sfence_vma;
    logic         pc_csr_valid;
    logic [31:0]  pc_csr;

    // Write-back mux inputs
    wb_src_e      wb_src;
    logic [31:0]  pc_plus_4;
    logic [31:0]  exec_result;
    logic [31:0]  mem_rdata;

    // Trap handler interface
    logic         exception_valid;
    exception_e   exception_cause;
    logic [31:0]  exception_value;
    logic         m_interrupt_valid;
    interrupt_e   m_interrupt_cause;
    logic         s_interrupt_valid;
    interrupt_e   s_interrupt_cause;
    priv_e        priv;
    logic         cfg_mie;
    logic         cfg_sie;
    logic         cfg_meie;
    logic         cfg_mtie;
    logic         cfg_seie;
    logic         cfg_stie;
    logic         cfg_ssie;
    logic         cfg_seip;
    logic         cfg_stip;
    logic         cfg_ssip;
    logic         cfg_mideleg_se;
    logic         cfg_mideleg_st;
    logic         cfg_mideleg_ss;
    logic         ex_csr_illegal_instr;
    logic         ex_ecall;
    logic         ex_ebreak;
    logic         ex_exec_illegal_instr;
    logic         ex_instr_misaligned;
    logic         ex_load_misaligned;
    logic         ex_store_misaligned;
    logic         ex_instr_access_fault;
    logic         ex_load_access_fault;
    logic         ex_store_access_fault;
    logic         ex_instr_page_fault;
    logic         ex_load_page_fault;
    logic         ex_store_page_fault;

    // Memory interface
    logic         imem_valid;
    logic         imem_ready;
    logic [31:0]  imem_addr;
    logic [31:0]  imem_rdata;
    logic         dmem_valid;
    logic         dmem_ready;
    logic [31:0]  dmem_addr;
    mem_dir_e     dmem_dir;
    logic [31:0]  dmem_wdata;
    logic  [3:0]  dmem_wstrb;
    logic [31:0]  dmem_rdata;
    priv_e        priv_imem;
    priv_e        priv_dmem;
    logic         cfg_sum;
    logic         cfg_mxr;
    satp_mode_e   cfg_satp_mode;
    logic [21:0]  cfg_satp_ppn;

    // ------------------ Controller ------------------
    core_controller u_controller(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .fetch_stage_valid      (fetch_stage_valid),
        .fetch_stage_ready      (fetch_stage_ready),
        .exec_stage_valid       (exec_stage_valid),
        .exec_stage_ready       (exec_stage_ready),
        .exec_phase             (exec_phase),
        .ctrl_path              (ctrl_path),
        .mem_stage_valid        (mem_stage_valid),
        .mem_stage_ready        (mem_stage_ready),
        .reg_d_en               (reg_d_en),
        .csr_en                 (csr_en),
        .instr_done             (instr_done),
        .check_interrupt        (check_interrupt),
        .exception_valid        (exception_valid),
        .m_interrupt_valid      (m_interrupt_valid),
        .s_interrupt_valid      (s_interrupt_valid)
    );

    // ----------------- FETCH stage ------------------
    core_stage_fetch #(
        .RESET_VECTOR           (RESET_VECTOR)
    ) u_stage_fetch(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .fetch_stage_valid      (fetch_stage_valid),
        .fetch_stage_ready      (fetch_stage_ready),
        .instr                  (instr),
        .pc                     (pc),
        .pc_new_valid           (pc_new_valid),
        .pc_new                 (pc_new),
        .pc_csr_valid           (pc_csr_valid),
        .pc_csr                 (pc_csr),
        .pc_plus_4              (pc_plus_4),
        .imem_valid             (imem_valid),
        .imem_ready             (imem_ready),
        .imem_addr              (imem_addr),
        .imem_rdata             (imem_rdata),
        .m_interrupt_valid      (m_interrupt_valid),
        .s_interrupt_valid      (s_interrupt_valid)
    );

    // ------------------ EXEC stage ------------------
    core_stage_exec u_stage_exec(
        .clk                    (clk),
        .exec_stage_valid       (exec_stage_valid),
        .exec_stage_ready       (exec_stage_ready),
        .exec_phase             (exec_phase),
        .ctrl_path              (ctrl_path),
        .reg_a_id               (reg_a_id),
        .reg_a_value            (reg_a_value),
        .reg_b_id               (reg_b_id),
        .reg_b_value            (reg_b_value),
        .reg_d_id               (reg_d_id),
        .instr                  (instr),
        .pc                     (pc),
        .pc_new_valid           (pc_new_valid),
        .pc_new                 (pc_new),
        .mem_addr               (mem_addr),
        .mem_wdata              (mem_wdata),
        .mem_dir                (mem_dir),
        .mem_size               (mem_size),
        .mem_rsv                (mem_rsv),
        .mem_rsv_valid          (mem_rsv_valid),
        .mem_last_rdata         (mem_last_rdata),
        .wb_src                 (wb_src),
        .exec_result            (exec_result),
        .csr_id                 (csr_id),
        .csr_read               (csr_read),
        .csr_write              (csr_write),
        .csr_rdata              (csr_rdata),
        .csr_wdata              (csr_wdata),
        .mret                   (mret),
        .sret                   (sret),
        .wfi                    (wfi),
        .sfence_vma             (sfence_vma),
        .ex_ecall               (ex_ecall),
        .ex_ebreak              (ex_ebreak),
        .ex_exec_illegal_instr  (ex_exec_illegal_instr),
        .ex_instr_misaligned    (ex_instr_misaligned),
        .ex_load_misaligned     (ex_load_misaligned),
        .ex_store_misaligned    (ex_store_misaligned)
    );

    // ------------------- MEM stage ------------------
    core_stage_mem u_stage_mem(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .mem_stage_valid        (mem_stage_valid),
        .mem_stage_ready        (mem_stage_ready),
        .mem_addr               (mem_addr),
        .mem_wdata              (mem_wdata),
        .mem_dir                (mem_dir),
        .mem_size               (mem_size),
        .mem_rsv                (mem_rsv),
        .mem_rsv_valid          (mem_rsv_valid),
        .mem_last_rdata         (mem_last_rdata),
        .mem_rdata              (mem_rdata),
        .dmem_valid             (dmem_valid),
        .dmem_ready             (dmem_ready),
        .dmem_addr              (dmem_addr),
        .dmem_dir               (dmem_dir),
        .dmem_wdata             (dmem_wdata),
        .dmem_wstrb             (dmem_wstrb),
        .dmem_rdata             (dmem_rdata)
    );

    // ------------------- Reg file -------------------
    core_reg_file u_reg_file(
        .clk                    (clk),
        .reg_a_id               (reg_a_id),
        .reg_a_value            (reg_a_value),
        .reg_b_id               (reg_b_id),
        .reg_b_value            (reg_b_value),
        .reg_d_id               (reg_d_id),
        .reg_d_en               (reg_d_en),
        .reg_d_write            (reg_d_write),
        .reg_d_value            (reg_d_value)
    );

    // --------------------- CSR ----------------------
    core_csr u_csr(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .csr_en                 (csr_en),
        .instr_done             (instr_done),
        .csr_id                 (csr_id),
        .csr_read               (csr_read),
        .csr_write              (csr_write),
        .csr_rdata              (csr_rdata),
        .csr_wdata              (csr_wdata),
        .mret                   (mret),
        .sret                   (sret),
        .wfi                    (wfi),
        .sfence_vma             (sfence_vma),
        .pc                     (pc),
        .pc_csr_valid           (pc_csr_valid),
        .pc_csr                 (pc_csr),
        .exception_valid        (exception_valid),
        .exception_cause        (exception_cause),
        .exception_value        (exception_value),
        .m_interrupt_valid      (m_interrupt_valid),
        .m_interrupt_cause      (m_interrupt_cause),
        .s_interrupt_valid      (s_interrupt_valid),
        .s_interrupt_cause      (s_interrupt_cause),
        .priv                   (priv),
        .cfg_mie                (cfg_mie),
        .cfg_sie                (cfg_sie),
        .cfg_meie               (cfg_meie),
        .cfg_mtie               (cfg_mtie),
        .cfg_seie               (cfg_seie),
        .cfg_stie               (cfg_stie),
        .cfg_ssie               (cfg_ssie),
        .cfg_seip               (cfg_seip),
        .cfg_stip               (cfg_stip),
        .cfg_ssip               (cfg_ssip),
        .cfg_mideleg_se         (cfg_mideleg_se),
        .cfg_mideleg_st         (cfg_mideleg_st),
        .cfg_mideleg_ss         (cfg_mideleg_ss),
        .ex_csr_illegal_instr   (ex_csr_illegal_instr),
        .priv_imem              (priv_imem),
        .priv_dmem              (priv_dmem),
        .cfg_sum                (cfg_sum),
        .cfg_mxr                (cfg_mxr),
        .cfg_satp_mode          (cfg_satp_mode),
        .cfg_satp_ppn           (cfg_satp_ppn),
        .mtime                  (mtime),
        .int_m_ext              (int_m_ext),
        .mtimer_int             (mtimer_int)
    );

    // --------------- Memory interface ---------------
    core_mem_if u_mem_if(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .imem_valid             (imem_valid),
        .imem_ready             (imem_ready),
        .imem_addr              (imem_addr),
        .imem_rdata             (imem_rdata),
        .dmem_valid             (dmem_valid),
        .dmem_ready             (dmem_ready),
        .dmem_addr              (dmem_addr),
        .dmem_dir               (dmem_dir),
        .dmem_wdata             (dmem_wdata),
        .dmem_wstrb             (dmem_wstrb),
        .dmem_rdata             (dmem_rdata),
        .psel                   (psel),
        .penable                (penable),
        .pready                 (pready),
        .paddr                  (paddr),
        .pwrite                 (pwrite),
        .pwdata                 (pwdata),
        .pwstrb                 (pwstrb),
        .prdata                 (prdata),
        .pslverr                (pslverr),
        .priv_imem              (priv_imem),
        .priv_dmem              (priv_dmem),
        .cfg_sum                (cfg_sum),
        .cfg_mxr                (cfg_mxr),
        .cfg_satp_mode          (cfg_satp_mode),
        .cfg_satp_ppn           (cfg_satp_ppn),
        .ex_instr_access_fault  (ex_instr_access_fault),
        .ex_load_access_fault   (ex_load_access_fault),
        .ex_store_access_fault  (ex_store_access_fault),
        .ex_instr_page_fault    (ex_instr_page_fault),
        .ex_load_page_fault     (ex_load_page_fault),
        .ex_store_page_fault    (ex_store_page_fault)
    );

    // --------------- Write-back mux -----------------
    core_wb_mux u_wb_mux(
        .pc_plus_4              (pc_plus_4),
        .wb_src                 (wb_src),
        .exec_result            (exec_result),
        .mem_rdata              (mem_rdata),
        .reg_d_write            (reg_d_write),
        .reg_d_value            (reg_d_value)
    );

    // ---------------- Trap handler ------------------
    core_trap_handler u_trap_handler(
        .check_interrupt        (check_interrupt),
        .exception_valid        (exception_valid),
        .exception_cause        (exception_cause),
        .exception_value        (exception_value),
        .m_interrupt_valid      (m_interrupt_valid),
        .m_interrupt_cause      (m_interrupt_cause),
        .s_interrupt_valid      (s_interrupt_valid),
        .s_interrupt_cause      (s_interrupt_cause),
        .priv                   (priv),
        .cfg_mie                (cfg_mie),
        .cfg_sie                (cfg_sie),
        .cfg_meie               (cfg_meie),
        .cfg_mtie               (cfg_mtie),
        .cfg_seie               (cfg_seie),
        .cfg_stie               (cfg_stie),
        .cfg_ssie               (cfg_ssie),
        .cfg_seip               (cfg_seip),
        .cfg_stip               (cfg_stip),
        .cfg_ssip               (cfg_ssip),
        .cfg_mideleg_se         (cfg_mideleg_se),
        .cfg_mideleg_st         (cfg_mideleg_st),
        .cfg_mideleg_ss         (cfg_mideleg_ss),
        .ex_csr_illegal_instr   (ex_csr_illegal_instr),
        .instr                  (instr),
        .imem_addr              (imem_addr),
        .pc_new                 (pc_new),
        .mem_addr               (mem_addr),
        .ex_ecall               (ex_ecall),
        .ex_ebreak              (ex_ebreak),
        .ex_exec_illegal_instr  (ex_exec_illegal_instr),
        .ex_instr_misaligned    (ex_instr_misaligned),
        .ex_load_misaligned     (ex_load_misaligned),
        .ex_store_misaligned    (ex_store_misaligned),
        .ex_instr_access_fault  (ex_instr_access_fault),
        .ex_load_access_fault   (ex_load_access_fault),
        .ex_store_access_fault  (ex_store_access_fault),
        .ex_instr_page_fault    (ex_instr_page_fault),
        .ex_load_page_fault     (ex_load_page_fault),
        .ex_store_page_fault    (ex_store_page_fault),
        .int_m_ext              (int_m_ext),
        .mtimer_int             (mtimer_int)
    );


endmodule
