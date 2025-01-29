module core_stage_mem (
    input  logic                 clk,
    input  logic                 rst_n,
    // From Controller
    input  logic                 mem_stage_valid,
    output logic                 mem_stage_ready,
    // From/to EXEC stage
    input  logic [31:0]          mem_addr,
    input  logic [31:0]          mem_wdata,
    input  core_pkg::mem_dir_e   mem_dir,
    input  core_pkg::mem_size_e  mem_size,
    input  core_pkg::mem_rsv_e   mem_rsv,
    output logic                 mem_rsv_valid,
    output logic [31:0]          mem_last_rdata,
    // To Write-back mux
    output logic [31:0]          mem_rdata,
    // Memory interface
    output logic                 dmem_valid,
    input  logic                 dmem_ready,
    output logic [31:0]          dmem_addr,
    output logic                 dmem_write,
    output logic [31:0]          dmem_wdata,
    output logic  [3:0]          dmem_wstrb,
    input  logic [31:0]          dmem_rdata,
    input  logic                 dmem_err,
    // To Trap handler
    output logic                 ex_load_access_fault,
    output logic                 ex_store_access_fault
);

    import core_pkg::*;

    logic         mem_done;
    logic         rsv_addr_valid;
    logic [29:0]  rsv_addr;
    logic         rsv_addr_matched;

    // Handshake
    assign dmem_valid      = mem_stage_valid;
    assign mem_stage_ready = dmem_ready;
    assign mem_done        = mem_stage_valid & mem_stage_ready;

    // D-mem address
    assign dmem_addr = mem_addr;

    // D-mem direction
    assign dmem_write = (mem_dir == MEM_WRITE);

    // Write data must be shifted to the correct lanes
    always_comb begin
        case (mem_size)
            SIZE_B, SIZE_BU: case (mem_addr[1:0])
                2'b00: begin
                    dmem_wdata = {24'b0, mem_wdata[7:0]};
                    dmem_wstrb = 4'b0001;
                end
                2'b01: begin
                    dmem_wdata = {16'b0, mem_wdata[7:0], 8'b0};
                    dmem_wstrb = 4'b0010;
                end
                2'b10: begin
                    dmem_wdata = {8'b0, mem_wdata[7:0], 16'b0};
                    dmem_wstrb = 4'b0100;
                end
                2'b11: begin
                    dmem_wdata = {mem_wdata[7:0], 24'b0};
                    dmem_wstrb = 4'b1000;
                end
            endcase
            SIZE_H, SIZE_HU: case (mem_addr[1])
                1'b0: begin
                    dmem_wdata = {16'b0, mem_wdata[15:0]};
                    dmem_wstrb = 4'b0011;
                end
                1'b1: begin
                    dmem_wdata = {mem_wdata[15:0], 16'b0};
                    dmem_wstrb = 4'b1100;
                end
            endcase
            SIZE_W: begin
                dmem_wdata = mem_wdata;
                dmem_wstrb = 4'b1111;
            end
            default: begin
                // Should not happen
                dmem_wdata = 'x;
                dmem_wstrb = 'x;
            end
        endcase
    end

    // Read data must be shifted back and bit-extend
    always_comb begin
        case (mem_size)
            SIZE_B: case (mem_addr[1:0])
                2'b00: mem_rdata = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                2'b01: mem_rdata = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                2'b10: mem_rdata = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                2'b11: mem_rdata = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
            endcase
            SIZE_BU: case (mem_addr[1:0])
                2'b00: mem_rdata = {24'b0, dmem_rdata[7:0]};
                2'b01: mem_rdata = {24'b0, dmem_rdata[15:8]};
                2'b10: mem_rdata = {24'b0, dmem_rdata[23:16]};
                2'b11: mem_rdata = {24'b0, dmem_rdata[31:24]};
            endcase
            SIZE_H: case (mem_addr[1])
                1'b0: mem_rdata = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                1'b1: mem_rdata = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
            endcase
            SIZE_HU: case (mem_addr[1])
                1'b0: mem_rdata = {16'b0, dmem_rdata[15:0]};
                1'b1: mem_rdata = {16'b0, dmem_rdata[31:16]};
            endcase
            SIZE_W:  mem_rdata = dmem_rdata;
            default: mem_rdata = 'x;    // Should not happen
        endcase
    end

    // Reservation register
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) rsv_addr_valid <= 1'b0;
        else if (mem_stage_valid & mem_stage_ready) begin
            case (mem_rsv)
                // LR: set reservation to load addr
                RSV_SET: begin
                    rsv_addr_valid <= 1'b1;
                    rsv_addr       <= mem_addr[31:2];
                end
                // SC: clear reservation regardless
                RSV_CLEAR: begin
                    rsv_addr_valid <= 1'b0;
                end
                // Check for store to invalidate
                default: begin
                    if ((mem_dir == MEM_WRITE) & rsv_addr_matched)
                        rsv_addr_valid <= 1'b0;
                end
            endcase
        end
    end

    assign rsv_addr_matched = (rsv_addr == mem_addr[31:2]);

    // Reservation check
    assign mem_rsv_valid = rsv_addr_valid & rsv_addr_matched;

    // Last read data
    flope #(
        .WIDTH  (32)
    ) u_last_rdata(
        .clk    (clk),
        .en     (mem_stage_valid & mem_stage_ready),
        .d      (mem_rdata),
        .q      (mem_last_rdata)
    );

    // Access fault happens when memory interface returns with an error
    always_comb begin
        if (mem_done & dmem_err) begin
            case (mem_dir)
                MEM_READ: begin
                    ex_load_access_fault  = 1'b1;
                    ex_store_access_fault = 1'b0;
                end
                MEM_WRITE,
                MEM_READ_AMO: begin
                    ex_load_access_fault  = 1'b0;
                    ex_store_access_fault = 1'b1;
                end
                default: begin
                    ex_load_access_fault  = 1'b0;
                    ex_store_access_fault = 1'b0;
                end
            endcase
        end
        else begin
            ex_load_access_fault  = 1'b0;
            ex_store_access_fault = 1'b0;
        end
    end

endmodule
