module core_decoder (
    // Instruction
    input  logic [31:0]          instr,
    // Control signals
    output core_pkg::imm_type_e  imm_type,
    output core_pkg::alu_src_e   alu_src,
    output core_pkg::alu_op_e    alu_op,
    output core_pkg::wb_src_e    wb_src,
    output core_pkg::pc_src_e    pc_src,
    output core_pkg::br_type_e   br_type,
    output logic                 mem_op,
    output core_pkg::mem_dir_e   mem_dir,
    output core_pkg::mem_size_e  mem_size
);

    import core_pkg::*;

    localparam CTRL_W =
        $bits(imm_type_e) +
        $bits(alu_src_e)  +
        $bits(wb_src_e)   +
        $bits(pc_src_e)   +
        1                 +     // For mem_op
        $bits(mem_dir_e);

    logic [6:0] opcode;
    logic [2:0] funct3;

    logic       is_shift_op;
    logic [3:0] dec_alu_op;
    logic [3:0] dec_alu_opimm;

    logic [CTRL_W-1:0] ctrl;

    // Decompose into components
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];

    // Aggregate all the controls
    assign {imm_type, alu_src, wb_src, pc_src, mem_op, mem_dir} = ctrl;

    // Main decode table
    always_comb begin
        case (opcode)
            OP_OP:      ctrl = {IMM_I, SRC_RR, WB_EXEC,  PC_NORMAL, 1'b0, MEM_READ};
            OP_OPIMM:   ctrl = {IMM_I, SRC_RI, WB_EXEC,  PC_NORMAL, 1'b0, MEM_READ};
            OP_LUI:     ctrl = {IMM_U, SRC_PI, WB_EXEC,  PC_NORMAL, 1'b0, MEM_READ};
            OP_AUIPC:   ctrl = {IMM_U, SRC_PI, WB_EXEC,  PC_NORMAL, 1'b0, MEM_READ};
            OP_JAL:     ctrl = {IMM_J, SRC_PI, WB_FETCH, PC_JUMP,   1'b0, MEM_READ};  
            OP_JALR:    ctrl = {IMM_I, SRC_RI, WB_FETCH, PC_JUMP,   1'b0, MEM_READ};
            OP_BRANCH:  ctrl = {IMM_B, SRC_RR, WB_NONE,  PC_BRANCH, 1'b0, MEM_READ}; 
            OP_LOAD:    ctrl = {IMM_I, SRC_RI, WB_MEM,   PC_NORMAL, 1'b1, MEM_READ};
            OP_STORE:   ctrl = {IMM_S, SRC_RI, WB_NONE,  PC_NORMAL, 1'b1, MEM_WRITE};
            default:    ctrl = {IMM_I, SRC_RR, WB_NONE,  PC_NORMAL, 1'b0, MEM_READ};
        endcase
    end

    // Mem size is always funct3
    assign mem_size = mem_size_e'(funct3);

    // ALU op decode
    assign is_shift_op   = (funct3[1:0] == 2'b01);
    assign dec_alu_op    = {instr[30], funct3};
    assign dec_alu_opimm = {1'b0, funct3};

    always_comb begin
        case (opcode)
            OP_OP:       alu_op = alu_op_e'(dec_alu_op);
            OP_OPIMM:    alu_op = alu_op_e'(is_shift_op ? dec_alu_op : dec_alu_opimm);
            OP_BRANCH: case (funct3)
                BEQ:     alu_op = ALU_SUB;
                BNE:     alu_op = ALU_SUB;
                BLT:     alu_op = ALU_SLT;
                BGE:     alu_op = ALU_SLT;
                BLTU:    alu_op = ALU_SLTU;
                BGEU:    alu_op = ALU_SLTU;
                default: alu_op = ALU_SUB;
            endcase
            default:     alu_op = ALU_ADD;
        endcase
    end

    // Branch type decode
    always_comb begin
        case (funct3)
            BEQ:     br_type = BRANCH_Z;
            BNE:     br_type = BRANCH_NZ;
            BLT:     br_type = BRANCH_NZ;
            BGE:     br_type = BRANCH_Z;
            BLTU:    br_type = BRANCH_NZ;
            BGEU:    br_type = BRANCH_Z;
            default: br_type = BRANCH_Z;
        endcase
    end

endmodule
