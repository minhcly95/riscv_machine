module core_trap_handler (
    // To CSR
    output logic                  exception_valid,
    output core_pkg::exception_e  exception_cause,
    output logic [31:0]           exception_value,
    // From CSR
    input  core_pkg::priv_e       priv,
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
    input  logic                  ex_store_access_fault
);

    import core_pkg::*;

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

    // The priority of exceptions is described in the spec
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
