#include "uart.h"
#include "mtimer.h"

#define BAUD_RATE   115200
#define CLOCK_FREQ  (16 * BAUD_RATE)
#define DELTA_T     1000

volatile int int_cnt;

void set_next_event() {
    // Ignore the high part
    *MTIMECMP = *MTIME + DELTA_T;
}

// Interrupt handler
void int_handler() {
    int_cnt++;
    set_next_event();
}

// This program sends a character every timer interrupt.
// The first character is ASCII 0, second is ASCII 1, and so on.
int main() {
    // Register config
    uart_set_baud_rate(BAUD_RATE, CLOCK_FREQ);
    *UART_LCR = UART_LCR_LEN_8 | UART_LCR_PARITY_NONE;
    *UART_FCR = UART_FCR_FIFO_ENABLE;

    // Start the timer interrupt
    set_next_event();
    *MTIMECMPH = 0;

    int sent_cnt = 0;
    int_cnt = 0;

    // Main loop
    while (1) {
        // Wait until there is an interrupt
        while (sent_cnt == int_cnt) ;
        // Send a character
        uint8_t c = sent_cnt & 0xff;
        uart_putc(c);
        // Increase the counter
        sent_cnt++;
    }

    return 0;
}
