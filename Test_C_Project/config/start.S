/* start.S
 *
 * Minimal RV32I bare-metal startup for the provided linker script.
 *
 * Responsibilities:
 *   - Set stack pointer
 *   - Copy .data from FLASH to SRAM
 *   - Zero .bss
 *   - Call main()
 *   - Trap forever if main returns
 *
 * Expected symbols from linker script:
 *   _estack
 *   _sidata
 *   _sdata
 *   _edata
 *   _sbss
 *   _ebss
 */

    .section .text._start
    .globl _start
    .type _start, @function

_start:
    /* --------------------------------------------------------- */
    /* Set up stack pointer                                      */
    /* --------------------------------------------------------- */
    la      sp, _estack

    /* Optional: clear frame pointer */
    li      fp, 0

    /* --------------------------------------------------------- */
    /* Copy initialized data (.data) from FLASH to SRAM          */
    /* --------------------------------------------------------- */
    la      a0, _sidata      /* source in FLASH */
    la      a1, _sdata       /* destination in SRAM */
    la      a2, _edata       /* end of .data */

1:
    bgeu    a1, a2, 2f
    lw      t0, 0(a0)
    sw      t0, 0(a1)
    addi    a0, a0, 4
    addi    a1, a1, 4
    j       1b

    /* --------------------------------------------------------- */
    /* Zero initialize .bss                                      */
    /* --------------------------------------------------------- */
2:
    la      a0, _sbss
    la      a1, _ebss
    li      t0, 0

3:
    bgeu    a0, a1, 4f
    sw      t0, 0(a0)
    addi    a0, a0, 4
    j       3b

    /* --------------------------------------------------------- */
    /* Call main()                                               */
    /* --------------------------------------------------------- */
4:
    call    main

    /* --------------------------------------------------------- */
    /* If main returns, loop forever                             */
    /* --------------------------------------------------------- */
5:
    wfi
    j       5b

.size _start, . - _start