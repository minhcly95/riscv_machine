module core_decoder (
    // Instruction
    input  logic [31:0]             instr,
    // EXEC phase
    input  logic                    exec_phase,
    // Control signals
    output core_pkg::ctrl_path_e    ctrl_path,
    output core_pkg::imm_type_e     imm_type,
    output core_pkg::exec_src_e     exec_src,
    output core_pkg::alu_op_e       alu_op,
    output core_pkg::mul_op_e       mul_op,
    output core_pkg::div_op_e       div_op,
    output core_pkg::exec_engine_e  exec_engine,
    output core_pkg::wb_src_e       wb_src,
    output core_pkg::pc_src_e       pc_src,
    output core_pkg::br_type_e      br_type,
    output core_pkg::mem_src_e      mem_src,
    output core_pkg::mem_dir_e      mem_dir,
    output core_pkg::mem_size_e     mem_size,
    output core_pkg::mem_rsv_e      mem_rsv,
    output logic                    sc,
    output logic [11:0]             csr_id,
    output logic                    csr_read,
    output logic                    csr_write,
    output logic                    ecall,
    output logic                    ebreak,
    output logic                    mret,
    output logic                    sret,
    output logic                    wfi,
    output logic                    sfence_vma,
    output logic                    illegal_instr
);

    import core_pkg::*;

    localparam CTRL_W =
        $bits(ctrl_path_e) +
        $bits(imm_type_e) +
        $bits(exec_src_e) +
        $bits(wb_src_e)   +
        $bits(pc_src_e)   +
        $bits(mem_dir_e);

    opcode_e    opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    br_op_e     br_op;
    amo_op_e    amo_op;
    sys_op_e    sys_op;

    logic       is_shift_op;
    alu_op_e    dec_alu_op;
    alu_op_e    dec_alu_opimm;

    logic       zero_rd;
    logic       zero_rs1;

    logic [CTRL_W-1:0] ctrl;

    logic       illegal_op;
    logic       illegal_opimm;
    logic       illegal_branch;
    logic       illegal_load;
    logic       illegal_store;
    logic       illegal_amo;
    logic       illegal_system;

    // Helper conditions
    assign zero_rd  = (instr[11:7]  == 5'd0);
    assign zero_rs1 = (instr[19:15] == 5'd0);

    // Decompose into components
    assign opcode = opcode_e'(instr[6:0]);
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    assign br_op  = br_op_e'(funct3);
    assign amo_op = amo_op_e'(instr[31:27]);
    assign sys_op = sys_op_e'(funct3);

    // Aggregate all the controls
    assign {ctrl_path, imm_type, exec_src, wb_src, pc_src, mem_dir} = ctrl;

    // Main decode table
    always_comb begin
        ecall      = 1'b0;
        ebreak     = 1'b0;
        mret       = 1'b0;
        sret       = 1'b0;
        wfi        = 1'b0;
        sfence_vma = 1'b0;

        case (opcode)
            OP_OP:          ctrl = {CTRL_EXEC, IMM_Z, SRC_RR, WB_EXEC,  PC_NORMAL, MEM_READ};
            OP_OPIMM:       ctrl = {CTRL_EXEC, IMM_I, SRC_RI, WB_EXEC,  PC_NORMAL, MEM_READ};
            OP_LUI:         ctrl = {CTRL_EXEC, IMM_U, SRC_ZI, WB_EXEC,  PC_NORMAL, MEM_READ};
            OP_AUIPC:       ctrl = {CTRL_EXEC, IMM_U, SRC_PI, WB_EXEC,  PC_NORMAL, MEM_READ};
            OP_JAL:         ctrl = {CTRL_EXEC, IMM_J, SRC_PI, WB_FETCH, PC_JUMP,   MEM_READ};
            OP_JALR:        ctrl = {CTRL_EXEC, IMM_I, SRC_RI, WB_FETCH, PC_JUMP,   MEM_READ};
            OP_BRANCH:      ctrl = {CTRL_EXEC, IMM_B, SRC_RR, WB_NONE,  PC_BRANCH, MEM_READ};
            OP_LOAD:        ctrl = {CTRL_MEM,  IMM_I, SRC_RI, WB_MEM,   PC_NORMAL, MEM_READ};
            OP_STORE:       ctrl = {CTRL_MEM,  IMM_S, SRC_RI, WB_NONE,  PC_NORMAL, MEM_WRITE};
            OP_AMO: case (amo_op)
                AMO_LR:     ctrl = {CTRL_MEM,  IMM_Z, SRC_RI, WB_MEM,   PC_NORMAL, MEM_READ};
                AMO_SC:     ctrl = {CTRL_MEM,  IMM_Z, SRC_RI, WB_EXEC,  PC_NORMAL, MEM_WRITE};
                AMO_SWAP,
                AMO_ADD,
                AMO_XOR,
                AMO_OR,
                AMO_AND,
                AMO_MIN,
                AMO_MAX,
                AMO_MINU,
                AMO_MAXU: case (exec_phase)
                    1'b0:   ctrl = {CTRL_AMO,  IMM_Z, SRC_RI, WB_MEM,   PC_NORMAL, MEM_READ_AMO};
                    1'b1:   ctrl = {CTRL_AMO,  IMM_Z, SRC_MR, WB_NONE,  PC_NORMAL, MEM_WRITE};
                endcase
                default:    ctrl = {CTRL_EXEC, IMM_Z, SRC_RR, WB_NONE,  PC_NORMAL, MEM_READ};
            endcase
            OP_SYSTEM: case (sys_op)
                SYS_CSRRW,
                SYS_CSRRS,
                SYS_CSRRC:  ctrl = {CTRL_EXEC, IMM_C, SRC_CA, WB_EXEC,  PC_NORMAL, MEM_READ};
                SYS_CSRRWI,
                SYS_CSRRSI,
                SYS_CSRRCI: ctrl = {CTRL_EXEC, IMM_C, SRC_CI, WB_EXEC,  PC_NORMAL, MEM_READ};
                SYS_PRIV: begin
                    ctrl       = {CTRL_EXEC, IMM_Z, SRC_RI, WB_NONE,  PC_NORMAL, MEM_READ};
                    ecall      = (instr[31:20] == 12'b0000000_00000);
                    ebreak     = (instr[31:20] == 12'b0000000_00001);
                    mret       = (instr[31:20] == 12'b0011000_00010);
                    sret       = (instr[31:20] == 12'b0001000_00010);
                    wfi        = (instr[31:20] == 12'b0001000_00101);
                    sfence_vma = (instr[31:25] ==  7'b0001001);
                end
                default:    ctrl = {CTRL_EXEC, IMM_Z, SRC_RR, WB_NONE,  PC_NORMAL, MEM_READ};
            endcase
            default:        ctrl = {CTRL_EXEC, IMM_Z, SRC_RR, WB_NONE,  PC_NORMAL, MEM_READ};
        endcase
    end

    // Engine decode
    always_comb begin
        if (opcode == OP_OP)
            case ({instr[25], funct3[2]})
                2'b00, 2'b01: exec_engine = EXEC_ALU;
                2'b10       : exec_engine = EXEC_MUL;
                2'b11       : exec_engine = EXEC_DIV;
            endcase
        else if ((opcode == OP_AMO) & (amo_op == AMO_SC))
            exec_engine = EXEC_RSV;
        else if (opcode == OP_SYSTEM)
            exec_engine = EXEC_CSR;
        else
            exec_engine = EXEC_ALU;
    end

    // Mem source decode (only switch source on second phase)
    assign mem_src = exec_phase ? MEMSRC_LAST_ALU : MEMSRC_ALU_B;

    // Mem size decode
    assign mem_size = mem_size_e'(funct3);

    // ALU op decode
    assign is_shift_op   = (funct3[1:0] == 2'b01);
    assign dec_alu_op    = alu_op_e'({1'b0, instr[30], funct3});
    assign dec_alu_opimm = alu_op_e'({2'b0, funct3});

    always_comb begin
        case (opcode)
            OP_OP:       alu_op = dec_alu_op;
            OP_OPIMM:    alu_op = is_shift_op ? dec_alu_op : dec_alu_opimm;
            OP_BRANCH: case (funct3)
                BEQ:     alu_op = ALU_SUB;
                BNE:     alu_op = ALU_SUB;
                BLT:     alu_op = ALU_SLT;
                BGE:     alu_op = ALU_SLT;
                BLTU:    alu_op = ALU_SLTU;
                BGEU:    alu_op = ALU_SLTU;
                default: alu_op = ALU_SUB;
            endcase
            OP_AMO: case ({exec_phase, amo_op})
                {1'b1, AMO_SWAP}: alu_op = ALU_OB;
                {1'b1, AMO_ADD}:  alu_op = ALU_ADD;
                {1'b1, AMO_XOR}:  alu_op = ALU_XOR;
                {1'b1, AMO_OR}:   alu_op = ALU_OR;
                {1'b1, AMO_AND}:  alu_op = ALU_AND;
                {1'b1, AMO_MIN}:  alu_op = ALU_MIN;
                {1'b1, AMO_MAX}:  alu_op = ALU_MAX;
                {1'b1, AMO_MINU}: alu_op = ALU_MINU;
                {1'b1, AMO_MAXU}: alu_op = ALU_MAXU;
                default: alu_op = ALU_ADD;
            endcase
            OP_SYSTEM: case (sys_op)
                SYS_CSRRW:  alu_op = ALU_OB;
                SYS_CSRRS:  alu_op = ALU_OR;
                SYS_CSRRC:  alu_op = ALU_ANDN;
                SYS_CSRRWI: alu_op = ALU_OB;
                SYS_CSRRSI: alu_op = ALU_OR;
                SYS_CSRRCI: alu_op = ALU_ANDN;
                default:    alu_op = ALU_ADD;
            endcase
            default:     alu_op = ALU_ADD;
        endcase
    end

    // MUL op decode
    assign mul_op = mul_op_e'(funct3[1:0]);

    // DIV op decode
    assign div_op = div_op_e'(funct3[1:0]);

    // Branch type decode
    always_comb begin
        case (br_op)
            BEQ:     br_type = BRANCH_Z;
            BNE:     br_type = BRANCH_NZ;
            BLT:     br_type = BRANCH_NZ;
            BGE:     br_type = BRANCH_Z;
            BLTU:    br_type = BRANCH_NZ;
            BGEU:    br_type = BRANCH_Z;
            default: br_type = BRANCH_Z;
        endcase
    end

    // SC command
    assign sc = (opcode == OP_AMO) & (amo_op == AMO_SC);

    // Reservation decode
    always_comb begin
        if (opcode == OP_AMO)
            case (amo_op)
                AMO_LR:  mem_rsv = RSV_SET;
                AMO_SC:  mem_rsv = RSV_CLEAR;
                default: mem_rsv = RSV_NONE;
            endcase
        else
            mem_rsv = RSV_NONE;
    end

    // CSR decode
    assign csr_id = instr[31:20];

    always_comb begin
        if (opcode == OP_SYSTEM) begin
            case (sys_op)
                SYS_CSRRW,
                SYS_CSRRWI: begin
                    csr_read  = ~zero_rd;
                    csr_write = 1'b1;
                end
                SYS_CSRRS,
                SYS_CSRRSI,
                SYS_CSRRC,
                SYS_CSRRCI: begin
                    csr_read  = 1'b1;
                    csr_write = ~zero_rs1;
                end
                default: begin
                    csr_read  = 1'b0;
                    csr_write = 1'b0;
                end
            endcase
        end
        else begin
            csr_read  = 1'b0;
            csr_write = 1'b0;
        end
    end

    // Illegal instruction decode
    always_comb begin
        case (opcode)
            OP_OP:      illegal_instr = illegal_op;
            OP_OPIMM:   illegal_instr = illegal_opimm;
            OP_LUI:     illegal_instr = 1'b0;
            OP_AUIPC:   illegal_instr = 1'b0;
            OP_JAL:     illegal_instr = 1'b0;
            OP_JALR:    illegal_instr = 1'b0;
            OP_BRANCH:  illegal_instr = illegal_branch;
            OP_LOAD:    illegal_instr = illegal_load;
            OP_STORE:   illegal_instr = illegal_store;
            OP_AMO:     illegal_instr = illegal_amo;
            OP_SYSTEM:  illegal_instr = illegal_system;
            OP_MISCMEM: illegal_instr = 1'b0;
            default:    illegal_instr = 1'b1;
        endcase
    end

    always_comb begin
        case (funct7)
            7'b0000001: illegal_op = 1'b0;  // All MUL and DIV ops
            7'b0000000: illegal_op = 1'b0;  // All ALU ops
            7'b0100000: illegal_op = (funct3 != 3'b000) & (funct3 != 3'b101);   // Only SUB and SRA
            default:    illegal_op = 1'b1;
        endcase
    end

    always_comb begin
        if (~is_shift_op)     illegal_opimm = 1'b0; // All arithmetic ops
        else
            case ({funct7, funct3[2]})
                8'b0000000_0,
                8'b0000000_1,
                8'b0100000_1: illegal_opimm = 1'b0; // SLLI, SRLI, SRAI
                default:      illegal_opimm = 1'b1;
            endcase
    end

    always_comb begin
        case (br_op)
            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU:    illegal_branch = 1'b0;
            default: illegal_branch = 1'b1;
        endcase
    end

    always_comb begin
        case (mem_size)
            SIZE_B,
            SIZE_H,
            SIZE_W,
            SIZE_BU,
            SIZE_HU: illegal_load = 1'b0;
            default: illegal_load = 1'b1;
        endcase
    end

    always_comb begin
        case (mem_size)
            SIZE_B,
            SIZE_H,
            SIZE_W:  illegal_store = 1'b0;
            default: illegal_store = 1'b1;
        endcase
    end

    always_comb begin
        case (amo_op)
            AMO_LR,
            AMO_SC,
            AMO_SWAP,
            AMO_ADD,
            AMO_XOR,
            AMO_OR,
            AMO_AND,
            AMO_MIN,
            AMO_MAX,
            AMO_MINU,
            AMO_MAXU: illegal_amo = (mem_size != SIZE_W);
            default:  illegal_amo = 1'b1;
        endcase
    end

    always_comb begin
        case (sys_op)
            SYS_CSRRW,
            SYS_CSRRS,
            SYS_CSRRC,
            SYS_CSRRWI,
            SYS_CSRRSI,
            SYS_CSRRCI: illegal_system = 1'b0;
            SYS_PRIV:   illegal_system = ~|{ecall, ebreak, mret, sret, wfi, sfence_vma};
            default:    illegal_system = 1'b1;
        endcase
    end

endmodule
