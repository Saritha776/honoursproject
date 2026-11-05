// ==============================================================================
// Header: neuroedge_hw.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Complete memory map, register bitfield offsets, and hardware
//              abstraction register accessors.
// ==============================================================================

#ifndef NEUROEDGE_HW_H_
#define NEUROEDGE_HW_H_

#include <stdint.h>

// -----------------------------------------------------------------------------
// Base Addresses
// -----------------------------------------------------------------------------
#define ISRAM_BASE              0x00000000U
#define DSRAM_STACK_BASE        0x20000000U
#define DSRAM_WEIGHTS_BASE      0x20008000U
#define DSRAM_ACTS_BASE         0x2000A000U
#define DSRAM_OUTS_BASE         0x2000B000U

#define SPI_BASE                0x40000000U
#define DMA_BASE                0x40001000U
#define ARRAY_BASE              0x40002000U
#define UART_BASE               0x40003000U
#define TIMER_BASE              0x40004000U
#define WDT_BASE                0x40005000U
#define GPIO_BASE               0x40006000U
#define PIC_BASE                0x40007000U

// -----------------------------------------------------------------------------
// Peripheral Register Offsets
// -----------------------------------------------------------------------------

// SPI Controller Registers
#define SPI_REG_CTRL            (*(volatile uint32_t *)(SPI_BASE + 0x00))
#define SPI_REG_STATUS          (*(volatile uint32_t *)(SPI_BASE + 0x04))
#define SPI_REG_CLKDIV          (*(volatile uint32_t *)(SPI_BASE + 0x08))
#define SPI_REG_FLASH_ADDR      (*(volatile uint32_t *)(SPI_BASE + 0x0C))
#define SPI_REG_LENGTH          (*(volatile uint32_t *)(SPI_BASE + 0x10))

#define SPI_CTRL_EN             (1U << 0)
#define SPI_CTRL_START          (1U << 1)
#define SPI_CTRL_AUTO_READ      (1U << 2)

#define SPI_STATUS_BUSY         (1U << 0)
#define SPI_STATUS_DONE         (1U << 1)
#define SPI_STATUS_RX_EMPTY     (1U << 2)

// DMA Controller Registers
#define DMA_REG_CTRL            (*(volatile uint32_t *)(DMA_BASE + 0x00))
#define DMA_REG_STATUS          (*(volatile uint32_t *)(DMA_BASE + 0x04))
#define DMA_REG_CH0_SRC         (*(volatile uint32_t *)(DMA_BASE + 0x10))
#define DMA_REG_CH0_DST         (*(volatile uint32_t *)(DMA_BASE + 0x14))
#define DMA_REG_CH0_LEN         (*(volatile uint32_t *)(DMA_BASE + 0x18))
#define DMA_REG_CH1_SRC         (*(volatile uint32_t *)(DMA_BASE + 0x20))
#define DMA_REG_CH1_DST         (*(volatile uint32_t *)(DMA_BASE + 0x24))
#define DMA_REG_CH1_LEN         (*(volatile uint32_t *)(DMA_BASE + 0x28))

#define DMA_CTRL_EN             (1U << 0)
#define DMA_CTRL_CH0_EN         (1U << 1)
#define DMA_CTRL_CH1_EN         (1U << 2)

#define DMA_STATUS_BUSY         (1U << 0)
#define DMA_STATUS_CH0_DONE     (1U << 1)
#define DMA_STATUS_CH1_DONE     (1U << 2)
#define DMA_STATUS_ERR          (1U << 8)

