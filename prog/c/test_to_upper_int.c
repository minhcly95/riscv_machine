#include "uart.h"
#include "plic.h"
#include "circ_buf.h"

#define BAUD_RATE     115200
#define CLOCK_FREQ    (16 * BAUD_RATE)

// Global variable
struct circ_buf rx_queue;

// Interrupt handler
void int_handler() {
    uint8_t buffer[14];
    int i;

    // Claim the interrupt
    int int_src = *PLIC_CLAIM(INT_TGT_M0);
    if (!int_src)
        return;

    // Get the interrupt code
    uint8_t int_code = *UART_ISR & UART_ISR_INT_MASK;

    switch (int_code) {
        case UART_ISR_INT_RX_DATA_READY:
            // We have 14 characters in the RX FIFO
            // So we can pop them all without checking LSR
            for (i = 0; i < 14; i++)
                buffer[i] = *UART_RHR;
            circ_buf_push(&rx_queue, buffer, 14);
            break;

        case UART_ISR_INT_RX_TIMEOUT:
            // We are not sure how many characters are in the RX FIFO
            // So we need the check LSR for every read
            for (i = 0; i < 14; i++)
                if (*UART_LSR & UART_LSR_DATA_READY)
                    buffer[i] = *UART_RHR;
                else
                    break;
            circ_buf_push(&rx_queue, buffer, i);
            break;
    }

    // Complete the interrupt
    *PLIC_COMPLETE(INT_TGT_M0) = int_src;
}

// This program capitalizes all letters received from UART and sends them back.
// It constantly polls to check for new data.
int main() {
    // Init the queues
    circ_buf_init(&rx_queue);

    // Config UART
    uart_set_baud_rate(BAUD_RATE, CLOCK_FREQ);
    *UART_IER = UART_IER_RX_DATA_READY;
    *UART_LCR = UART_LCR_LEN_8 | UART_LCR_PARITY_NONE;
    *UART_FCR = UART_FCR_FIFO_ENABLE | UART_FCR_TRIG_14;

    // Config PLIC
    *PLIC_INT_PRIORITY(INT_SRC_UART) = 1;
    *PLIC_THRESHOLD(INT_TGT_M0)      = 0;
    *PLIC_INT_ENABLE(INT_TGT_M0)     = BIT(INT_SRC_UART);

    uint8_t buffer[16];

    // Main application loop.
    // It relies on the interrupt handler 
    // to feed data into the RX queue
    // and free the TX queue up.
    while (1) {
        // Pop 16 characters from RX
        int len = circ_buf_pop(&rx_queue, buffer, 16);

        for (int i = 0; i < len; i++) {
            uint8_t c = buffer[i];
            // Convert to uppercase
            if (c >= 'a' && c <= 'z')
                c += 'A' - 'a';
            // Send it to TX
            uart_putc(c); 
        }
    }

    return 0;
}

