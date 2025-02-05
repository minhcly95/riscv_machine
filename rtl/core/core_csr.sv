module core_csr (
    input  logic                  clk,
    input  logic                  rst_n,
    // From Controller
    input  logic                  csr_en,
    input  logic                  instr_done,
    // From/to EXEC stage
    input  logic [11:0]           csr_id,
    input  logic                  csr_read,
    input  logic                  csr_write,
    output logic [31:0]           csr_rdata,
    input  logic [31:0]           csr_wdata,
    input  logic                  mret,
    // From FETCH stage
    input  logic [31:0]           pc,
    // To FETCH stage
    output logic                  pc_csr_valid,
    output logic [31:0]           pc_csr,
    // From Trap handler
    input  logic                  exception_valid,
    input  core_pkg::exception_e  exception_cause,
    input  logic [31:0]           exception_value,
    input  logic                  interrupt_valid,
    input  core_pkg::interrupt_e  interrupt_cause,
    // To Trap handler
    output core_pkg::priv_e       priv,
    output logic                  cfg_mie,
    output logic                  cfg_meie,
    output logic                  cfg_mtie,
    output logic                  ex_csr_illegal_instr,
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
    localparam MISA_EXT_U        = 26'(1 << 20);
    localparam MISA_EXT          = MISA_EXT_I | MISA_EXT_M | MISA_EXT_A | MISA_EXT_U;

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
    logic         mie;
    logic         mpie;
    priv_e        mpp;
    logic         mprv;
    logic         tw;

    logic [29:0]  mtvec_base;
    mtvec_mode_e  mtvec_mode;

    logic         meie;
    logic         mtie;

    logic [63:0]  mcycle;
    logic [63:0]  minstret;

    logic         mcounteren_cy;
    logic         mcounteren_tm;
    logic         mcounteren_ir;

    logic         mcountinhibit_cy;
    logic         mcountinhibit_ir;

    logic [31:0]  mscratch;

    logic [29:0]  mepc_base;
    logic [31:0]  mcause;
    logic [31:0]  mtval;

    // Valid value check conditions
    logic         valid_mpp;
    logic         valid_mtvec_mode;

    // Counter helper
    logic [63:0]  next_mcycle;
    logic [63:0]  next_minstret;

    // Legal commands
    logic         legal_mret;
    logic         legal_mread;
    logic         legal_mwrite;
    logic         legal_uread;

    // Final write enable signal
    // Take into account the legality of the write
    logic         csr_write_en;

    // Trap helper
    logic         trap_valid;

    // ------------------ CSR decode ------------------
    assign dec_cycle                    = (csr_id == CSR_CYCLE);
    assign dec_time                     = (csr_id == CSR_TIME);
    assign dec_instret                  = (csr_id == CSR_INSTRET);
    assign dec_cycleh                   = (csr_id == CSR_CYCLEH);
    assign dec_timeh                    = (csr_id == CSR_TIMEH);
    assign dec_instreth                 = (csr_id == CSR_INSTRETH);

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
            CSR_TIME:          csr_rdata = mcycle[31:0];
            CSR_INSTRET:       csr_rdata = minstret[31:0];
            CSR_CYCLEH:        csr_rdata = mcycle[63:32];
            CSR_TIMEH:         csr_rdata = mcycle[63:32];
            CSR_INSTRETH:      csr_rdata = minstret[63:32];

            CSR_MSTATUS:       csr_rdata = {10'b0, tw, 3'b0, mprv, 4'b0, mpp, 3'b0, mpie, 3'b0, mie, 3'b0};
            CSR_MSTATUSH:      csr_rdata = 32'b0;
            CSR_MISA:          csr_rdata = {MISA_MXL_32, 4'b0, MISA_EXT};
            CSR_MIE:           csr_rdata = {20'b0, meie, 3'b0, mtie, 7'b0};
            CSR_MTVEC:         csr_rdata = {mtvec_base, mtvec_mode};
            CSR_MCOUNTEREN:    csr_rdata = {29'b0, mcounteren_ir, mcounteren_tm, mcounteren_cy};

            CSR_MSCRATCH:      csr_rdata = mscratch;
            CSR_MEPC:          csr_rdata = {mepc_base, 2'b00};
            CSR_MCAUSE:        csr_rdata = mcause;
            CSR_MTVAL:         csr_rdata = mtval;
            CSR_MIP:           csr_rdata = {20'b0, int_m_ext, 3'b0, mtimer_int, 7'b0};

            CSR_MCYCLE:        csr_rdata = mcycle[31:0];
            CSR_MINSTRET:      csr_rdata = minstret[31:0];
            CSR_MCYCLEH:       csr_rdata = mcycle[63:32];
            CSR_MINSTRETH:     csr_rdata = minstret[63:32];
            CSR_MCOUNTINHIBIT: csr_rdata = {29'b0, mcountinhibit_ir, 1'b0, mcountinhibit_cy};

            default:           csr_rdata = 32'b0;
        endcase
    end

    // ------------------ Priv mode -------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)          priv <= PRIV_M;
        else if (trap_valid) priv <= PRIV_M;
        else if (legal_mret) priv <= mpp;
    end

    // ----------------- Write data -------------------
    assign trap_valid   = exception_valid | interrupt_valid;
    assign legal_mret   = csr_en & (priv == PRIV_M) & mret;
    assign csr_write_en = csr_en & csr_write & ~exception_valid;

    // mstatus_mie
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                          mie <= 1'b0;
        else if (trap_valid)                 mie <= 1'b0;
        else if (legal_mret)                 mie <= mpie;
        else if (csr_write_en & dec_mstatus) mie <= csr_wdata[3];
    end

    // mstatus_mpie
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                          mpie <= 1'b1;
        else if (trap_valid)                 mpie <= mie;
        else if (legal_mret)                 mpie <= 1'b1;
        else if (csr_write_en & dec_mstatus) mpie <= csr_wdata[7];
    end

    // mstatus_mpp
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                      mpp <= PRIV_U;
        else if (trap_valid)                             mpp <= priv;
        else if (legal_mret)                             mpp <= PRIV_U;
        else if (csr_write_en & dec_mstatus & valid_mpp) mpp <= priv_e'(csr_wdata[12:11]);
    end

    // mstatus_mprv
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                            mprv <= 1'b0;
        else if (legal_mret & (mpp != PRIV_M)) mprv <= 1'b0;
        else if (csr_write_en & dec_mstatus)   mprv <= csr_wdata[17];
    end

    // mstatus_tw
    floper #(
        .WIDTH    (1),
        .RST_VAL  (0)
    ) u_flop_tw(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (csr_write_en & dec_mstatus),
        .d        (csr_wdata[21]),
        .q        (tw)
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

    // mepc
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       mepc_base <= 30'b0;
        else if (trap_valid)              mepc_base <= pc[31:2];
        else if (csr_write_en & dec_mepc) mepc_base <= csr_wdata[31:2];
    end

    // mcause
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         mcause <= 32'b0;
        else if (interrupt_valid)           mcause <= {1'b1, 31'(interrupt_cause)};
        else if (exception_valid)           mcause <= 32'(exception_cause);
        else if (csr_write_en & dec_mcause) mcause <= csr_wdata;
    end

    // mtval
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                        mtval <= 32'b0;
        else if (interrupt_valid)          mtval <= 32'b0;
        else if (exception_valid)          mtval <= exception_value;
        else if (csr_write_en & dec_mtval) mtval <= csr_wdata;
    end

    // -------------- Configuration output ------------
    assign cfg_mie  = mie;
    assign cfg_meie = meie;
    assign cfg_mtie = mtie;

    // --------------- Valid value check --------------
    // mstatus_mpp
    always_comb begin
        case (csr_wdata[12:11])
            PRIV_M,
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
        if (trap_valid) begin
            pc_csr_valid = 1'b1;
            case (mtvec_mode)
                MTVEC_DIRECT:   pc_csr = {mtvec_base, 2'b00};
                MTVEC_VECTORED: pc_csr = {mtvec_base + 30'(interrupt_valid ? interrupt_cause : 5'b0), 2'b00};
                default:        pc_csr = 'x;
            endcase
        end
        else if (legal_mret) begin
            pc_csr_valid = 1'b1;
            pc_csr       = {mepc_base, 2'b00};
        end
        else begin
            pc_csr_valid = 1'b0;
            pc_csr       = 'x;
        end
    end

    // --------------- Illegal access -----------------
    always_comb begin
        if (csr_en) begin
            if (priv == PRIV_M)
                ex_csr_illegal_instr = (csr_read & ~legal_mread) | (csr_write & ~legal_mwrite);
            else
                ex_csr_illegal_instr = (csr_read & ~legal_uread) | csr_write | mret;
        end
        else
            ex_csr_illegal_instr = 1'b0;
    end

    assign legal_mread = |{
        // U-mode
        dec_cycle,
        dec_time,
        dec_instret,
        dec_cycleh,
        dec_timeh,
        dec_instreth,
        // M-mode
        dec_mvendorid,
        dec_marchid,
        dec_mimpid,
        dec_mhartid,
        dec_mconfigptr,
        dec_mstatus,
        dec_misa,
        // dec_medeleg,
        // dec_mideleg,
        dec_mie,
        dec_mtvec,
        dec_mcounteren,
        dec_mstatush,
        // dec_medelegh,
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
        dec_mstatus,
        dec_misa,
        // dec_medeleg,
        // dec_mideleg,
        dec_mie,
        dec_mtvec,
        dec_mcounteren,
        dec_mstatush,
        // dec_medelegh,
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

    assign legal_uread = |{
        dec_cycle    & mcounteren_cy,
        dec_time     & mcounteren_tm,
        dec_instret  & mcounteren_ir,
        dec_cycleh   & mcounteren_cy,
        dec_timeh    & mcounteren_tm,
        dec_instreth & mcounteren_ir
    };

endmodule
