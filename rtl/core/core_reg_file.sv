module core_reg_file (
    input  logic         clk,
    // From EXEC stage
    input  logic  [4:0]  reg_a_id,
    output logic [31:0]  reg_a_value,
    input  logic  [4:0]  reg_b_id,
    output logic [31:0]  reg_b_value,
    input  logic  [4:0]  reg_d_id,
    // From Write-back mux
    input  logic         reg_d_en,
    input  logic         reg_d_write,
    input  logic [31:0]  reg_d_value
);

    logic [31:0] reg_mem[32];

    // Read ports
    assign reg_a_value = reg_mem[reg_a_id];
    assign reg_b_value = reg_mem[reg_b_id];

    // Write port
    always_ff @(posedge clk) begin
        if (reg_d_en & reg_d_write & (reg_d_id != 0))
            reg_mem[reg_d_id] <= reg_d_value;
    end

endmodule
