module core_mem_if (
    input  logic                  clk,
    input  logic                  rst_n,
    // From FETCH stage
    input  logic                  imem_valid,
    output logic                  imem_ready,
    input  logic [31:0]           imem_addr,
    output logic [31:0]           imem_rdata,
    // From MEM stage
    input  logic                  dmem_valid,
    output logic                  dmem_ready,
    input  logic [31:0]           dmem_addr,
    input  core_pkg::mem_dir_e    dmem_dir,
    input  logic [31:0]           dmem_wdata,
    input  logic  [3:0]           dmem_wstrb,
    output logic [31:0]           dmem_rdata,
    // APB master
    output logic                  psel,
    output logic                  penable,
    input  logic                  pready,
    output logic [33:0]           paddr,
    output logic                  pwrite,
    output logic [31:0]           pwdata,
    output logic  [3:0]           pwstrb,
    input  logic [31:0]           prdata,
    input  logic                  pslverr,
    // From CSR
    input  core_pkg::priv_e       priv_imem,
    input  core_pkg::priv_e       priv_dmem,
    input  logic                  cfg_sum,
    input  logic                  cfg_mxr,
    input  core_pkg::satp_mode_e  cfg_satp_mode,
    input  logic [21:0]           cfg_satp_ppn,
    // To Trap handler
    output logic                  ex_instr_access_fault,
    output logic                  ex_load_access_fault,
    output logic                  ex_store_access_fault,
    output logic                  ex_instr_page_fault,
    output logic                  ex_load_page_fault,
    output logic                  ex_store_page_fault
);

    import core_pkg::*;

    typedef enum logic [2:0] {
        IDLE,
        TRANS1,
        TRANS0,
        ACCESS1,        // Megapage access
        ACCESS0,        // Normal page access
        BARE            // Bare-mode access
    } state_e;

    typedef struct packed {
        logic [11:0]  ppn1;
        logic [9:0]   ppn0;
        logic [1:0]   rsw;
        logic         d;
        logic         a;
        logic         g;
        logic         u;
        logic         x;
        logic         w;
        logic         r;
        logic         v;
    } pte_t;

    state_e       curr_state;
    state_e       next_state;

    logic         apb_step;

    logic         mem_if_start;
    logic         mem_if_done;
    logic [31:0]  mem_if_addr;
    mem_dir_e     mem_if_dir;
    logic         mem_if_err;

    logic         satp_active;

    logic [33:0]  trans1_paddr;
    logic [33:0]  trans0_paddr;
    logic [33:0]  access1_paddr;
    logic [33:0]  access0_paddr;

    logic [21:0]  curr_ppn;

    pte_t         pte;
    logic         invalid_pte;
    logic         leaf_pte;
    logic         invalid_access;
    logic         unpriv_access;
    logic         svade;

    logic         access_fault;
    logic         page_fault;

    // Handshake
    // Although there are 2 input interfaces,
    // no arbiter is needed since FETCH and MEM do not coexist.
    assign apb_step     = penable & pready;

    assign mem_if_start = imem_valid | dmem_valid;
    assign mem_if_done  = (curr_state != IDLE) & (next_state == IDLE);

    assign imem_ready   = imem_valid & mem_if_done;
    assign dmem_ready   = dmem_valid & mem_if_done;

    // Translation active
    always_comb begin
        if (cfg_satp_mode == SATP_SV32)
            satp_active = |{
                imem_valid & (priv_imem != PRIV_M),
                dmem_valid & (priv_dmem != PRIV_M)
            };
        else
            satp_active = 1'b0;
    end

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) curr_state <= IDLE;
        else        curr_state <= next_state;
    end

    // Transition
    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE: if (mem_if_start) next_state = satp_active ? TRANS1 : BARE;
            TRANS1: if (apb_step) begin
                if (mem_if_err)     next_state = IDLE;
                else if (leaf_pte)  next_state = ACCESS1; // Megapage
                else                next_state = TRANS0;
            end
            TRANS0: if (apb_step) begin
                if (mem_if_err)     next_state = IDLE;
                else                next_state = ACCESS0;
            end
            ACCESS1, ACCESS0, BARE:
                if (apb_step)       next_state = IDLE;
            default:                next_state = IDLE;
        endcase
    end

    // APB request
    always_comb begin
        case (curr_state)
            IDLE: begin
                psel   = mem_if_start;
                paddr  = satp_active ? trans1_paddr : {2'b0, mem_if_addr};
                pwrite = satp_active ? 1'b0         : (mem_if_dir == MEM_WRITE);
            end
            TRANS1: begin
                psel   = 1'b1;
                paddr  = trans1_paddr;
                pwrite = 1'b0;
            end
            TRANS0: begin
                psel   = 1'b1;
                paddr  = trans0_paddr;
                pwrite = 1'b0;
            end
            ACCESS1: begin
                psel   = 1'b1;
                paddr  = access1_paddr;
                pwrite = (mem_if_dir == MEM_WRITE);
            end
            ACCESS0: begin
                psel   = 1'b1;
                paddr  = access0_paddr;
                pwrite = (mem_if_dir == MEM_WRITE);
            end
            BARE: begin
                psel   = 1'b1;
                paddr  = {2'b0, mem_if_addr};
                pwrite = (mem_if_dir == MEM_WRITE);
            end
            default: begin
                psel   = 1'b0;
                paddr  = 34'b0;
                pwrite = 1'b0;
            end
        endcase
    end

    assign mem_if_addr   = dmem_valid ? dmem_addr : imem_addr;
    assign mem_if_dir    = dmem_valid ? dmem_dir  : MEM_EXEC;

    assign trans1_paddr  = {cfg_satp_ppn,    mem_if_addr[31:22], 2'b0};
    assign trans0_paddr  = {curr_ppn,        mem_if_addr[21:12], 2'b0};
    assign access1_paddr = {curr_ppn[21:10], mem_if_addr[21:0]};    // 4MB megapage
    assign access0_paddr = {curr_ppn,        mem_if_addr[11:0]};    // 4kB normal page

    assign pwdata        = dmem_wdata;
    assign pwstrb        = dmem_wstrb;

    // Response
    assign imem_rdata    = prdata;
    assign dmem_rdata    = prdata;

    // PENABLE flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       penable <= 1'b0;
        else if (psel & penable & pready) penable <= 1'b0;
        else                              penable <= psel;
    end

    // Current PPN flop
    flope #(
        .WIDTH  (22)
    ) u_flop_ppn(
        .clk    (clk),
        .en     (apb_step),
        .d      ({pte.ppn1, pte.ppn0}),
        .q      (curr_ppn)
    );

    // PTE parsing
    assign pte            = prdata;
    assign invalid_pte    = ~pte.v | (pte.w & ~pte.r);
    assign leaf_pte       = pte.r | pte.x;

    // Check if the access type is allowed
    // If MXR is set, loads from X-pages are allowed
    always_comb begin
        case (mem_if_dir)
            MEM_EXEC:     invalid_access = ~pte.x;
            MEM_READ:     invalid_access = cfg_mxr ? ~(pte.r | pte.x) : ~pte.r;
            MEM_WRITE,
            MEM_READ_AMO: invalid_access = ~pte.w;
        endcase
    end

    // Check if the access has matching privilege
    // If SUM is set, S-mode is allowed to load/store U-pages
    always_comb begin
        case (priv_dmem)
            PRIV_M,
            PRIV_S:  unpriv_access = (cfg_sum & (mem_if_dir != MEM_EXEC)) ? 1'b0 : pte.u;
            default: unpriv_access = ~pte.u;
        endcase
    end

    // Check if A/D bits are cleared on leaf node
    // Only check D bit on stores
    always_comb begin
        if (~pte.a)       svade = 1'b1;
        else case (mem_if_dir)
            MEM_WRITE,
            MEM_READ_AMO: svade = ~pte.d;
            default:      svade = 1'b0;
        endcase
    end

    // Fault conditions
    always_comb begin
        access_fault = 1'b0;
        page_fault   = 1'b0;

        case (curr_state)
            TRANS1: if (apb_step) begin
                if (pslverr)          access_fault = 1'b1;
                else if (invalid_pte) page_fault   = 1'b1;
                else if (leaf_pte) begin
                    if (|pte.ppn0)    page_fault   = 1'b1;  // Misaligned megapage
                    else              page_fault   = invalid_access | unpriv_access | svade;
                end
            end
            TRANS0: if (apb_step) begin
                if (pslverr)          access_fault = 1'b1;
                else if (invalid_pte) page_fault   = 1'b1;
                else if (leaf_pte)    page_fault   = invalid_access | unpriv_access | svade;
                else                  page_fault   = 1'b1;  // End of translation, must be a leaf
            end
            default: if (apb_step)    access_fault = pslverr;
        endcase
    end

    assign mem_if_err = access_fault | page_fault;

    // Mapping faults to exception code
    always_comb begin
        ex_instr_access_fault = 1'b0;
        ex_load_access_fault  = 1'b0;
        ex_store_access_fault = 1'b0;
        ex_instr_page_fault   = 1'b0;
        ex_load_page_fault    = 1'b0;
        ex_store_page_fault   = 1'b0;

        case (mem_if_dir)
            MEM_EXEC: begin
                ex_instr_access_fault = access_fault;
                ex_instr_page_fault   = page_fault;
            end
            MEM_READ: begin
                ex_load_access_fault  = access_fault;
                ex_load_page_fault    = page_fault;
            end
            MEM_WRITE, MEM_READ_AMO: begin
                ex_store_access_fault = access_fault;
                ex_store_page_fault   = page_fault;
            end
        endcase
    end

    // Assertion: imem_valid and dmem_valid are mutually exclusive
    A_SingleValid: assert property (@(posedge clk) disable iff (~rst_n)
        ~(imem_valid & dmem_valid)
    );

endmodule
