module core_imm_parser (
    // Instruction
    input  logic [31:0]          instr,
    // From Decoder
    input  core_pkg::imm_type_e  imm_type,
    // To ALU
    output logic [31:0]          imm_val
);

    import core_pkg::*;

    always_comb begin
        case (imm_type)
            IMM_Z:   imm_val = 32'b0;
            IMM_I:   imm_val = {{21{instr[31]}}, instr[30:20]};
            IMM_S:   imm_val = {{21{instr[31]}}, instr[30:25], instr[11:7]};
            IMM_B:   imm_val = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U:   imm_val = {instr[31:12], 12'b0};
            IMM_J:   imm_val = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm_val = 'x;  // Should not happen
        endcase
    end

endmodule
