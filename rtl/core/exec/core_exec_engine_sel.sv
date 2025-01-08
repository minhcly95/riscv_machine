module core_exec_engine_sel (
    // From Decoder
    input  core_pkg::exec_engine_e  exec_engine,
    // Inputs
    input  logic [31:0]             alu_result,
    input  logic [31:0]             mul_result,
    // Outputs
    output logic [31:0]             exec_result
);

    import core_pkg::*;

    always_comb begin
        case (exec_engine)
            EXEC_ALU: exec_result = alu_result;
            EXEC_MUL: exec_result = mul_result;
            default:  exec_result = 'x;
        endcase
    end

endmodule
