.global _start

.text
_start:
    # Address of input address
    la      s0, .data
    # Address of output data
    la      s1, .data + 0x1000
    # Address of root page table
    la      s2, .data + 0x2000
    # Set SATP
    srli    s2, s2, 12
    li      t0, 0x80000000
    or      s2, s2, t0
    csrw    satp, s2
    # Set MPP to S-mode
    li      t0, 0x1800
    csrc    mstatus, t0     # Clear MPP
    li      t1, 0x0800
    csrs    mstatus, t1     # Set MPP
    # Init the loop
    li      s3, 0x20000     # Bit 17 of mstatus (MPRV)
    li      gp, 1024
loop:
    # Load the virtual address
    lw      a0, 0(s0)
    # Set MPRV to enable translation
    csrs    mstatus, s3
    # Load the data (with translation)
    lw      a1, 0(a0)
    # Clear MPRV to disable translation
    csrc    mstatus, s3
    # Store the result
    sw      a1, 0(s1)
    # Advance the loop
    addi    s0, s0, 4
    addi    s1, s1, 4
    addi    gp, gp, -1
    bnez    gp, loop
end:
    ecall

