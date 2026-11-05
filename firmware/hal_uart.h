// ==============================================================================
// Header: hal_uart.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// ==============================================================================

#ifndef HAL_UART_H_
#define HAL_UART_H_

#include <stdint.h>

void uart_init(uint16_t baud_divisor);
void uart_putc(char c);
void uart_puts(const char *str);
char uart_getc(void);
int  uart_rx_ready(void);
void uart_print_hex(uint32_t val);
void uart_print_dec(int32_t val);

#endif // HAL_UART_H_
