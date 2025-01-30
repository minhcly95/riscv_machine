#ifndef __UART_H__
#define __UART_H__

#include <stdint.h>

#define UART_BASE                    0x80000000

#define UART_REG_THR                 0x0
#define UART_REG_RHR                 0x0
#define UART_REG_IER                 0x1
#define UART_REG_FCR                 0x2
#define UART_REG_ISR                 0x2
#define UART_REG_LCR                 0x3
#define UART_REG_MCR                 0x4
#define UART_REG_LSR                 0x5
#define UART_REG_MSR                 0x6
#define UART_REG_SPR                 0x7
#define UART_REG_DLL                 0x0
#define UART_REG_DLM                 0x1

#define UART_IER_RX_DATA_READY       0x01
#define UART_IER_THR_EMPTY           0x02
#define UART_IER_RX_LINE_STAT        0x04

#define UART_ISR_INT_MASK            0x0f
#define UART_ISR_INT_NONE            0x01
#define UART_ISR_INT_RX_LINE_STAT    0x06
#define UART_ISR_INT_RX_DATA_READY   0x04
#define UART_ISR_INT_RX_TIMEOUT      0x0c
#define UART_ISR_INT_THR_EMPTY       0x02

#define UART_FCR_FIFO_ENABLE         0x01
#define UART_FCR_RX_RESET            0x02
#define UART_FCR_TX_RESET            0x04
#define UART_FCR_TRIG_1              0x00
#define UART_FCR_TRIG_4              0x40
#define UART_FCR_TRIG_8              0x80
#define UART_FCR_TRIG_14             0xc0

#define UART_LCR_LEN_MASK            0x03
#define UART_LCR_LEN_5               0x00
#define UART_LCR_LEN_6               0x01
#define UART_LCR_LEN_7               0x02
#define UART_LCR_LEN_8               0x03

#define UART_LCR_DOUBLE_STOP         0x04
#define UART_LCR_PARITY_EN           0x08
#define UART_LCR_EVEN_PARITY         0x10
#define UART_LCR_FORCE_PARITY        0x20
#define UART_LCR_SET_BREAK           0x40
#define UART_LCR_DLAB                0x80

#define UART_LCR_PARITY_MASK         0x38
#define UART_LCR_PARITY_NONE         0x00
#define UART_LCR_PARITY_ODD          0x08
#define UART_LCR_PARITY_EVEN         0x18
#define UART_LCR_PARITY_FORCE1       0x28
#define UART_LCR_PARITY_FORCE0       0x38

#define UART_MCR_LOOPBACK            0x10

#define UART_LSR_DATA_READY          0x01
#define UART_LSR_OVERRUN_ERR         0x02
#define UART_LSR_PARITY_ERR          0x04
#define UART_LSR_FRAME_ERR           0x08
#define UART_LSR_BREAK_INT           0x10
#define UART_LSR_THR_EMPTY           0x20
#define UART_LSR_TX_EMPTY            0x40
#define UART_LSR_FIFO_ERR            0x80

#define UART_LCR_DEFAULT             (UART_LCR_LEN_8 | UART_LCR_PARITY_NONE)

// Set baud rate (return div const)
uint16_t uart_set_baud_rate(int baud_rate, int clk_freq);

// Config LCR
void uart_set_lcr(uint8_t config);

// Config FCR
void uart_set_fcr(uint8_t config);

// Config MCR
void uart_set_mcr(uint8_t config);

// Write a character to TX
void uart_putc(uint8_t c);

// Read a character from RX
uint8_t uart_getc();

// Write a string to TX
int uart_write(uint8_t* buf);

#endif

