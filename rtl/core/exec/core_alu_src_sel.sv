module core_alu_src_sel (
    // From Decoder
    input  core_pkg::alu_src_e   alu_src,
    // Inputs
    input  logic [31:0]          reg_a_value,
    input  logic [31:0]          reg_b_value,
    input  logic [31:0]          imm_val,
    input  logic [31:0]          pc,
    // Outputs
    output logic [31:0]          src_a,
    output logic [31:0]          src_b
);

    import core_pkg::*;

    always_comb begin
        case (alu_src)
            SRC_RR: begin
                src_a = reg_a_value;
                src_b = reg_b_value;
            end
            SRC_RI: begin
                src_a = reg_a_value;
                src_b = imm_val;
            end
            SRC_PI: begin
                src_a = pc;
                src_b = imm_val;
            end
            default: begin  // Should not happen
                src_a = 'x;
                src_b = 'x;
            end
        endcase
    end

endmodule
