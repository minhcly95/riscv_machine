module core_pc_new_sel (
    // From Decoder
    input  core_pkg::pc_src_e    pc_src,
    input  core_pkg::br_type_e   br_type,
    // Inputs
    input  logic [31:0]          alu_result,
    input  logic [31:0]          br_target,
    // Outputs
    output logic                 pc_new_valid,
    output logic [31:0]          pc_new
);

    import core_pkg::*;

    logic alu_nonzero;

    assign alu_nonzero = (alu_result != 32'b0);

    always_comb begin
        case (pc_src)
            PC_JUMP: begin
                pc_new_valid = 1'b1;
                pc_new       = alu_result;
            end
            PC_BRANCH: begin
                pc_new_valid = (br_type == BRANCH_NZ) ? alu_nonzero : ~alu_nonzero;
                pc_new       = br_target;
            end
            default: begin
                pc_new_valid = 1'b0;
                pc_new       = 'x;
            end
        endcase
    end

endmodule
