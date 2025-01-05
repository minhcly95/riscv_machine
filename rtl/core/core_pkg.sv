package core_pkg;

    // --------------------- Enum ---------------------
    typedef enum logic [6:0] {
        OP_LOAD    = 7'b00_000_11,
        OP_STORE   = 7'b01_000_11,
        OP_BRANCH  = 7'b11_000_11,
        OP_JALR    = 7'b11_001_11,
        OP_JAL     = 7'b11_011_11,
        OP_MISCMEM = 7'b00_011_11,
        OP_OPIMM   = 7'b00_100_11,
        OP_OP      = 7'b01_100_11,
        OP_SYSTEM  = 7'b11_100_11,
        OP_AUIPC   = 7'b00_101_11,
        OP_LUI     = 7'b01_101_11
    } opcode_e;

    typedef enum logic [2:0] {
        IMM_I,
        IMM_S,
        IMM_B,
        IMM_U,
        IMM_J
    } imm_type_e;

    typedef enum logic [1:0] {
        SRC_RR,
        SRC_RI,
        SRC_PI
    } alu_src_e;

    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0_000,
        ALU_SUB  = 4'b1_000,
        ALU_SLT  = 4'b0_010,
        ALU_SLTU = 4'b0_011,
        ALU_AND  = 4'b0_111,
        ALU_OR   = 4'b0_110,
        ALU_XOR  = 4'b0_100,
        ALU_SLL  = 4'b0_001,
        ALU_SRL  = 4'b0_101,
        ALU_SRA  = 4'b1_101
    } alu_op_e;

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

endpackage
