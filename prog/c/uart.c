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

// Write a character to TX
void uart_putc(uint8_t c) {
    // Wait for THR empty
    while (!(*UART_LSR & UART_LSR_THR_EMPTY));
    // Send the character
    *UART_THR = c;
}

// Read a character from RX
uint8_t uart_getc() {
    // Wait for data ready
    while (!(*UART_LSR & UART_LSR_DATA_READY));
    // Read the character
    return *UART_RHR;
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

