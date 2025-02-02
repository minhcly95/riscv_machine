module plic_reg #(
    parameter  SRC_N   = 1,     // Number of sources
    parameter  TGT_N   = 1,     // Number of targets
    parameter  PRIO_W  = 1      // Priority width
)(
    input  logic                          clk,
    input  logic                          rst_n,
    // APB access
    input  logic [25:0]                   reg_addr,   // 26-bit address space
    input  logic                          reg_read,
    input  logic                          reg_write,
    input  logic [31:0]                   reg_wdata,
    output logic [31:0]                   reg_rdata,
    // Claim interface
    output logic                          claim_valid,
    output logic [4:0]                    claim_tgt,
    // Complete interface
    output logic                          complete_valid,
    output logic [4:0]                    complete_src,
    output logic [4:0]                    complete_tgt,
    // Status
    input  logic [SRC_N:0]                int_pending,
    input  logic [4:0]                    claim_src,
    // Configurations
    output logic [SRC_N:0][PRIO_W-1:0]    cfg_int_prio,
    output logic [TGT_N-1:0][SRC_N:0]     cfg_int_enable,
    output logic [TGT_N-1:0][PRIO_W-1:0]  cfg_threshold
);

    genvar i;
    genvar j;

    // Interrupt priority
    logic [SRC_N:1][PRIO_W-1:0]    int_prio;

    // Interrupt enable
    logic [TGT_N-1:0][SRC_N:1]     int_enable;

    // Priority threshold
    logic [TGT_N-1:0][PRIO_W-1:0]  threshold;

    // Decoding logic
    logic         dec_int_prio;
    logic         dec_int_pending;
    logic         dec_int_enable;
    logic         dec_threshold;
    logic         dec_claim;

    logic [4:0]   dec_src_int_prio;     // Keep this 5 bit to keep the code simple
    logic [4:0]   dec_tgt_int_enable;
    logic [4:0]   dec_tgt_threshold;
    logic [4:0]   dec_tgt_claim;

    logic [31:0]  rdata_int_prio;
    logic [31:0]  rdata_int_pending;
    logic [31:0]  rdata_int_enable;
    logic [31:0]  rdata_threshold;
    logic [31:0]  rdata_claim;

    // ------------------- Decoder --------------------
    // Interrupt priority: 0x0000000 + 4 * src
    assign dec_src_int_prio   = reg_addr[6:2];
    assign dec_int_prio       = (reg_addr[25:12] == 14'h0)  & (reg_addr[11:7] == 5'h0)  & (dec_src_int_prio   <= 5'(SRC_N)) & (dec_src_int_prio != 5'h0);

    // Interrupt pending:  0x0001000
    assign dec_int_pending    = (reg_addr == 26'h1000);

    // Interrupt enable:   0x0002000 + 0x80 * tgt
    assign dec_tgt_int_enable = reg_addr[11:7];
    assign dec_int_enable     = (reg_addr[25:12] == 14'h2)  & (reg_addr[6:2]  == 5'd0)  & (dec_tgt_int_enable <= 5'(TGT_N-1));

    // Priority threshold: 0x0200000 + 0x1000 * tgt
    assign dec_tgt_threshold  = reg_addr[16:12];
    assign dec_threshold      = (reg_addr[25:17] == 9'h010) & (reg_addr[11:2] == 10'd0) & (dec_tgt_threshold  <= 5'(TGT_N-1));

    // Claim/complete:     0x0200004 + 0x1000 * tgt
    assign dec_tgt_claim      = reg_addr[16:12];
    assign dec_claim          = (reg_addr[25:17] == 9'h010) & (reg_addr[11:2] == 10'd1) & (dec_tgt_claim      <= 5'(TGT_N-1));

    // ------------------ Read data -------------------
    assign rdata_int_prio     = 32'(int_prio[dec_src_int_prio]);
    assign rdata_int_pending  = 32'(int_pending);
    assign rdata_int_enable   = 32'({int_enable[dec_tgt_int_enable], 1'b0});
    assign rdata_threshold    = 32'(threshold[dec_tgt_threshold]);
    assign rdata_claim        = 32'(claim_src);

    one_hot_mux #(
        .CH_N     (5),
        .PLD_W    (32)
    ) u_rdata_mux(
        .sel      ({
            dec_int_prio,
            dec_int_pending,
            dec_int_enable,
            dec_threshold,
            dec_claim
        }),
        .in_pld   ({
            rdata_int_prio,
            rdata_int_pending,
            rdata_int_enable,
            rdata_threshold,
            rdata_claim
        }),
        .out_pld  (reg_rdata)
    );

    // ---------------- Read actions ------------------
    // Claim interrupt on claim read
    assign claim_valid = reg_read & dec_claim;
    assign claim_tgt   = dec_tgt_claim;

    // ---------------- Write actions -----------------
    // Complete interrupt on claim write
    // We only check the MSbits of reg_wdata and
    // rely on the gateways to check the LSbits.
    assign complete_valid = reg_write & dec_claim & (reg_wdata[31:5] == 27'b0);
    assign complete_tgt   = dec_tgt_claim;
    assign complete_src   = reg_wdata[4:0];

    generate
        for (i = 1; i < SRC_N+1; i++) begin : g_src
            // Store Interrupt priority
            floper #(
                .WIDTH    (PRIO_W),
                .RST_VAL  (PRIO_W'(0))
            ) u_int_prio_flop(
                .clk      (clk),
                .rst_n    (rst_n),
                .en       (reg_write & dec_int_prio & (dec_src_int_prio == 5'(i))),
                .d        (reg_wdata[PRIO_W-1:0]),
                .q        (int_prio[i])
            );
        end
    endgenerate
    
    generate
        for (j = 0; j < TGT_N; j++) begin : g_tgt
            // Store Interrupt enable
            floper #(
                .WIDTH    (SRC_N),
                .RST_VAL  (SRC_N'(0))
            ) u_int_enable_flop(
                .clk      (clk),
                .rst_n    (rst_n),
                .en       (reg_write & dec_int_enable & (dec_tgt_int_enable == 5'(j))),
                .d        (reg_wdata[SRC_N:1]),
                .q        (int_enable[j])
            );

            // Store Priority threshold
            floper #(
                .WIDTH    (PRIO_W),
                .RST_VAL  (PRIO_W'(0))
            ) u_threshold_flop(
                .clk      (clk),
                .rst_n    (rst_n),
                .en       (reg_write & dec_threshold & (dec_tgt_threshold == 5'(j))),
                .d        (reg_wdata[PRIO_W-1:0]),
                .q        (threshold[j])
            );
        end
    endgenerate

    // ---------------- Output wiring -----------------
    assign cfg_int_prio = {int_prio, PRIO_W'(0)};   // Priority of source 0 is 0

    generate for (j = 0; j < TGT_N; j++)
        assign cfg_int_enable[j] = {int_enable[j], 1'b0};   // Source 0 is never enabled
    endgenerate

    assign cfg_threshold = threshold;

endmodule
