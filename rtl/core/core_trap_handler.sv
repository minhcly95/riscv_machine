module core_trap_handler (
    // From Controller
    input  logic                  check_interrupt,
    // To CSR
    output logic                  exception_valid,
    output core_pkg::exception_e  exception_cause,
    output logic [31:0]           exception_value,
    output logic                  m_interrupt_valid,
    output core_pkg::interrupt_e  m_interrupt_cause,
    output logic                  s_interrupt_valid,
    output core_pkg::interrupt_e  s_interrupt_cause,
    // From CSR
    input  core_pkg::priv_e       priv,
    input  logic                  cfg_mie,
    input  logic                  cfg_sie,
    input  logic                  cfg_meie,
    input  logic                  cfg_mtie,
    input  logic                  cfg_seie,
    input  logic                  cfg_stie,
    input  logic                  cfg_ssie,
    input  logic                  cfg_seip,
    input  logic                  cfg_stip,
    input  logic                  cfg_ssip,
    input  logic                  ex_csr_illegal_instr,
    // From FETCH
    input  logic [31:0]           instr,
    input  logic [31:0]           imem_addr,
    input  logic                  ex_instr_access_fault,
    // From EXEC
    input  logic [31:0]           pc_new,
    input  logic [31:0]           mem_addr,
    input  logic                  ex_ecall,
    input  logic                  ex_ebreak,
    input  logic                  ex_exec_illegal_instr,
    input  logic                  ex_instr_misaligned,
    input  logic                  ex_load_misaligned,
    input  logic                  ex_store_misaligned,
    // From MEM
    input  logic                  ex_load_access_fault,
    input  logic                  ex_store_access_fault,
    // From external
    input  logic                  int_m_ext,
    input  logic                  mtimer_int
);

    import core_pkg::*;

    logic  int_m_enable;
    logic  int_s_enable;

    logic  int_m_ext_active;
    logic  int_m_tim_active;
    logic  int_s_ext_active;
    logic  int_s_tim_active;
    logic  int_s_sw_active;

    // Trap when any exception happens
    assign exception_valid = |{
        ex_csr_illegal_instr,
        ex_exec_illegal_instr,
        ex_instr_misaligned,
        ex_instr_access_fault,
        ex_load_misaligned,
        ex_store_misaligned,
        ex_load_access_fault,
        ex_store_access_fault,
        ex_ecall,
        ex_ebreak
    };

    // Check the interrupt condition
    always_comb begin
        case (priv)
            PRIV_M:  int_m_enable = cfg_mie;
            default: int_m_enable = 1'b1;
        endcase
    end

    always_comb begin
        case (priv)
            PRIV_M:  int_s_enable = 1'b0;
            PRIV_S:  int_s_enable = cfg_sie;
            default: int_s_enable = 1'b1;
        endcase
    end

    assign int_m_ext_active = cfg_meie & int_m_ext;
    assign int_m_tim_active = cfg_mtie & mtimer_int;
    assign int_s_ext_active = cfg_seie & cfg_seip;
    assign int_s_tim_active = cfg_stie & cfg_stip;
    assign int_s_sw_active  = cfg_ssie & cfg_ssip;

    always_comb begin
        if (check_interrupt) begin
            m_interrupt_valid = int_m_enable & |{int_m_ext_active, int_m_tim_active};
            s_interrupt_valid = int_s_enable & |{int_s_ext_active, int_s_tim_active, int_s_sw_active};
        end
        else begin
            m_interrupt_valid = 1'b0;
            s_interrupt_valid = 1'b0;
        end
    end

    // The priority of exceptions and interrupts is described in the spec
    always_comb begin
        if (ex_instr_access_fault)
            exception_cause = EX_INSTR_ACCESS_FAULT;
        else if (ex_csr_illegal_instr | ex_exec_illegal_instr)
            exception_cause = EX_ILLEGAL_INSTR;
        else if (ex_instr_misaligned)
            exception_cause = EX_INSTR_MISALIGNED;
        else if (ex_ecall)
            case (priv)
                PRIV_M:  exception_cause = EX_ECALL_MMODE;
                PRIV_S:  exception_cause = EX_ECALL_SMODE;
                default: exception_cause = EX_ECALL_UMODE;
            endcase
        else if (ex_ebreak)
            exception_cause = EX_BREAKPOINT;
        else if (ex_load_access_fault)
            exception_cause = EX_LOAD_ACCESS_FAULT;
        else if (ex_store_access_fault)
            exception_cause = EX_STORE_ACCESS_FAULT;
        else if (ex_load_misaligned)
            exception_cause = EX_LOAD_MISALIGNED;
        else if (ex_store_misaligned)
            exception_cause = EX_STORE_MISALIGNED;
        else
            exception_cause = EX_HARDWARE_ERROR;
    end

    always_comb begin
        if (int_m_ext_active)
            m_interrupt_cause = INT_M_EXTERNAL;
        else if (int_m_tim_active)
            m_interrupt_cause = INT_M_TIMER;
        else
            m_interrupt_cause = INT_NONE;
    end

    always_comb begin
        if (int_s_ext_active)
            s_interrupt_cause = INT_S_EXTERNAL;
        else if (int_s_sw_active)
            s_interrupt_cause = INT_S_SOFTWARE;
        else if (int_s_tim_active)
            s_interrupt_cause = INT_S_TIMER;
        else
            s_interrupt_cause = INT_NONE;
    end

    // Exception argument (mtval)
    always_comb begin
        case (exception_cause)
            EX_INSTR_MISALIGNED:   exception_value = pc_new;
            EX_INSTR_ACCESS_FAULT: exception_value = imem_addr;
            EX_ILLEGAL_INSTR:      exception_value = instr;
            EX_LOAD_MISALIGNED,
            EX_LOAD_ACCESS_FAULT,
            EX_STORE_MISALIGNED,
            EX_STORE_ACCESS_FAULT: exception_value = mem_addr;
            default:               exception_value = 32'd0;
        endcase
    end

endmodule
