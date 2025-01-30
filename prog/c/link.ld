OUTPUT_ARCH( "riscv" )
ENTRY(_start)


MEMORY {
    RAM (rwx)  : ORIGIN = 0x00000000, LENGTH = 1M
    UART (rw)  : ORIGIN = 0x80000000, LENGTH = 4K
}

SECTIONS
{
    . = 0x00000000;
    .text : {
        *(.startup)
        *(.text.startup)
        *(.text)
        __rodata = .;
        *(.rodata.*)
    }

    . = ALIGN(4K);
    .data : {
        *(.data)
    }

    . = ALIGN(4K);
    .bss : {
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

    __uart = ORIGIN(UART);
}

