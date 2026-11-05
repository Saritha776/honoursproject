/* ==============================================================================
 * Assembly: crt0.S
 * Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
 * Description: RISC-V C runtime initialization and vector table setup.
 * ============================================================================== */

    .section .text.init
    .global _start
    .type _start, @function

_start:
    /* Disable interrupts globally */
    csrci   mstatus, 8

    /* Set up stack pointer (0x20007FE0) */
    la      sp, _stack_top

    /* Set Machine Trap Vector Base Address (mtvec) */
    la      t0, trap_entry
    csrw    mtvec, t0

    /* Clear BSS section */
    la      t0, _sbss
    la      t1, _ebss
bss_clear_loop:
    bge     t0, t1, bss_done
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       bss_clear_loop
bss_done:

    /* Call main application entry */
    call    main

    /* If main returns, loop forever */
halt_loop:
    wfi
    j       halt_loop

    /* Trap Handler */
    .align 4
trap_entry:
    /* Minimal trap handler: loop */
    mret
