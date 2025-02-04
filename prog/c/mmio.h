#ifndef __MMIO_H__
#define __MMIO_H__

#include <stdint.h>

#define MMIO_32(ADDR) ((volatile uint32_t*)(ADDR))
#define MMIO_16(ADDR) ((volatile uint16_t*)(ADDR))
#define MMIO_8(ADDR)  ((volatile uint8_t*)(ADDR))

#define BIT(I)        (1 << I)

#endif
