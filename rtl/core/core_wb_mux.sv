module core_wb_mux (
    // From FETCH stage
    input  logic [31:0]          pc_plus_4,
    // From EXEC stage
    input  core_pkg::wb_src_e    wb_src,
    input  logic [31:0]          exec_result,
    // From MEM stage
    input  logic [31:0]          mem_rdata,
    // To Reg file
    output logic                 reg_d_write,
    output logic [31:0]          reg_d_value
);

    import core_pkg::*;

    // Source selection
    always_comb begin
        case (wb_src)
            WB_FETCH: reg_d_value = pc_plus_4;
            WB_EXEC:  reg_d_value = exec_result;
            WB_MEM:   reg_d_value = mem_rdata;
            default:  reg_d_value = 'x;
        endcase
    end

    // Only write when not WB_NONE
    assign reg_d_write = (wb_src != WB_NONE);

endmodule
