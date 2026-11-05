// ==============================================================================
// Source: hal_uart.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// ==============================================================================

#include "neuroedge_hw.h"
#include "hal_uart.h"

void uart_init(uint16_t baud_divisor) {
    UART_REG_BAUD_DIV = (uint32_t)baud_divisor;
}

void uart_putc(char c) {
    // Wait until TX FIFO is not full
    while (UART_REG_STATUS & UART_STATUS_TX_FULL);
    UART_REG_TX_DATA = (uint32_t)c;
}

void uart_puts(const char *str) {
    while (*str) {
        if (*str == '\n') {
            uart_putc('\r');
        }
        uart_putc(*str++);
    }
}

int uart_rx_ready(void) {
    return (UART_REG_STATUS & UART_STATUS_RX_VALID) ? 1 : 0;
}

char uart_getc(void) {
    while (!uart_rx_ready());
    return (char)(UART_REG_RX_DATA & 0xFF);
}

void uart_print_hex(uint32_t val) {
    const char hex_chars[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex_chars[(val >> i) & 0xF]);
    }
}

void uart_print_dec(int32_t val) {
    char buf[12];
    int idx = 0;
    uint32_t uval;

    if (val < 0) {
        uart_putc('-');
        uval = (uint32_t)(-val);
    } else {
        uval = (uint32_t)val;
    }

    if (uval == 0) {
        uart_putc('0');
        return;
    }

    while (uval > 0) {
        buf[idx++] = (char)('0' + (uval % 10));
        uval /= 10;
    }

    for (int i = idx - 1; i >= 0; i--) {
        uart_putc(buf[i]);
    }
}
