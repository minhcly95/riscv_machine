.section .startup, "ax"
.global _start

_start:
    # Set stack pointer
    la  sp, __stack_start
    # Jump to main
    j   main
_end:
    # If main returns, we loop here forever
    j   _end
