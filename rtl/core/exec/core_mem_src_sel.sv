module core_mem_src_sel (
    // From Decoder
    input  core_pkg::mem_src_e   mem_src,
    // Inputs
    input  logic [31:0]          reg_b_value,
    input  logic [31:0]          alu_result,
    input  logic [31:0]          last_alu_result,
    // Outputs
    output logic [31:0]          mem_addr,
    output logic [31:0]          mem_wdata
);

    import core_pkg::*;

    always_comb begin
        case (mem_src)
            MEMSRC_ALU_B: begin
                mem_addr  = alu_result;
                mem_wdata = reg_b_value;
            end
            MEMSRC_LAST_ALU: begin
                mem_addr  = last_alu_result;
                mem_wdata = alu_result;
            end
        endcase
    end

endmodule
