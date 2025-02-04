#ifndef __PLIC_H__
#define __PLIC_H__

#include <stdint.h>
#include "mmio.h"

#define PLIC_BASE               0x90000000

#define PLIC_INT_PRIORITY(SRC)  MMIO_32(PLIC_BASE + 0x4 * SRC)
#define PLIC_INT_PENDING        MMIO_32(PLIC_BASE + 0x1000)
#define PLIC_INT_ENABLE(TGT)    MMIO_32(PLIC_BASE + 0x2000 + 0x80 * TGT)
#define PLIC_THRESHOLD(TGT)     MMIO_32(PLIC_BASE + 0x200000 + 0x1000 * TGT)
#define PLIC_CLAIM(TGT)         MMIO_32(PLIC_BASE + 0x200004 + 0x1000 * TGT)
#define PLIC_COMPLETE(TGT)      MMIO_32(PLIC_BASE + 0x200004 + 0x1000 * TGT)

#define INT_SRC_UART            1

#define INT_TGT_M0              0
#define INT_TGT_S0              1

#endif

