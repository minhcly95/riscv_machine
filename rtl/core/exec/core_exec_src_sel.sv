module core_exec_src_sel (
    // From Decoder
    input  core_pkg::exec_src_e  exec_src,
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
        case (exec_src)
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
            SRC_ZI: begin
                src_a = 32'b0;
                src_b = imm_val;
            end
        endcase
    end

endmodule
