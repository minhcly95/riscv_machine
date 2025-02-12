// Top-level testbench
// Consists of the system and a clock generator
module tb_top #(
    parameter  RESET_VECTOR = 32'h0000_0000,    // Value of PC when reset
    parameter  RAM_SIZE = 32'h0400_0000         // RAM size in bytes
)(
    input  logic  rst_n,
    // UART I/O
    output logic  tx,
    input  logic  rx
);

    logic clk;

    // -------------------- System --------------------
    top #(
        .RESET_VECTOR  (RESET_VECTOR),
        .RAM_SIZE      (RAM_SIZE)
    ) dut(
        .clk           (clk),
        .rst_n         (rst_n),
        .tx            (tx),
        .rx            (rx)
    );

    // ------------------- Clock gen ------------------
    // We run clock at 16 * UART baud rate (115200).
    // In short, clock frequency is 1.843 MHz
    initial begin
        forever begin
            clk = 1'b1;
            #271ns;
            clk = 1'b0;
            #271ns;
        end
    end

endmodule
