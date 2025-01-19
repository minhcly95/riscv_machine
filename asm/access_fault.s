.global _start

.text
_start:
    j          reset_start
trap_vector:
    # Write index and mcause to .data
    csrr       t0, mcause
    sw         tp, 0(gp)
    sw         t0, 4(gp)
    addi       gp, gp, 8
    # Step to the next instr and return
    csrr       t1, mepc
    addi       t1, t1, 4
    csrw       mepc, t1
    mret
reset_start:
    # Intialize the trap vector
    la         gp, .data
    la         t0, trap_vector
    csrw       mtvec, t0
test_start:
    # Setup an invalid address
    li         a0, 0xbadbeef0
test_1:
    # Load
    li         tp, 1
    lw         t0, 0(a0)
test_2:
    # Store
    li         tp, 2
    sw         t0, 0(a0)
test_3:
    # Load reserve
    li         tp, 3
    lr.w       t0, (a0)
test_4:
    # Store conditional
    li         tp, 4
    sc.w       t0, t1, (a0)
test_5:
    # AMOSWAP
    li         tp, 5
    amoswap.w  t0, t1, (a0)
test_6:
    # AMOADD
    li         tp, 6
    amoadd.w   t0, t1, (a0)
test_7:
    # AMOXOR
    li         tp, 7
    amoxor.w   t0, t1, (a0)
test_8:
    # AMOOR
    li         tp, 8
    amoor.w    t0, t1, (a0)
test_9:
    # AMOAND
    li         tp, 9
    amoand.w   t0, t1, (a0)
test_10:
    # AMOMIN
    li         tp, 10
    amomin.w   t0, t1, (a0)
test_11:
    # AMOMAX
    li         tp, 11
    amomax.w   t0, t1, (a0)
test_12:
    # AMOMINU
    li         tp, 12
    amominu.w  t0, t1, (a0)
test_13:
    # AMOMAXU
    li         tp, 13
    amomaxu.w  t0, t1, (a0)
end:
    # End test with ecall
    ecall

