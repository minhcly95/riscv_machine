#ifndef __RISCV_H__
#define __RISCV_H__

#include <stdint.h>

// Store a byte of `data` to memory at `base + offset`.
// offset must be constant.
inline void riscv_sb(uint32_t base, int16_t offset, uint8_t data) {
    asm volatile ("sb %0, %2(%1)" : : "r" (data), "r" (base), "i" (offset) : "memory");
}

// Load an unsigned byte of `data` from memory at `base + offset`.
// offset must be constant.
inline uint8_t riscv_lbu(uint32_t base, int16_t offset) {
    uint8_t data;
    asm volatile ("lbu %0, %2(%1)" : "=r" (data) : "r" (base), "i" (offset));
    return data;
}

#endif

