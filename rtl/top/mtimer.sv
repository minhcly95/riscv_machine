module mtimer(
    input  logic              clk,
    input  logic              rst_n,
    // APB slave
    input  logic              psel,
    input  logic              penable,
    output logic              pready,
    input  logic [15:0]       paddr,
    input  logic              pwrite,
    input  logic [31:0]       pwdata,
    input  logic [3:0]        pwstrb,
    output logic [31:0]       prdata,
    output logic              pslverr,
    // MTIME direct output to core
    output logic [63:0]       mtime,
    // Interrupt output
    output logic              mtimer_int
);

    // TIME register
    logic [63:0]  next_mtime;

    // TIMECMP register
    logic [63:0]  mtimecmp;

    // Decoding logic
    logic         wr_en;
    logic         wr_mtime;
    logic         wr_mtimeh;
    logic         wr_mtimecmp;
    logic         wr_mtimecmph;

    // ---------------- APB handshake -----------------
    assign pready  = 1'b1;      // No wait states
    assign wr_en   = psel & penable & pwrite;
    assign pslverr = ~&pwstrb;  // Partial write is not allowed

    // ------------------- Decoder --------------------
    always_comb begin
        wr_mtime     = 1'b0;
        wr_mtimeh    = 1'b0;
        wr_mtimecmp  = 1'b0;
        wr_mtimecmph = 1'b0;

        case (paddr)
            16'h0000: wr_mtime     = wr_en;
            16'h0004: wr_mtimeh    = wr_en;
            16'h8000: wr_mtimecmp  = wr_en;
            16'h8004: wr_mtimecmph = wr_en;
            default: ;
        endcase
    end

    // ------------------ Read data -------------------
    always_comb begin
        case (paddr)
            16'h0000: prdata = mtime[0  +: 32];
            16'h0004: prdata = mtime[32 +: 32];
            16'h8000: prdata = mtimecmp[0  +: 32];
            16'h8004: prdata = mtimecmp[32 +: 32];
            default:  prdata = 32'b0;
        endcase
    end

    // ---------------- Write actions -----------------
    // Store TIME
    assign next_mtime = mtime + 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)         mtime <= 64'd0;
        else if (wr_mtime)  mtime <= {next_mtime[63:32], pwdata};
        else if (wr_mtimeh) mtime <= {pwdata, next_mtime[31:0]};
        else                mtime <= next_mtime;
    end

    // Store TIMECMP
    floper #(
        .WIDTH    (32),
        .RST_VAL  (32'hffffffff)
    ) u_mtimecmp(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_mtimecmp),
        .d        (pwdata),
        .q        (mtimecmp[0 +: 32])
    );

    floper #(
        .WIDTH    (32),
        .RST_VAL  (32'hffffffff)
    ) u_mtimecmph(
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (wr_mtimecmph),
        .d        (pwdata),
        .q        (mtimecmp[32 +: 32])
    );

    // ------------------ Interrupt -------------------
    assign mtimer_int = (mtime >= mtimecmp);

endmodule
