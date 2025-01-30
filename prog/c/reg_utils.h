#ifndef __REG_UTILS_H__
#define __REG_UTILS_H__

#include <stdint.h>

// Write a byte of `data` to register at `base + offset`.
// offset must be constant.
inline void reg_write_u8(uint32_t base, int16_t offset, uint8_t data) {
    asm volatile ("sb %0, %2(%1)" : : "r" (data), "r" (base), "i" (offset) : "memory");
}

// Read a byte of `data` from register at `base + offset`.
// offset must be constant.
inline uint8_t reg_read_u8(uint32_t base, int16_t offset) {
    uint8_t data;
    asm volatile ("lbu %0, %2(%1)" : "=r" (data) : "r" (base), "i" (offset) : "memory");
    return data;
}

#endif