// 4x4 Systolic Array Registers
#define ARRAY_REG_CTRL          (*(volatile uint32_t *)(ARRAY_BASE + 0x00))
#define ARRAY_REG_STATUS        (*(volatile uint32_t *)(ARRAY_BASE + 0x04))
#define ARRAY_REG_CFG           (*(volatile uint32_t *)(ARRAY_BASE + 0x08))
#define ARRAY_REG_WEIGHT_PORT   (*(volatile uint32_t *)(ARRAY_BASE + 0x10))
#define ARRAY_REG_ACT_PORT      (*(volatile uint32_t *)(ARRAY_BASE + 0x14))
#define ARRAY_REG_RES_0         (*(volatile int32_t  *)(ARRAY_BASE + 0x20))
#define ARRAY_REG_RES_1         (*(volatile int32_t  *)(ARRAY_BASE + 0x24))
#define ARRAY_REG_RES_2         (*(volatile int32_t  *)(ARRAY_BASE + 0x28))
#define ARRAY_REG_RES_3         (*(volatile int32_t  *)(ARRAY_BASE + 0x2C))

#define ARRAY_CTRL_EN           (1U << 0)
#define ARRAY_CTRL_START        (1U << 1)
#define ARRAY_CTRL_CLEAR_ACC    (1U << 2)

#define ARRAY_STATUS_BUSY       (1U << 0)
#define ARRAY_STATUS_DONE       (1U << 1)
#define ARRAY_STATUS_OVERFLOW   (1U << 2)

// UART Registers
#define UART_REG_TX_DATA        (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_REG_RX_DATA        (*(volatile uint32_t *)(UART_BASE + 0x04))
#define UART_REG_STATUS         (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_REG_BAUD_DIV       (*(volatile uint32_t *)(UART_BASE + 0x0C))

#define UART_STATUS_TX_BUSY     (1U << 0)
#define UART_STATUS_TX_FULL     (1U << 1)
#define UART_STATUS_RX_VALID    (1U << 2)
#define UART_STATUS_RX_OVERRUN  (1U << 3)

// Precision Timer Registers
#define TIMER_REG_CTRL          (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define TIMER_REG_CNT           (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define TIMER_REG_CMP           (*(volatile uint32_t *)(TIMER_BASE + 0x08))
#define TIMER_REG_STATUS        (*(volatile uint32_t *)(TIMER_BASE + 0x0C))

#define TIMER_CTRL_EN           (1U << 0)
#define TIMER_CTRL_AUTO_RELOAD  (1U << 1)
#define TIMER_STATUS_MATCH      (1U << 0)

// Watchdog Timer Registers
#define WDT_REG_CTRL            (*(volatile uint32_t *)(WDT_BASE + 0x00))
#define WDT_REG_KICK            (*(volatile uint32_t *)(WDT_BASE + 0x04))
#define WDT_REG_TIMEOUT         (*(volatile uint32_t *)(WDT_BASE + 0x08))
#define WDT_REG_STATUS          (*(volatile uint32_t *)(WDT_BASE + 0x0C))

#define WDT_KEY_RELOAD          0xA5A55A5AU
#define WDT_CTRL_EN             (1U << 0)
#define WDT_CTRL_RESET_EN       (1U << 1)
#define WDT_STATUS_BARK         (1U << 0)

// GPIO Registers
#define GPIO_REG_IN             (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_REG_OUT            (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define GPIO_REG_DIR            (*(volatile uint32_t *)(GPIO_BASE + 0x08))
#define GPIO_REG_STATUS         (*(volatile uint32_t *)(GPIO_BASE + 0x0C))

// Platform Interrupt Controller (PIC) Registers
#define PIC_REG_ENABLE          (*(volatile uint32_t *)(PIC_BASE + 0x00))
#define PIC_REG_PENDING         (*(volatile uint32_t *)(PIC_BASE + 0x04))
#define PIC_REG_PRIORITY        (*(volatile uint32_t *)(PIC_BASE + 0x08))
#define PIC_REG_ACK             (*(volatile uint32_t *)(PIC_BASE + 0x0C))

#define PIC_IRQ_WDT             (1U << 0)
#define PIC_IRQ_TIMER           (1U << 1)
#define PIC_IRQ_ARRAY           (1U << 2)
#define PIC_IRQ_DMA             (1U << 3)
#define PIC_IRQ_UART            (1U << 4)
#define PIC_IRQ_GPIO            (1U << 5)

#endif // NEUROEDGE_HW_H_
