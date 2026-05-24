MEMORY
{
    FLASH (rx)  : ORIGIN = 0x01000000, LENGTH = 1M
    SRAM  (rwx) : ORIGIN = 0x02000000, LENGTH = 8K
}

STACK_SIZE = 2K;

SECTIONS
{
    /* Flash: interrupt vectors and code */
    . = ORIGIN(FLASH);
    .text : ALIGN(4)
    {
        KEEP(*(.text._start))   /* ensure _start is first */
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        . = ALIGN(4);
        _etext = .;             /* end of code / load data */
    } > FLASH

    /* SRAM: initialised data (copied from flash at startup) */
    .data : ALIGN(4)
    {
        _sdata = .;             /* VMA start of data */
        *(.data .data.*)

        . = ALIGN(4);
        _edata = .;             /* VMA end of data */
    } > SRAM AT > FLASH
    _sidata = LOADADDR(.data);  /* LMA of data in flash */

    /* SRAM: uninitialised data (zeroed at startup) */
    .bss : ALIGN(4)
    {
        _sbss = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > SRAM

    /* Heap start (optional, for malloc) */
    _end = _ebss;
    _heap_start = _ebss;

    /* Stack – placed at the top of SRAM, growing downward */
    .stack (ORIGIN(SRAM) + LENGTH(SRAM) - STACK_SIZE) (NOLOAD) : ALIGN(16)
    {
        _stack_start = .;
        . += STACK_SIZE;
        . = ALIGN(16);
        _stack_top = .;
    }
    /* Top of SRAM: initial stack pointer value */
    _estack = ORIGIN(SRAM) + LENGTH(SRAM);

    /* Ensure final alignment */
    . = ALIGN(4);
}