#include "uart.h"

#define BAUD_RATE   115200
#define CLOCK_FREQ  (16 * BAUD_RATE)

int main() {
    // Register config
    uart_set_baud_rate(BAUD_RATE, CLOCK_FREQ);
    uart_set_lcr(UART_LCR_LEN_8 | UART_LCR_PARITY_NONE);
    uart_set_fcr(UART_FCR_FIFO_ENABLE);

    // Main loop
    while (1) {
        // Read a character
        uint8_t c = uart_getc();
        // Convert to uppercase
        if (c >= 'a' && c <= 'z')
            c += 'A' - 'a';
        // Write that character back
        uart_putc(c);
    }

    return 0;
}
