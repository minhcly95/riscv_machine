module core_exec_exception(
    // Inputs
    input  logic                  exec_done,
    input  core_pkg::ctrl_path_e  ctrl_path,
    input  logic                  pc_new_valid,
    input  logic [1:0]            pc_new_offset,
    input  logic [1:0]            mem_addr_offset,
    input  core_pkg::mem_dir_e    mem_dir,
    input  core_pkg::mem_size_e   mem_size,
    input  logic                  ecall,
    input  logic                  ebreak,
    input  logic                  illegal_instr,
    // To Trap handler
    output logic                  ex_ecall,
    output logic                  ex_ebreak,
    output logic                  ex_exec_illegal_instr,
    output logic                  ex_instr_misaligned,
    output logic                  ex_load_misaligned,
    output logic                  ex_store_misaligned
);

    import core_pkg::*;

    logic mem_addr_misaligned;
    logic is_mem_op;

    // Mem access misaligned condition
    always_comb begin
        case (mem_size)
            SIZE_W:  mem_addr_misaligned = |mem_addr_offset;
            SIZE_H,
            SIZE_HU: mem_addr_misaligned = mem_addr_offset[0];
            default: mem_addr_misaligned = 1'b0;
        endcase
    end

    assign is_mem_op = (ctrl_path == CTRL_MEM) | (ctrl_path == CTRL_AMO);

    // Exception conditions
    assign ex_instr_misaligned   = pc_new_valid & (|pc_new_offset);
    assign ex_ecall              = exec_done & ecall;
    assign ex_ebreak             = exec_done & ebreak;
    assign ex_exec_illegal_instr = exec_done & illegal_instr;

    always_comb begin
        if (exec_done & is_mem_op & mem_addr_misaligned) begin
            case (mem_dir)
                MEM_READ: begin
                    ex_load_misaligned  = 1'b1;
                    ex_store_misaligned = 1'b0;
                end
                MEM_WRITE,
                MEM_READ_AMO: begin
                    ex_load_misaligned  = 1'b0;
                    ex_store_misaligned = 1'b1;
                end
                default: begin
                    ex_load_misaligned  = 1'b0;
                    ex_store_misaligned = 1'b0;
                end
            endcase
        end
        else begin
            ex_load_misaligned  = 1'b0;
            ex_store_misaligned = 1'b0;
        end
    end

endmodule
