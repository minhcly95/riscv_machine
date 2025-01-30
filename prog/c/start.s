.section .startup, "ax"
.global _start

_start:
    # Set stack pointer
    la  sp, __stack_start
    # Jump to main
    jal main
    # If main returns, we call the environment
    ecall
_end:
    # If ecall returns, loop here forever
    j   _end
