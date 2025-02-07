#include "uart.h"

// Set baud rate (return div const)
uint16_t uart_set_baud_rate(int baud_rate, int clk_freq) {
    uint16_t div_const = (clk_freq + 8 * baud_rate) / (16 * baud_rate);
    uint8_t lcr = *UART_LCR;
    *UART_LCR = lcr | UART_LCR_DLAB;
    *UART_DLL = div_const & 0xff;
    *UART_DLM = div_const >> 8;
    *UART_LCR = lcr;
    return div_const;
}

// Write a string to TX
int uart_write(char* buf) {
    int size = 0;
    while (*buf) {
        uart_putc(*buf);
        buf++;
        size++;
    }
    return size;
}

