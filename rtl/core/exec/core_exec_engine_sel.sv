module core_exec_engine_sel (
    // From Decoder
    input  core_pkg::exec_engine_e  exec_engine,
    // Inputs
    input  logic [31:0]             alu_result,
    input  logic [31:0]             mul_result,
    input  logic [31:0]             div_result,
    input  logic [31:0]             csr_rdata,
    input  logic                    mem_rsv_valid,
    // Outputs
    output logic [31:0]             exec_result
);

    import core_pkg::*;

    always_comb begin
        case (exec_engine)
            EXEC_ALU: exec_result = alu_result;
            EXEC_MUL: exec_result = mul_result;
            EXEC_DIV: exec_result = div_result;
            EXEC_CSR: exec_result = csr_rdata;
            EXEC_RSV: exec_result = {31'b0, ~mem_rsv_valid};
            default:  exec_result = 'x;
        endcase
    end

endmodule
