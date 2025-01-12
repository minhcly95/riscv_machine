// Top-level testbench
// Consists of the system and the clock generator
module tb_top #(
    parameter  RESET_VECTOR = 32'h0000_0000,    // Value of PC when reset
    parameter  RAM_SIZE = 32'h0010_0000         // RAM size in bytes
)(
    input  logic  rst_n
);

    logic clk;

    // -------------------- System --------------------
    top #(
        .RESET_VECTOR  (RESET_VECTOR),
        .RAM_SIZE      (RAM_SIZE)
    ) u_top(
        .clk           (clk),
        .rst_n         (rst_n)
    );

    // ------------------- Clock gen ------------------
    initial begin
        forever begin
            clk = 1'b1;
            #0.5;
            clk = 1'b0;
            #0.5;
        end
    end

endmodule
