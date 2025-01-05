module core_alu (
    // Op select
    input  core_pkg::alu_op_e    alu_op,
    // Input
    input  logic [31:0]          src_a,
    input  logic [31:0]          src_b,
    // Output
    output logic [31:0]          alu_result
);

    import core_pkg::*;

    // Adder signals
    logic [31:0] adder_result;
    logic        sign_a;
    logic        sign_b;
    logic        adder_sign;

    // Shifter signals
    logic [31:0] shifter_result;
    logic [62:0] pre_shift;
    logic [4:0]  shift_amt;

    // ------------------- Decoder --------------------
    always_comb begin
        case (alu_op)
            ALU_ADD,
            ALU_SUB:          alu_result = adder_result;
            ALU_SLT:  case ({sign_a, sign_b})
                2'b00, 2'b11: alu_result = 32'(adder_sign); // Same input sign, subtract to compare
                2'b01:        alu_result = 32'b0;           // Positive A > Negative B
                2'b10:        alu_result = 32'b1;           // Negative A < Positive B
            endcase
            ALU_SLTU: case ({sign_a, sign_b})
                2'b00, 2'b11: alu_result = 32'(adder_sign); // Same input sign, subtract to compare
                2'b01:        alu_result = 32'b1;           // Small A < Large B
                2'b10:        alu_result = 32'b0;           // Large A > Small B
            endcase
            ALU_AND:          alu_result = src_a & src_b;
            ALU_OR:           alu_result = src_a | src_b;
            ALU_XOR:          alu_result = src_a ^ src_b;
            ALU_SLL,
            ALU_SRL,
            ALU_SRA:          alu_result = shifter_result;
            default:          alu_result = 'x;
        endcase
    end

    // -------------------- Adder ---------------------
    always_comb begin
        case (alu_op)
            ALU_SUB,
            ALU_SLT,
            ALU_SLTU: adder_result = src_a - src_b;
            default:  adder_result = src_a + src_b;
        endcase
    end

    assign sign_a     = src_a[31];
    assign sign_b     = src_b[31];
    assign adder_sign = adder_result[31];

    // ------------------- Shifter --------------------
    assign shift_amt = {5{alu_op == ALU_SLL}} ^ src_b[4:0];

    always_comb begin
        case (alu_op)
            ALU_SLL: pre_shift = {src_a, 31'b0};
            ALU_SRL: pre_shift = {31'b0, src_a};
            ALU_SRA: pre_shift = {{31{sign_a}}, src_a};
            default: pre_shift = 'x;
        endcase
    end

    // Funnel shifter
    assign shifter_result = 32'(pre_shift >> shift_amt);

endmodule
