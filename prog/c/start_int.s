.section .startup, "ax"
.global _start

_start:
    # Set stack pointer
    la      sp, __stack_start
    # Configure the interrupt handler
    la      t0, _trap_handler
    csrw    mtvec, t0
    # Enable interrupt (external and timer)
    li      t1, 0x880
    csrs    mie, t1
    csrsi   mstatus, 0x8
    # Jump to main
    jal     main
    # If main returns, we call the environment
    ecall
_halt:
    # If ecall returns, loop here forever
    j       _halt
_trap_handler:
    # We need to save the current context to the stack
    # before passing to the C's interrupt handler.
    # Based on the calling convention, we only need
    # to preserve ra, t0-t6, and a0-a7 registers.
    # s0-s11 will be preserved by the C's interrupt handler.
    addi    sp, sp, -64     # 16 registers in total
    sw      ra, 60(sp)
    sw      t0, 56(sp)
    sw      t1, 52(sp)
    sw      t2, 48(sp)
    sw      t3, 44(sp)
    sw      t4, 40(sp)
    sw      t5, 36(sp)
    sw      t6, 32(sp)
    sw      a0, 28(sp)
    sw      a1, 24(sp)
    sw      a2, 20(sp)
    sw      a3, 16(sp)
    sw      a4, 12(sp)
    sw      a5, 8(sp)
    sw      a6, 4(sp)
    sw      a7, 0(sp)
    # Make sure we only handle interrupt
    csrr    t0, mcause
    bgez    t0, _halt
_enter_int_handler:
    # Jump to C's interrupt handler
    jal     int_handler
    # Check mip to see if there is pending interrupt
    csrr    t0, mip
    li      t1, 0x800
    and     t2, t0, t1
    # If there is, go back to the interrupt handler
    bnez    t2, _enter_int_handler
    # Restore the context
    lw      ra, 60(sp)
    lw      t0, 56(sp)
    lw      t1, 52(sp)
    lw      t2, 48(sp)
    lw      t3, 44(sp)
    lw      t4, 40(sp)
    lw      t5, 36(sp)
    lw      t6, 32(sp)
    lw      a0, 28(sp)
    lw      a1, 24(sp)
    lw      a2, 20(sp)
    lw      a3, 16(sp)
    lw      a4, 12(sp)
    lw      a5, 8(sp)
    lw      a6, 4(sp)
    lw      a7, 0(sp)
    addi    sp, sp, 64
    # Return from interrupt
    mret

