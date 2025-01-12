.global _start

.text
_start:
    la      a0, .data
    la      a1, .data + 0x1000
    la      a2, .data + 0x2000
    la      a3, .data + 0x3000
    la      a4, .data + 0x4000
    la      a5, .data + 0x5000
    li      gp, 1024
loop:
    lw      t0, 0(a0)
    lw      t1, 0(a1)
    div     t2, t0, t1
    sw      t2, 0(a2)
    divu    t2, t0, t1
    sw      t2, 0(a3)
    rem     t2, t0, t1
    sw      t2, 0(a4)
    remu    t2, t0, t1
    sw      t2, 0(a5)
    addi    a0, a0, 4
    addi    a1, a1, 4
    addi    a2, a2, 4
    addi    a3, a3, 4
    addi    a4, a4, 4
    addi    a5, a5, 4
    addi    gp, gp, -1
    bnez    gp, loop
end:
    ecall

