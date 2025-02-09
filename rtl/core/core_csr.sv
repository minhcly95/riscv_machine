module core_csr (
    input  logic                  clk,
    input  logic                  rst_n,
    // From Controller
    input  logic                  csr_en,
    input  logic                  instr_done,
    // From/to EXEC stage
    input  logic [11:0]           csr_id,
    input  logic                  csr_read,
    input  core_pkg::csr_upd_e    csr_upd,
    output logic [31:0]           csr_rdata,
    input  logic [31:0]           csr_udata,
    input  logic                  mret,
    input  logic                  sret,
    input  logic                  wfi,
    input  logic                  sfence_vma,
    // From FETCH stage
    input  logic [31:0]           pc,
    // To FETCH stage
    output logic                  pc_csr_valid,
    output logic [31:0]           pc_csr,
    // From Trap handler
    input  logic                  exception_valid,
    input  core_pkg::exception_e  exception_cause,
    input  logic [31:0]           exception_value,
    input  logic                  m_interrupt_valid,
    input  core_pkg::interrupt_e  m_interrupt_cause,
    input  logic                  s_interrupt_valid,
    input  core_pkg::interrupt_e  s_interrupt_cause,
    // To Trap handler
    output core_pkg::priv_e       priv,
    output logic                  cfg_mie,
    output logic                  cfg_sie,
    output logic                  cfg_meie,
    output logic                  cfg_mtie,
    output logic                  cfg_seie,
    output logic                  cfg_stie,
    output logic                  cfg_ssie,
    output logic                  cfg_seip,
    output logic                  cfg_stip,
    output logic                  cfg_ssip,
    output logic                  cfg_mideleg_se,
    output logic                  cfg_mideleg_st,
    output logic                  cfg_mideleg_ss,
    output logic                  ex_csr_illegal_instr,
    // To Memory interface
    output core_pkg::priv_e       priv_imem,
    output core_pkg::priv_e       priv_dmem,
    output logic                  cfg_sum,
    output logic                  cfg_mxr,
    output core_pkg::satp_mode_e  cfg_satp_mode,
    output logic [21:0]           cfg_satp_ppn,
    // MTIME direct input
    input  logic [63:0]           mtime,
    // From external
    input  logic                  int_m_ext,
    input  logic                  mtimer_int
);

    import core_pkg::*;

    genvar i;

    localparam CSR_CYCLE         = 12'hC00;
    localparam CSR_TIME          = 12'hC01;
    localparam CSR_INSTRET       = 12'hC02;
    localparam CSR_CYCLEH        = 12'hC80;
    localparam CSR_TIMEH         = 12'hC81;
    localparam CSR_INSTRETH      = 12'hC82;

    localparam CSR_SSTATUS       = 12'h100;
    localparam CSR_SIE           = 12'h104;
    localparam CSR_STVEC         = 12'h105;
    localparam CSR_SCOUNTEREN    = 12'h106;

    localparam CSR_SSCRATCH      = 12'h140;
    localparam CSR_SEPC          = 12'h141;
    localparam CSR_SCAUSE        = 12'h142;
    localparam CSR_STVAL         = 12'h143;
    localparam CSR_SIP           = 12'h144;

    localparam CSR_SENVCFG       = 12'h10A;
    localparam CSR_SATP          = 12'h180;

    localparam CSR_MVENDORID     = 12'hF11;
    localparam CSR_MARCHID       = 12'hF12;
    localparam CSR_MIMPID        = 12'hF13;
    localparam CSR_MHARTID       = 12'hF14;
    localparam CSR_MCONFIGPTR    = 12'hF15;

    localparam CSR_MSTATUS       = 12'h300;
    localparam CSR_MISA          = 12'h301;
    localparam CSR_MEDELEG       = 12'h302;
    localparam CSR_MIDELEG       = 12'h303;
    localparam CSR_MIE           = 12'h304;
    localparam CSR_MTVEC         = 12'h305;
    localparam CSR_MCOUNTEREN    = 12'h306;
    localparam CSR_MSTATUSH      = 12'h310;
    localparam CSR_MEDELEGH      = 12'h312;

    localparam CSR_MSCRATCH      = 12'h340;
    localparam CSR_MEPC          = 12'h341;
    localparam CSR_MCAUSE        = 12'h342;
    localparam CSR_MTVAL         = 12'h343;
    localparam CSR_MIP           = 12'h344;

    localparam CSR_MENVCFG       = 12'h30A;
    localparam CSR_MENVCFGH      = 12'h31A;
    localparam CSR_MSECCFG       = 12'h747;
    localparam CSR_MSECCFGH      = 12'h757;

    localparam CSR_MCYCLE        = 12'hB00;
    localparam CSR_MINSTRET      = 12'hB02;
    localparam CSR_MCYCLEH       = 12'hB80;
    localparam CSR_MINSTRETH     = 12'hB82;
    localparam CSR_MCOUNTINHIBIT = 12'h320;

    localparam MISA_MXL_32       = 2'b01;
    localparam MISA_EXT_I        = 26'(1 << 8);
    localparam MISA_EXT_M        = 26'(1 << 12);
    localparam MISA_EXT_A        = 26'(1 << 0);
    localparam MISA_EXT_S        = 26'(1 << 18);
    localparam MISA_EXT_U        = 26'(1 << 20);
    localparam MISA_EXT          = MISA_EXT_I | MISA_EXT_M | MISA_EXT_A | MISA_EXT_S | MISA_EXT_U;

    typedef enum logic [1:0] {
        MTVEC_DIRECT   = 2'b00,
        MTVEC_VECTORED = 2'b01
    } mtvec_mode_e;
    
    // Decode signals
    logic         dec_cycle;
    logic         dec_time;
    logic         dec_instret;
    logic         dec_cycleh;
    logic         dec_timeh;
    logic         dec_instreth;

    logic         dec_sstatus;
    logic         dec_sie;
    logic         dec_stvec;
    logic         dec_scounteren;

    logic         dec_sscratch;
    logic         dec_sepc;
    logic         dec_scause;
    logic         dec_stval;
    logic         dec_sip;

    logic         dec_senvcfg;
    logic         dec_satp;

    logic         dec_mvendorid;
    logic         dec_marchid;
    logic         dec_mimpid;
    logic         dec_mhartid;
    logic         dec_mconfigptr;

    logic         dec_mstatus;
    logic         dec_misa;
    logic         dec_medeleg;
    logic         dec_mideleg;
    logic         dec_mie;
    logic         dec_mtvec;
    logic         dec_mcounteren;
    logic         dec_mstatush;
    logic         dec_medelegh;

    logic         dec_mscratch;
    logic         dec_mepc;
    logic         dec_mcause;
    logic         dec_mtval;
    logic         dec_mip;

    logic         dec_menvcfg;
    logic         dec_menvcfgh;
    logic         dec_mseccfg;
    logic         dec_mseccfgh;

    logic [15:0]  dec_pmpcfgx;
    logic [63:0]  dec_pmpaddrx;

    logic         dec_mcycle;
    logic         dec_minstret;
    logic [31:3]  dec_mhpmcounterx;
    logic         dec_mcycleh;
    logic         dec_minstreth;
    logic [31:3]  dec_mhpmcounterxh;

    logic         dec_mcountinhibit;
    logic [31:3]  dec_mhpmeventx;

    // Actual registers
    logic         sie;
    logic         mie;
    logic         spie;
    logic         mpie;
    spriv_e       spp;
    priv_e        mpp;
    logic         mprv;
    logic         sum;
    logic         mxr;
    logic         tvm;
    logic         tw;
    logic         tsr;

    logic [29:0]  stvec_base;
    mtvec_mode_e  stvec_mode;

    logic [29:0]  mtvec_base;
    mtvec_mode_e  mtvec_mode;

    logic [31:0]  medeleg;
    logic         medeleg_instr_misaligned;
    logic         medeleg_instr_access_fault;
    logic         medeleg_illegal_instr;
    logic         medeleg_breakpoint;
    logic         medeleg_load_misaligned;
    logic         medeleg_load_access_fault;
    logic         medeleg_store_misaligned;
    logic         medeleg_store_access_fault;
    logic         medeleg_ecall_umode;
    logic         medeleg_ecall_smode;
    logic         medeleg_instr_page_fault;
    logic         medeleg_load_page_fault;
    logic         medeleg_store_page_fault;
    logic         medeleg_software_check;
    logic         medeleg_hardware_error;

    logic         mideleg_se;
    logic         mideleg_st;
    logic         mideleg_ss;

    logic         seie;
    logic         stie;
    logic         ssie;
    logic         meie;
    logic         mtie;

    logic         seip;
    logic         stip;
    logic         ssip;

    logic [63:0]  mcycle;
    logic [63:0]  minstret;

    logic         scounteren_cy;
    logic         scounteren_tm;
    logic         scounteren_ir;

    logic         mcounteren_cy;
    logic         mcounteren_tm;
    logic         mcounteren_ir;

    logic         mcountinhibit_cy;
    logic         mcountinhibit_ir;

    logic [31:0]  sscratch;
    logic [31:0]  mscratch;

    logic [29:0]  sepc_base;
    logic [31:0]  scause;
    logic [31:0]  stval;

    logic [29:0]  mepc_base;
    logic [31:0]  mcause;
    logic [31:0]  mtval;

    logic         senvcfg_fiom;
    logic         menvcfg_fiom;

    satp_mode_e   satp_mode;
    logic [21:0]  satp_ppn;

    // Updated value
    logic [31:0]  csr_wdata;

    // Valid value check conditions
    logic         valid_mpp;
    logic         valid_mtvec_mode;

    // Counter helper
    logic [63:0]  next_mcycle;
    logic [63:0]  next_minstret;

    // Legal commands
    logic         legal_mret;
    logic         legal_sret;
    logic         legal_mread;
    logic         legal_mwrite;
    logic         legal_sread;
    logic         legal_swrite;
    logic         legal_uread;

    // Final write enable signal
    // Take into account the legality of the write
    logic         csr_write;
    logic         csr_write_en;

    // Trap helper
    logic         mtrap_valid;
    logic         strap_valid;

    // ------------------ CSR decode ------------------
    assign dec_cycle                    = (csr_id == CSR_CYCLE);
    assign dec_time                     = (csr_id == CSR_TIME);
    assign dec_instret                  = (csr_id == CSR_INSTRET);
    assign dec_cycleh                   = (csr_id == CSR_CYCLEH);
    assign dec_timeh                    = (csr_id == CSR_TIMEH);
    assign dec_instreth                 = (csr_id == CSR_INSTRETH);

    assign dec_sstatus                  = (csr_id == CSR_SSTATUS);
    assign dec_sie                      = (csr_id == CSR_SIE);
    assign dec_stvec                    = (csr_id == CSR_STVEC);
    assign dec_scounteren               = (csr_id == CSR_SCOUNTEREN);

    assign dec_sscratch                 = (csr_id == CSR_SSCRATCH);
    assign dec_sepc                     = (csr_id == CSR_SEPC);
    assign dec_scause                   = (csr_id == CSR_SCAUSE);
    assign dec_stval                    = (csr_id == CSR_STVAL);
    assign dec_sip                      = (csr_id == CSR_SIP);

    assign dec_senvcfg                  = (csr_id == CSR_SENVCFG);
    assign dec_satp                     = (csr_id == CSR_SATP);

    assign dec_mvendorid                = (csr_id == CSR_MVENDORID);
    assign dec_marchid                  = (csr_id == CSR_MARCHID);
    assign dec_mimpid                   = (csr_id == CSR_MIMPID);
    assign dec_mhartid                  = (csr_id == CSR_MHARTID);
    assign dec_mconfigptr               = (csr_id == CSR_MCONFIGPTR);

    assign dec_mstatus                  = (csr_id == CSR_MSTATUS);
    assign dec_misa                     = (csr_id == CSR_MISA);
    assign dec_medeleg                  = (csr_id == CSR_MEDELEG);
    assign dec_mideleg                  = (csr_id == CSR_MIDELEG);
    assign dec_mie                      = (csr_id == CSR_MIE);
    assign dec_mtvec                    = (csr_id == CSR_MTVEC);
    assign dec_mcounteren               = (csr_id == CSR_MCOUNTEREN);
    assign dec_mstatush                 = (csr_id == CSR_MSTATUSH);
    assign dec_medelegh                 = (csr_id == CSR_MEDELEGH);

    assign dec_mscratch                 = (csr_id == CSR_MSCRATCH);
    assign dec_mepc                     = (csr_id == CSR_MEPC);
    assign dec_mcause                   = (csr_id == CSR_MCAUSE);
    assign dec_mtval                    = (csr_id == CSR_MTVAL);
    assign dec_mip                      = (csr_id == CSR_MIP);

    assign dec_menvcfg                  = (csr_id == CSR_MENVCFG);
    assign dec_menvcfgh                 = (csr_id == CSR_MENVCFGH);
    assign dec_mseccfg                  = (csr_id == CSR_MSECCFG);
    assign dec_mseccfgh                 = (csr_id == CSR_MSECCFGH);

    generate for (i = 0; i < 16; i++)
        assign dec_pmpcfgx[i]           = (csr_id == 12'h3A0 + i);
    endgenerate

    generate for (i = 0; i < 64; i++)
        assign dec_pmpaddrx[i]          = (csr_id == 12'h3B0 + i);
    endgenerate

    assign dec_mcycle                   = (csr_id == CSR_MCYCLE);
    assign dec_minstret                 = (csr_id == CSR_MINSTRET);
    assign dec_mcycleh                  = (csr_id == CSR_MCYCLEH);
    assign dec_minstreth                = (csr_id == CSR_MINSTRETH);
    assign dec_mcountinhibit            = (csr_id == CSR_MCOUNTINHIBIT);

    generate
        for (i = 3; i < 32; i++) begin
            assign dec_mhpmcounterx [i] = (csr_id == 12'hB00 + i);
            assign dec_mhpmcounterxh[i] = (csr_id == 12'hB80 + i);
            assign dec_mhpmeventx   [i] = (csr_id == 12'h320 + i);
        end
    endgenerate

    // ------------------ Read data -------------------
    always_comb begin
        case (csr_id)
            CSR_CYCLE:         csr_rdata = mcycle[31:0];
            CSR_TIME:          csr_rdata = mtime[31:0];
            CSR_INSTRET:       csr_rdata = minstret[31:0];
            CSR_CYCLEH:        csr_rdata = mcycle[63:32];
            CSR_TIMEH:         csr_rdata = mtime[63:32];
            CSR_INSTRETH:      csr_rdata = minstret[63:32];

            CSR_SSTATUS:       csr_rdata = {12'b0, mxr, sum, 9'b0, spp, 2'b0, spie, 3'b0, sie, 1'b0};
            CSR_SIE:           csr_rdata = {22'b0, seie, 3'b0, stie, 3'b0, ssie, 1'b0};
            CSR_STVEC:         csr_rdata = {stvec_base, stvec_mode};
            CSR_SCOUNTEREN:    csr_rdata = {29'b0, scounteren_ir, scounteren_tm, scounteren_cy};

            CSR_SSCRATCH:      csr_rdata = sscratch;
            CSR_SEPC:          csr_rdata = {sepc_base, 2'b00};
            CSR_SCAUSE:        csr_rdata = scause;
            CSR_STVAL:         csr_rdata = stval;
            CSR_SIP:           csr_rdata = {22'b0, seip, 3'b0, stip, 3'b0, ssip, 1'b0};

            CSR_SENVCFG:       csr_rdata = {31'b0, senvcfg_fiom};
            CSR_SATP:          csr_rdata = {satp_mode, 9'b0, satp_ppn};

            CSR_MSTATUS:       csr_rdata = {9'b0, tsr, tw, tvm, mxr, sum, mprv, 4'b0, mpp, 2'b0, spp, mpie, 1'b0, spie, 1'b0, mie, 1'b0, sie, 1'b0};
            CSR_MSTATUSH:      csr_rdata = 32'b0;
            CSR_MISA:          csr_rdata = {MISA_MXL_32, 4'b0, MISA_EXT};
            CSR_MEDELEG:       csr_rdata = medeleg;
            CSR_MEDELEGH:      csr_rdata = 32'b0;
            CSR_MIDELEG:       csr_rdata = {22'b0, mideleg_se, 3'b0, mideleg_st, 3'b0, mideleg_ss, 1'b0};
            CSR_MIE:           csr_rdata = {20'b0, meie, 1'b0, seie, 1'b0, mtie, 1'b0, stie, 3'b0, ssie, 1'b0};
            CSR_MTVEC:         csr_rdata = {mtvec_base, mtvec_mode};
            CSR_MCOUNTEREN:    csr_rdata = {29'b0, mcounteren_ir, mcounteren_tm, mcounteren_cy};

            CSR_MSCRATCH:      csr_rdata = mscratch;
            CSR_MEPC:          csr_rdata = {mepc_base, 2'b00};
            CSR_MCAUSE:        csr_rdata = mcause;
            CSR_MTVAL:         csr_rdata = mtval;
            CSR_MIP:           csr_rdata = {20'b0, int_m_ext, 1'b0, seip, 1'b0, mtimer_int, 1'b0, stip, 3'b0, ssip, 1'b0};

            CSR_MENVCFG:       csr_rdata = {31'b0, menvcfg_fiom};

            CSR_MCYCLE:        csr_rdata = mcycle[31:0];
            CSR_MINSTRET:      csr_rdata = minstret[31:0];
            CSR_MCYCLEH:       csr_rdata = mcycle[63:32];
            CSR_MINSTRETH:     csr_rdata = minstret[63:32];
            CSR_MCOUNTINHIBIT: csr_rdata = {29'b0, mcountinhibit_ir, 1'b0, mcountinhibit_cy};

            default:           csr_rdata = 32'b0;
        endcase
    end

    assign medeleg = {
        12'b0,
        medeleg_hardware_error,
        medeleg_software_check,
        2'b0,
        medeleg_store_page_fault,
        1'b0,
        medeleg_load_page_fault,
        medeleg_instr_page_fault,
        2'b0,
        medeleg_ecall_smode,
        medeleg_ecall_umode,
        medeleg_store_access_fault,
        medeleg_store_misaligned,
        medeleg_load_access_fault,
        medeleg_load_misaligned,
        medeleg_breakpoint,
        medeleg_illegal_instr,
        medeleg_instr_access_fault,
        medeleg_instr_misaligned
    };

    // ------------------ Priv mode -------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)           priv <= PRIV_M;
        else if (mtrap_valid) priv <= PRIV_M;
        else if (strap_valid) priv <= PRIV_S;
        else if (legal_mret)  priv <= mpp;
        else if (legal_sret)  priv <= priv_e'({1'b0, spp});
    end

    // --------------- Trap condition -----------------
    always_comb begin
        if (m_interrupt_valid)    mtrap_valid = 1'b1;
        else if (exception_valid) mtrap_valid = (priv == PRIV_M) | (~medeleg[5'(exception_cause)]);
        else                      mtrap_valid = 1'b0;
    end

    always_comb begin
        if (s_interrupt_valid)    strap_valid = ~mtrap_valid;
        else if (exception_valid) strap_valid = ~mtrap_valid;
        else                      strap_valid = 1'b0;
    end

    // ----------------- Write data -------------------
    always_comb begin
        case (csr_upd)
            CSR_WRITE: csr_wdata = csr_udata;
            CSR_SET:   csr_wdata = csr_rdata | csr_udata;
            CSR_CLEAR: csr_wdata = csr_rdata & ~csr_udata;
            default:   csr_wdata = csr_rdata;
        endcase
    end

    assign csr_write    = (csr_upd != CSR_NONE);
    assign csr_write_en = csr_en & csr_write & ~exception_valid;

    // mstatus_sie
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                          sie <= 1'b0;
        else if (strap_valid)                                sie <= 1'b0;
        else if (legal_sret)                                 sie <= spie;
        else if (csr_write_en & (dec_mstatus | dec_sstatus)) sie <= csr_wdata[1];
    end

    // mstatus_mie
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                          mie <= 1'b0;
        else if (mtrap_valid)                mie <= 1'b0;
        else if (legal_mret)                 mie <= mpie;
        else if (csr_write_en & dec_mstatus) mie <= csr_wdata[3];
    end

    // mstatus_spie
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                          spie <= 1'b1;
        else if (strap_valid)                                spie <= sie;
        else if (legal_sret)                                 spie <= 1'b1;
        else if (csr_write_en & (dec_mstatus | dec_sstatus)) spie <= csr_wdata[5];
    end

    // mstatus_mpie
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                          mpie <= 1'b1;
        else if (mtrap_valid)                mpie <= mie;
        else if (legal_mret)                 mpie <= 1'b1;
        else if (csr_write_en & dec_mstatus) mpie <= csr_wdata[7];
    end

    // mstatus_spp
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                          spp <= SPRIV_U;
        else if (strap_valid)                                spp <= spriv_e'({priv}[0]);
        else if (legal_sret)                                 spp <= SPRIV_U;
        else if (csr_write_en & (dec_mstatus | dec_sstatus)) spp <= spriv_e'(csr_wdata[8]);
    end

    // mstatus_mpp
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                      mpp <= PRIV_U;
        else if (mtrap_valid)                            mpp <= priv;
        else if (legal_mret)                             mpp <= PRIV_U;
        else if (csr_write_en & dec_mstatus & valid_mpp) mpp <= priv_e'(csr_wdata[12:11]);
    end

    // mstatus_mprv
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                            mprv <= 1'b0;
        else if (legal_mret & (mpp != PRIV_M)) mprv <= 1'b0;
        else if (csr_write_en & dec_mstatus)   mprv <= csr_wdata[17];
    end

    // mstatus/sstatus common
    floper #(
        .WIDTH    (2),
        .RST_VAL  (0)
    ) u_flop_sstatus(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & (dec_mstatus | dec_sstatus)),
        .d        (csr_wdata[19:18]),
        .q        ({mxr, sum})
    );

    // mstatus only
    floper #(
        .WIDTH    (3),
        .RST_VAL  (0)
    ) u_flop_mstatus(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mstatus),
        .d        (csr_wdata[22:20]),
        .q        ({tsr, tw, tvm})
    );

    // stvec_base
    floper #(
        .WIDTH    (30),
        .RST_VAL  (0)
    ) u_flop_stvec_base(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_stvec),
        .d        (csr_wdata[31:2]),
        .q        (stvec_base)
    );

    // stvec_mode
    floper #(
        .WIDTH    (2),
        .RST_VAL  (MTVEC_DIRECT)
    ) u_flop_stvec_mode(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_stvec & valid_mtvec_mode),
        .d        (csr_wdata[1:0]),
        .q        (stvec_mode)
    );

    // mtvec_base
    floper #(
        .WIDTH    (30),
        .RST_VAL  (0)
    ) u_flop_mtvec_base(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mtvec),
        .d        (csr_wdata[31:2]),
        .q        (mtvec_base)
    );

    // mtvec_mode
    floper #(
        .WIDTH    (2),
        .RST_VAL  (MTVEC_DIRECT)
    ) u_flop_mtvec_mode(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mtvec & valid_mtvec_mode),
        .d        (csr_wdata[1:0]),
        .q        (mtvec_mode)
    );

    // medeleg
    floper #(
        .WIDTH    (15),
        .RST_VAL  (0)
    ) u_flop_medeleg(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_medeleg),
        .d        ({
            csr_wdata[0],
            csr_wdata[1],
            csr_wdata[2],
            csr_wdata[3],
            csr_wdata[4],
            csr_wdata[5],
            csr_wdata[6],
            csr_wdata[7],
            csr_wdata[8],
            csr_wdata[9],
            csr_wdata[12],
            csr_wdata[13],
            csr_wdata[15],
            csr_wdata[18],
            csr_wdata[19]
        }),
        .q        ({
            medeleg_instr_misaligned,
            medeleg_instr_access_fault,
            medeleg_illegal_instr,
            medeleg_breakpoint,
            medeleg_load_misaligned,
            medeleg_load_access_fault,
            medeleg_store_misaligned,
            medeleg_store_access_fault,
            medeleg_ecall_umode,
            medeleg_ecall_smode,
            medeleg_instr_page_fault,
            medeleg_load_page_fault,
            medeleg_store_page_fault,
            medeleg_software_check,
            medeleg_hardware_error
        })
    );

    // mideleg
    floper #(
        .WIDTH    (3),
        .RST_VAL  (0)
    ) u_flop_mideleg(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mideleg),
        .d        ({csr_wdata[1], csr_wdata[5], csr_wdata[9]}),
        .q        ({mideleg_ss,   mideleg_st,   mideleg_se})
    );

    // sie
    floper #(
        .WIDTH    (3),
        .RST_VAL  (0)
    ) u_flop_sie(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & (dec_mie | dec_sie)),
        .d        ({csr_wdata[9], csr_wdata[5], csr_wdata[1]}),
        .q        ({seie, stie, ssie})
    );

    // mie
    floper #(
        .WIDTH    (2),
        .RST_VAL  (0)
    ) u_flop_mie(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mie),
        .d        ({csr_wdata[11], csr_wdata[7]}),
        .q        ({meie, mtie})
    );

    // sip
    floper #(
        .WIDTH    (1),
        .RST_VAL  (0)
    ) u_flop_sip(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & (dec_mip | dec_sip)),
        .d        (csr_wdata[1]),
        .q        (ssip)
    );

    // mip
    floper #(
        .WIDTH    (2),
        .RST_VAL  (0)
    ) u_flop_mip(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mip),
        .d        ({csr_wdata[9], csr_wdata[5]}),
        .q        ({seip, stip})
    );

    // mcycle
    assign next_mcycle = (~mcountinhibit_cy) ? (mcycle + 1'b1) : mcycle;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                          mcycle <= 64'd0;
        else if (csr_write_en & dec_mcycle)  mcycle <= {next_mcycle[63:32], csr_wdata};
        else if (csr_write_en & dec_mcycleh) mcycle <= {csr_wdata, next_mcycle[31:0]};
        else                                 mcycle <= next_mcycle;
    end

    // minstret
    assign next_minstret = (~mcountinhibit_ir & instr_done & ~exception_valid) ? (minstret + 1'b1) : minstret;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                            minstret <= 64'd0;
        else if (csr_write_en & dec_minstret)  minstret <= {next_minstret[63:32], csr_wdata};
        else if (csr_write_en & dec_minstreth) minstret <= {csr_wdata, next_minstret[31:0]};
        else                                   minstret <= next_minstret;
    end

    // scounteren
    floper #(
        .WIDTH    (3),
        .RST_VAL  (0)
    ) u_flop_scounteren(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_scounteren),
        .d        (csr_wdata[2:0]),
        .q        ({scounteren_ir, scounteren_tm, scounteren_cy})
    );

    // mcounteren
    floper #(
        .WIDTH    (3),
        .RST_VAL  (0)
    ) u_flop_mcounteren(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mcounteren),
        .d        (csr_wdata[2:0]),
        .q        ({mcounteren_ir, mcounteren_tm, mcounteren_cy})
    );

    // mcountinhibit
    floper #(
        .WIDTH    (2),
        .RST_VAL  (0)
    ) u_flop_mcountinhibit(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mcountinhibit),
        .d        ({csr_wdata[2], csr_wdata[0]}),
        .q        ({mcountinhibit_ir, mcountinhibit_cy})
    );

    // sscratch
    floper #(
        .WIDTH    (32),
        .RST_VAL  (0)
    ) u_flop_sscratch(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_sscratch),
        .d        (csr_wdata),
        .q        (sscratch)
    );

    // mscratch
    floper #(
        .WIDTH    (32),
        .RST_VAL  (0)
    ) u_flop_mscratch(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mscratch),
        .d        (csr_wdata),
        .q        (mscratch)
    );

    // sepc
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       sepc_base <= 30'b0;
        else if (strap_valid)             sepc_base <= pc[31:2];
        else if (csr_write_en & dec_sepc) sepc_base <= csr_wdata[31:2];
    end

    // mepc
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       mepc_base <= 30'b0;
        else if (mtrap_valid)             mepc_base <= pc[31:2];
        else if (csr_write_en & dec_mepc) mepc_base <= csr_wdata[31:2];
    end

    // scause
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                             scause <= 32'b0;
        else if (s_interrupt_valid)             scause <= {1'b1, 31'(s_interrupt_cause)};
        else if (strap_valid & exception_valid) scause <= 32'(exception_cause);
        else if (csr_write_en & dec_scause)     scause <= csr_wdata;
    end

    // mcause
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                             mcause <= 32'b0;
        else if (m_interrupt_valid)             mcause <= {1'b1, 31'(m_interrupt_cause)};
        else if (mtrap_valid & exception_valid) mcause <= 32'(exception_cause);
        else if (csr_write_en & dec_mcause)     mcause <= csr_wdata;
    end

    // stval
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                             stval <= 32'b0;
        else if (s_interrupt_valid)             stval <= 32'b0;
        else if (strap_valid & exception_valid) stval <= exception_value;
        else if (csr_write_en & dec_stval)      stval <= csr_wdata;
    end

    // mtval
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                             mtval <= 32'b0;
        else if (m_interrupt_valid)             mtval <= 32'b0;
        else if (mtrap_valid & exception_valid) mtval <= exception_value;
        else if (csr_write_en & dec_mtval)      mtval <= csr_wdata;
    end

    // senvcfg
    floper #(
        .WIDTH    (1),
        .RST_VAL  (0)
    ) u_flop_senvcfg(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_senvcfg),
        .d        (csr_wdata[0]),
        .q        (senvcfg_fiom)
    );

    // menvcfg
    floper #(
        .WIDTH    (1),
        .RST_VAL  (0)
    ) u_flop_menvcfg(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_menvcfg),
        .d        (csr_wdata[0]),
        .q        (menvcfg_fiom)
    );

    // satp
    floper #(
        .WIDTH    (23),
        .RST_VAL  (0)
    ) u_flop_satp(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_satp),
        .d        ({csr_wdata[31], csr_wdata[21:0]}),
        .q        ({satp_mode, satp_ppn})
    );

    // -------------- Effective privilege -------------
    assign priv_imem = priv;
    assign priv_dmem = mprv ? mpp : priv;

    // -------------- Configuration output ------------
    assign cfg_mie        = mie;
    assign cfg_sie        = sie;
    assign cfg_meie       = meie;
    assign cfg_mtie       = mtie;
    assign cfg_seie       = seie;
    assign cfg_stie       = stie;
    assign cfg_ssie       = ssie;
    assign cfg_seip       = seip;
    assign cfg_stip       = stip;
    assign cfg_ssip       = ssip;
    assign cfg_mideleg_se = mideleg_se;
    assign cfg_mideleg_st = mideleg_st;
    assign cfg_mideleg_ss = mideleg_ss;

    assign cfg_mxr        = mxr;
    assign cfg_sum        = sum;
    assign cfg_satp_mode  = satp_mode;
    assign cfg_satp_ppn   = satp_ppn;

    // --------------- Valid value check --------------
    // mstatus_mpp
    always_comb begin
        case (csr_wdata[12:11])
            PRIV_M,
            PRIV_S,
            PRIV_U:  valid_mpp = 1'b1;
            default: valid_mpp = 1'b0;
        endcase
    end

    // mtvec_mode
    always_comb begin
        case (csr_wdata[1:0])
            MTVEC_DIRECT,
            MTVEC_VECTORED: valid_mtvec_mode = 1'b1;
            default:        valid_mtvec_mode = 1'b0;
        endcase
    end

    // ----------------- Trap address -----------------
    always_comb begin
        if (mtrap_valid) begin
            pc_csr_valid = 1'b1;
            case (mtvec_mode)
                MTVEC_DIRECT:   pc_csr = {mtvec_base, 2'b00};
                MTVEC_VECTORED: pc_csr = {mtvec_base + 30'(m_interrupt_valid ? m_interrupt_cause : 5'b0), 2'b00};
                default:        pc_csr = 'x;
            endcase
        end
        else if (strap_valid) begin
            pc_csr_valid = 1'b1;
            case (stvec_mode)
                MTVEC_DIRECT:   pc_csr = {stvec_base, 2'b00};
                MTVEC_VECTORED: pc_csr = {stvec_base + 30'(s_interrupt_valid ? s_interrupt_cause : 5'b0), 2'b00};
                default:        pc_csr = 'x;
            endcase
        end
        else if (legal_mret) begin
            pc_csr_valid = 1'b1;
            pc_csr       = {mepc_base, 2'b00};
        end
        else if (legal_sret) begin
            pc_csr_valid = 1'b1;
            pc_csr       = {sepc_base, 2'b00};
        end
        else begin
            pc_csr_valid = 1'b0;
            pc_csr       = 'x;
        end
    end

    // --------------- Illegal access -----------------
    always_comb begin
        if (csr_en) begin
            case (priv)
                PRIV_M:  ex_csr_illegal_instr = |{
                    csr_read & ~legal_mread,
                    csr_write & ~legal_mwrite
                };
                PRIV_S:  ex_csr_illegal_instr = |{
                    csr_read & ~legal_sread,
                    csr_write & ~legal_swrite,
                    mret,
                    sret & tsr,
                    sfence_vma & tvm,
                    wfi & tw
                };
                default: ex_csr_illegal_instr = |{
                    csr_read & ~legal_uread,
                    csr_write,
                    mret,
                    sret,
                    sfence_vma,
                    wfi
                };
            endcase
        end
        else ex_csr_illegal_instr = 1'b0;
    end

    assign legal_mret = csr_en & (priv == PRIV_M) & mret;

    always_comb begin
        if (csr_en) begin
            case (priv)
                PRIV_M:  legal_sret = sret;
                PRIV_S:  legal_sret = sret & ~tsr;
                default: legal_sret = 1'b0;
            endcase
        end
        else legal_sret = 1'b0;
    end

    assign legal_mread = |{
        // U-mode
        dec_cycle,
        dec_time,
        dec_instret,
        dec_cycleh,
        dec_timeh,
        dec_instreth,
        // S-mode
        dec_sstatus,
        dec_sie,
        dec_stvec,
        dec_scounteren,
        dec_sscratch,
        dec_sepc,
        dec_scause,
        dec_stval,
        dec_sip,
        dec_senvcfg,
        dec_satp,
        // M-mode
        dec_mvendorid,
        dec_marchid,
        dec_mimpid,
        dec_mhartid,
        dec_mconfigptr,
        dec_mstatus,
        dec_misa,
        dec_medeleg,
        dec_mideleg,
        dec_mie,
        dec_mtvec,
        dec_mcounteren,
        dec_mstatush,
        dec_medelegh,
        dec_mscratch,
        dec_mepc,
        dec_mcause,
        dec_mtval,
        dec_mip,
        dec_menvcfg,
        dec_menvcfgh,
        dec_mseccfg,
        dec_mseccfgh,
        // dec_pmpcfgx,
        // dec_pmpaddrx,
        dec_mcycle,
        dec_minstret,
        dec_mhpmcounterx,
        dec_mcycleh,
        dec_minstreth,
        dec_mhpmcounterxh,
        dec_mcountinhibit,
        dec_mhpmeventx
    };

    assign legal_mwrite = |{
        // S-mode
        dec_sstatus,
        dec_sie,
        dec_stvec,
        dec_scounteren,
        dec_sscratch,
        dec_sepc,
        dec_scause,
        dec_stval,
        dec_sip,
        dec_senvcfg,
        dec_satp,
        // M-mode
        dec_mstatus,
        dec_misa,
        dec_medeleg,
        dec_mideleg,
        dec_mie,
        dec_mtvec,
        dec_mcounteren,
        dec_mstatush,
        dec_medelegh,
        dec_mscratch,
        dec_mepc,
        dec_mcause,
        dec_mtval,
        dec_mip,
        dec_menvcfg,
        dec_menvcfgh,
        dec_mseccfg,
        dec_mseccfgh,
        // dec_pmpcfgx,
        // dec_pmpaddrx,
        dec_mcycle,
        dec_minstret,
        dec_mhpmcounterx,
        dec_mcycleh,
        dec_minstreth,
        dec_mhpmcounterxh,
        dec_mcountinhibit,
        dec_mhpmeventx
    };

    assign legal_sread = |{
        // U-mode
        dec_cycle    & mcounteren_cy,
        dec_time     & mcounteren_tm,
        dec_instret  & mcounteren_ir,
        dec_cycleh   & mcounteren_cy,
        dec_timeh    & mcounteren_tm,
        dec_instreth & mcounteren_ir,
        // S-mode
        dec_sstatus,
        dec_sie,
        dec_stvec,
        dec_scounteren,
        dec_sscratch,
        dec_sepc,
        dec_scause,
        dec_stval,
        dec_sip,
        dec_senvcfg,
        dec_satp & ~tvm
    };

    assign legal_swrite = |{
        // S-mode
        dec_sstatus,
        dec_sie,
        dec_stvec,
        dec_scounteren,
        dec_sscratch,
        dec_sepc,
        dec_scause,
        dec_stval,
        dec_sip,
        dec_senvcfg,
        dec_satp & ~tvm
    };

    assign legal_uread = |{
        dec_cycle    & mcounteren_cy & scounteren_cy,
        dec_time     & mcounteren_tm & scounteren_tm,
        dec_instret  & mcounteren_ir & scounteren_ir,
        dec_cycleh   & mcounteren_cy & scounteren_cy,
        dec_timeh    & mcounteren_tm & scounteren_tm,
        dec_instreth & mcounteren_ir & scounteren_ir
    };

endmodule
