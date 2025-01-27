module uart_apb(
    // APB slave
    input  logic         psel,
    input  logic         penable,
    output logic         pready,
    input  logic [11:0]  paddr,
    input  logic         pwrite,
    input  logic [31:0]  pwdata,
    input  logic  [3:0]  pwstrb,
    output logic [31:0]  prdata,
    output logic         pslverr,
    // Register interface
    output logic  [2:0]  reg_addr,
    output logic         reg_read,
    output logic         reg_write,
    output logic  [7:0]  reg_wdata,
    input  logic  [7:0]  reg_rdata,
    input  logic         reg_err
);

    logic        out_of_range;
    logic [3:0]  exp_wstrb;
    logic        wrong_wstrb;
    logic        dec_err;

    // No wait states
    assign pready       = 1'b1;

    // Address decode
    assign reg_addr     = paddr[2:0];
    assign out_of_range = |paddr[11:3];

    // Read/write conditions
    assign reg_read     = psel & penable & ~pwrite & ~dec_err;
    assign reg_write    = psel & penable &  pwrite & ~dec_err;

    // Byte lane encode/decode
    always_comb begin
        case (reg_addr[1:0])
            2'd0: reg_wdata = pwdata[0  +: 8];
            2'd1: reg_wdata = pwdata[8  +: 8];
            2'd2: reg_wdata = pwdata[16 +: 8];
            2'd3: reg_wdata = pwdata[24 +: 8];
        endcase
    end

    always_comb begin
        case (reg_addr[1:0])
            2'd0: prdata = {24'd0, reg_rdata};
            2'd1: prdata = {16'd0, reg_rdata, 8'd0};
            2'd2: prdata = {8'd0,  reg_rdata, 16'd0};
            2'd3: prdata = {reg_rdata, 24'd0};
        endcase
    end

    // Strobe verification
    always_comb begin
        case (reg_addr[1:0])
            2'd0: exp_wstrb = 4'b0001;
            2'd1: exp_wstrb = 4'b0010;
            2'd2: exp_wstrb = 4'b0100;
            2'd3: exp_wstrb = 4'b1000;
        endcase
    end

    assign wrong_wstrb = pwrite & (exp_wstrb != pwstrb);

    // Error condition
    assign dec_err = out_of_range | wrong_wstrb;
    assign pslverr = reg_err | dec_err;

endmodule
