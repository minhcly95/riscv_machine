#ifndef __MTIMER_H__
#define __MTIMER_H__

#include "mmio.h"

#define MTIME       MMIO_32(0x80010000)
#define MTIMEH      MMIO_32(0x80010004)
#define MTIMECMP    MMIO_32(0x80018000)
#define MTIMECMPH   MMIO_32(0x80018004)

#endif

