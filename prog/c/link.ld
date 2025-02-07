OUTPUT_ARCH( "riscv" )
ENTRY(_start)


MEMORY {
    RAM      (rwx) : ORIGIN = 0x00000000, LENGTH = 1M
    UART     (rw)  : ORIGIN = 0x80000000, LENGTH = 4K
    MTIME    (rw)  : ORIGIN = 0x80010000, LENGTH = 32K
    MTIMECMP (rw)  : ORIGIN = 0x80018000, LENGTH = 32K
    PLIC     (rw)  : ORIGIN = 0x90000000, LENGTH = 64M
}

SECTIONS
{
    . = 0x00000000;
    .output : {
        *(.startup)
        *(.text.startup)
        *(.text)
        __rodata = .;
        *(.rodata.*)
        __sdata = .;
        *(.sdata)
    }

    . = ALIGN(4K);
    .data : {
        __data = .;
        *(.data)
    }

    . = ALIGN(4K);
    .bss : {
        __bss = .;
        *(.bss)
    }

    . = ALIGN(4K);
    .stack : {
        . = ALIGN(4);
        __stack_end = .;
        . = ORIGIN(RAM) + LENGTH(RAM);
        . = ALIGN(4);
        __stack_start = .;
    }

    __uart     = ORIGIN(UART);
    __mtime    = ORIGIN(MTIME);
    __mtimecmp = ORIGIN(MTIMECMP);
    __plic     = ORIGIN(PLIC);
}

