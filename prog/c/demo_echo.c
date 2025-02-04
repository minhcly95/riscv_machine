#include "uart.h"

#define BAUD_RATE   115200
#define CLOCK_FREQ  (16 * BAUD_RATE)

int main() {
    // Register config
    uart_set_baud_rate(BAUD_RATE, CLOCK_FREQ);
    *UART_LCR = UART_LCR_LEN_8 | UART_LCR_PARITY_NONE;
    *UART_FCR = UART_FCR_FIFO_ENABLE;

    // Wait for any input
    uart_getc();

    // Print help
    uart_write("This program will echo user's input.\r\n");
    uart_write("Press CTRL+C to exit.\r\n");

    // Main loop
    while (1) {
        // Read a character
        uint8_t c = uart_getc();

        // If encounter ETX, end the transmission
        if (c == '\3')
            break;
        // If encounter DEL, put "\b \b" instead
        if (c == '\x7f') {
            uart_putc('\b');
            uart_putc(' ');
            uart_putc('\b');
        }
        // Convert \r to \r\n
        if (c == '\r') {
            uart_putc('\r');
            uart_putc('\n');
        }
        // Otherwise, write that character back
        else
            uart_putc(c);
    }

    return 0;
}
