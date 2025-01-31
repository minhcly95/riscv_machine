.global _start

.text
_start:
    # Setup the trap handler
    la      t0, _trap_hdlr
    csrw    mtvec, t0
    # Setup mie and meie
    la      gp, .data
set_mie:
    # Set MIE if 0x1000 is set
    lw      a0, 0(gp)
    beqz    a0, set_meie
    li      t0, 0x88    # Set both mie and mpie
    csrs    mstatus, t0
set_meie:
    # Set MEIE if 0x1004 is set
    lw      a1, 4(gp)
    beqz    a1, ret_umode
    li      t0, 0x800   # Set meie
    csrs    mie, t0
ret_umode:
    # Return to U-mode if 0x1008 is set
    lw      a1, 8(gp)
    beqz    a1, main
    la      t0, main
    csrw    mepc, t0
    mret
main:
    # Loop 100 times
    li      s0, 100
loop:
    addi    s0, s0, -1
    bnez    s0, loop
    ecall
_trap_hdlr:
    csrr    a0, mcause
    # If Ecall, then no interrupt happened
    li      s0, 8
    beq     a0, s0, no_int
    li      s0, 11
    beq     a0, s0, no_int
    j       output
no_int:
    li      a0, 0x80000000
output:
    sw      a0, 16(gp)
    csrr    a1, mip
    sw      a1, 20(gp)
end:
    j       end

