module core_misaligned_calc (
    input  core_pkg::mem_size_e  mem_size,
    input  logic [1:0]           mem_addr_offset,
    output logic                 mem_addr_misaligned
);

    import core_pkg::*;

    always_comb begin
        case (mem_size)
            SIZE_W:  mem_addr_misaligned = |mem_addr_offset;
            SIZE_H,
            SIZE_HU: mem_addr_misaligned = mem_addr_offset[0];
            default: mem_addr_misaligned = 1'b0;
        endcase
    end

endmodule
