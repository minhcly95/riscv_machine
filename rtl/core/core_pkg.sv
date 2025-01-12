package core_pkg;

    // --------------------- Enum ---------------------
    typedef enum logic [1:0] {
        CTRL_EXEC,
        CTRL_MEM,
        CTRL_AMO
    } ctrl_path_e;

    typedef enum logic [6:0] {
        OP_LOAD    = 7'b00_000_11,
        OP_STORE   = 7'b01_000_11,
        OP_BRANCH  = 7'b11_000_11,
        OP_JALR    = 7'b11_001_11,
        OP_JAL     = 7'b11_011_11,
        OP_MISCMEM = 7'b00_011_11,
        OP_AMO     = 7'b01_011_11,
        OP_OPIMM   = 7'b00_100_11,
        OP_OP      = 7'b01_100_11,
        OP_SYSTEM  = 7'b11_100_11,
        OP_AUIPC   = 7'b00_101_11,
        OP_LUI     = 7'b01_101_11
    } opcode_e;

    typedef enum logic [2:0] {
        IMM_Z,
        IMM_I,
        IMM_S,
        IMM_B,
        IMM_U,
        IMM_J
    } imm_type_e;

    typedef enum logic [2:0] {
        SRC_RR,
        SRC_RI,
        SRC_PI,
        SRC_ZI,
        SRC_MR
    } exec_src_e;

    typedef enum logic [4:0] {
        ALU_ADD  = 5'b00_000,
        ALU_SUB  = 5'b01_000,
        ALU_SLT  = 5'b00_010,
        ALU_SLTU = 5'b00_011,
        ALU_AND  = 5'b00_111,
        ALU_OR   = 5'b00_110,
        ALU_XOR  = 5'b00_100,
        ALU_SLL  = 5'b00_001,
        ALU_SRL  = 5'b00_101,
        ALU_SRA  = 5'b01_101,
        ALU_OA   = 5'b10_000,
        ALU_OB   = 5'b10_001,
        ALU_MIN  = 5'b10_100,
        ALU_MAX  = 5'b10_101,
        ALU_MINU = 5'b10_110,
        ALU_MAXU = 5'b10_111
    } alu_op_e;

    typedef enum logic [1:0] {
        MUL_MUL    = 2'b00,
        MUL_MULH   = 2'b01,
        MUL_MULHSU = 2'b10,
        MUL_MULHU  = 2'b11
    } mul_op_e;

    typedef enum logic [1:0] {
        DIV_DIV  = 2'b00,
        DIV_DIVU = 2'b01,
        DIV_REM  = 2'b10,
        DIV_REMU = 2'b11
    } div_op_e;

    typedef enum logic [1:0] {
        EXEC_ALU = 2'b00,
        EXEC_RSV = 2'b01,
        EXEC_MUL = 2'b10,
        EXEC_DIV = 2'b11
    } exec_engine_e;

    typedef enum logic [1:0] {
        WB_NONE,
        WB_FETCH,
        WB_EXEC,
        WB_MEM
    } wb_src_e;

    typedef enum logic [1:0] {
        PC_NORMAL,
        PC_JUMP,
        PC_BRANCH
    } pc_src_e;

    typedef enum logic [2:0] {
        BEQ  = 3'b000,
        BNE  = 3'b001,
        BLT  = 3'b100,
        BGE  = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
    } br_op_e;

    typedef enum logic [0:0] {
        BRANCH_Z,
        BRANCH_NZ
    } br_type_e;

    typedef enum logic [0:0] {
        MEMSRC_ALU_B    = 1'b0,
        MEMSRC_LAST_ALU = 1'b1
    } mem_src_e;

    typedef enum logic [0:0] {
        MEM_READ  = 1'b0,
        MEM_WRITE = 1'b1
    } mem_dir_e;

    typedef enum logic [2:0] {
        SIZE_B  = 3'b000,
        SIZE_H  = 3'b001,
        SIZE_W  = 3'b010,
        SIZE_BU = 3'b100,
        SIZE_HU = 3'b101
    } mem_size_e;

    typedef enum logic [1:0] {
        RSV_NONE,
        RSV_SET,
        RSV_CLEAR
    } mem_rsv_e;

    typedef enum logic [4:0] {
        AMO_LR   = 5'b00010,
        AMO_SC   = 5'b00011,
        AMO_SWAP = 5'b00001,
        AMO_ADD  = 5'b00000,
        AMO_XOR  = 5'b00100,
        AMO_OR   = 5'b01000,
        AMO_AND  = 5'b01100,
        AMO_MIN  = 5'b10000,
        AMO_MAX  = 5'b10100,
        AMO_MINU = 5'b11000,
        AMO_MAXU = 5'b11100
    } amo_op_e;

endpackage
