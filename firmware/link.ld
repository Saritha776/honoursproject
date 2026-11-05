/* ==============================================================================
 * Linker Script: link.ld
 * Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
 * Target Memory Map:
 *   Instruction SRAM : 0x0000_0000 - 0x0000_7FFF (32 KB)
 *   Data SRAM        : 0x2000_0000 - 0x2000_FFFF (64 KB)
 * ============================================================================== */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    ISRAM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
    DSRAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
    /* Code segment located in Instruction SRAM */
    .text : {
        . = ALIGN(4);
        *(.text.init)
        *(.text .text.*)
        *(.rodata .rodata.*)
        . = ALIGN(4);
        _etext = .;
    } > ISRAM

    /* Initialized data placed in Data SRAM */
    .data : AT(_etext) {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        _edata = .;
    } > DSRAM

    /* Zero-initialized BSS section */
    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > DSRAM

    /* Stack grows downwards from top of application stack memory */
    PROVIDE(_stack_top = 0x20007FE0);
}
