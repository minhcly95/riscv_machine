.global _start

.text
_start:
    li   x1, 1
    li   x2, 1
    li   x3, 40
    la   x31, .data
loop:
    add  x1, x1, x2
    sub  x2, x1, x2
    sw   x1, 0(x31)
    addi x31, x31, 4
    addi x3, x3, -1
    bne  x3, x0, loop
end:
    ecall
