#include "reg_utils.h"
#include "uart.h"

// Set baud rate (return div const)
uint16_t uart_set_baud_rate(int baud_rate, int clk_freq) {
    uint16_t div_const = (clk_freq + 8 * baud_rate) / (16 * baud_rate);
    reg_write_u8(UART_BASE, UART_REG_LCR, UART_LCR_DLAB);
    reg_write_u8(UART_BASE, UART_REG_DLL, div_const & 0xff);
    reg_write_u8(UART_BASE, UART_REG_DLM, div_const >> 8);
    return div_const;
}

// Config LCR
void uart_set_lcr(uint8_t config) {
    reg_write_u8(UART_BASE, UART_REG_LCR, config);
}

// Config FCR
void uart_set_fcr(uint8_t config) {
    reg_write_u8(UART_BASE, UART_REG_FCR, config);
}

// Config MCR
void uart_set_mcr(uint8_t config) {
    reg_write_u8(UART_BASE, UART_REG_MCR, config);
}

// Write a character to TX
void uart_putc(uint8_t c) {
    // Wait for THR empty
    while (!(reg_read_u8(UART_BASE, UART_REG_LSR) & UART_LSR_THR_EMPTY));
    // Send the character
    reg_write_u8(UART_BASE, UART_REG_THR, c);
}

// Read a character from RX
uint8_t uart_getc() {
    // Wait for data ready
    while (!(reg_read_u8(UART_BASE, UART_REG_LSR) & UART_LSR_DATA_READY));
    // Read the character
    return reg_read_u8(UART_BASE, UART_REG_RHR);
}

// Write a string to TX
int uart_write(uint8_t* buf) {
    int size = 0;
    while (*buf) {
        uart_putc(*buf);
        buf++;
        size++;
    }
    return size;
}

