module plic_top #(
    parameter  SRC_N   = 1,     // Number of sources (max 31)
    parameter  TGT_N   = 1,     // Number of targets (max 32)
    parameter  PRIO_W  = 1      // Priority width
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
    // Interrupt sources (first one has ID 1)
    input  logic [SRC_N-1:0]  int_src,
    // Interrupt targets (first one has ID 0)
    output logic [TGT_N-1:0]  int_tgt
);

    // APB/Register interface
    logic [25:0]                   reg_addr;
    logic                          reg_read;
    logic                          reg_write;
    logic [31:0]                   reg_wdata;
    logic [31:0]                   reg_rdata;
    // Array inputs
    logic [SRC_N:0]                int_pending;
    // Array outputs
    logic [TGT_N-1:0][PRIO_W-1:0]  max_prio;
    logic [TGT_N-1:0][4:0]         max_src;
    // Claim interface
    logic                          claim_valid;
    logic [4:0]                    claim_src;
    logic [4:0]                    claim_tgt;
    // Complete interface
    logic                          complete_valid;
    logic [4:0]                    complete_src;
    logic [4:0]                    complete_tgt;
    // Configurations
    logic [SRC_N:0][PRIO_W-1:0]    cfg_int_prio;
    logic [TGT_N-1:0][SRC_N:0]     cfg_int_enable;
    logic [TGT_N-1:0][PRIO_W-1:0]  cfg_threshold;

    // ---------------- APB interface -----------------
    plic_apb u_apb(
        .psel       (psel),
        .penable    (penable),
        .pready     (pready),
        .paddr      (paddr),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .pwstrb     (pwstrb),
        .prdata     (prdata),
        .pslverr    (pslverr),
        .reg_addr   (reg_addr),
        .reg_read   (reg_read),
        .reg_write  (reg_write),
        .reg_wdata  (reg_wdata),
        .reg_rdata  (reg_rdata)
    );

    // ---------------- Register file -----------------
    plic_reg #(
        .SRC_N           (SRC_N),
        .TGT_N           (TGT_N),
        .PRIO_W          (PRIO_W)
    ) u_reg(
        .clk             (clk),
        .rst_n           (rst_n),
        .reg_addr        (reg_addr),
        .reg_read        (reg_read),
        .reg_write       (reg_write),
        .reg_wdata       (reg_wdata),
        .reg_rdata       (reg_rdata),
        .claim_valid     (claim_valid),
        .claim_tgt       (claim_tgt),
        .complete_valid  (complete_valid),
        .complete_src    (complete_src),
        .complete_tgt    (complete_tgt),
        .int_pending     (int_pending),
        .claim_src       (claim_src),
        .cfg_int_prio    (cfg_int_prio),
        .cfg_int_enable  (cfg_int_enable),
        .cfg_threshold   (cfg_threshold)
    );

    // ------------------- Gateways -------------------
    generate
        for (genvar i = 1; i < SRC_N+1; i++) begin: g_src
            plic_gateway #(
                .SRC_ID          (i)
            ) u_gateway(
                .clk             (clk),
                .rst_n           (rst_n),
                .int_src         (int_src[i-1]),    // Source 0 does not exist
                .int_pending     (int_pending[i]),
                .claim_valid     (claim_valid),
                .claim_src       (claim_src),
                .claim_tgt       (claim_tgt),
                .complete_valid  (complete_valid),
                .complete_src    (complete_src),
                .complete_tgt    (complete_tgt)
            );
        end
    endgenerate

    assign int_pending[0] = 1'b0;   // Source 0 does not exist

    // ---------------- Routing array -----------------
    plic_routing_array #(
        .SRC_N           (SRC_N),
        .TGT_N           (TGT_N),
        .PRIO_W          (PRIO_W)
    ) u_routing_array(
        .int_pending     (int_pending),
        .max_prio        (max_prio),
        .max_src         (max_src),
        .cfg_int_prio    (cfg_int_prio),
        .cfg_int_enable  (cfg_int_enable)
    );

    // ------------------ Notifiers -------------------
    generate
        for (genvar j = 0; j < TGT_N; j++) begin: g_tgt
            plic_notifier #(
                .PRIO_W         (PRIO_W)
            ) u_notifier(
                .max_prio       (max_prio[j]),
                .int_tgt        (int_tgt[j]),
                .cfg_threshold  (cfg_threshold[j])
            );
        end
    endgenerate

    // --------------- Claim controller ---------------
    plic_claim_ctrl #(
        .TGT_N      (TGT_N)
    ) u_claim_ctrl(
        .max_src    (max_src),
        .claim_tgt  (claim_tgt),
        .claim_src  (claim_src)
    );

endmodule
