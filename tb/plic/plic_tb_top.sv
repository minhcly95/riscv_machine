// Top-level testbench
// Mainly used to unpack int_src and int_tgt
module plic_tb_top #(
    parameter  SRC_N   = 8,     // Number of sources (max 31)
    parameter  TGT_N   = 8,     // Number of targets (max 32)
    parameter  PRIO_W  = 4      // Priority width
)(
    input  logic              clk,
    input  logic              rst_n,
    // APB slave
    input  logic              psel,
    input  logic              penable,
    output logic              pready,
    input  logic [25:0]       paddr,
    input  logic              pwrite,
    input  logic [31:0]       pwdata,
    input  logic [3:0]        pwstrb,
    output logic [31:0]       prdata,
    output logic              pslverr,
    // Interrupt sources
    input  logic [0:0]        int_src [SRC_N],
    // Interrupt targets
    output logic [0:0]        int_tgt [TGT_N]
);

    logic [SRC_N-1:0]  packed_int_src;
    logic [TGT_N-1:0]  packed_int_tgt;

    // Main DUT
    plic_top #(
        .SRC_N    (SRC_N),
        .TGT_N    (TGT_N),
        .PRIO_W   (PRIO_W)
    ) u_plic(
        .clk      (clk),
        .rst_n    (rst_n),
        .psel     (psel),
        .penable  (penable),
        .pready   (pready),
        .paddr    (paddr),
        .pwrite   (pwrite),
        .pwdata   (pwdata),
        .pwstrb   (pwstrb),
        .prdata   (prdata),
        .pslverr  (pslverr),
        .int_src  (packed_int_src),
        .int_tgt  (packed_int_tgt)
    );

    // Unpack int_src and int_tgt
    generate for (genvar i = 0; i < SRC_N; i++)
        assign packed_int_src[i] = int_src[i];
    endgenerate

    generate for (genvar j = 0; j < TGT_N; j++)
        assign int_tgt[j] = packed_int_tgt[j];
    endgenerate


endmodule
