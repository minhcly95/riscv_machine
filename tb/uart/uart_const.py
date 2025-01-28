from enum import Enum


def xor_all(data: int) -> int:
    result = 0
    while data != 0:
        result ^= data & 1
        data >>= 1
    return result


class WordLength(Enum):
    WORD_5 = 0b00
    WORD_6 = 0b01
    WORD_7 = 0b10
    WORD_8 = 0b11

    def length(self):
        return self.value + 5

    def cast_str(self, s):
        mask = (1 << self.length()) - 1
        return "".join(chr(ord(c) & mask) for c in s)


class StopMode(Enum):
    SINGLE = 0b0_00
    DOUBLE = 0b1_00


class ParityMode(Enum):
    NONE   = 0b000_000
    ODD    = 0b001_000
    EVEN   = 0b011_000
    FORCE1 = 0b101_000
    FORCE0 = 0b111_000
    def gen(self, data):
        if self == ParityMode.ODD:
            return xor_all(data) ^ 1
        elif self == ParityMode.EVEN:
            return xor_all(data)
        elif self == ParityMode.FORCE1:
            return 1
        elif self == ParityMode.FORCE0:
            return 0
        else:
            return None


class TriggerLevel(Enum):
    TRIG_1  = 0b00_000000
    TRIG_4  = 0b01_000000
    TRIG_8  = 0b10_000000
    TRIG_14 = 0b11_000000
    def length(self):
        return [1, 4, 8, 14][self.value]


REG_THR = 0
REG_RHR = 0
REG_IER = 1
REG_FCR = 2
REG_ISR = 2
REG_LCR = 3
REG_MCR = 4
REG_LSR = 5
REG_MSR = 6
REG_SPR = 7
REG_DLL = 0
REG_DLM = 1

IER_RX_DATA_READY = 0x01
IER_THR_EMPTY     = 0x02
IER_RX_LINE_STAT  = 0x04

ISR_INT_MASK           = 0x0f
ISR_INT_NONE           = 0b0001
ISR_INT_RX_LINE_STAT   = 0b0110
ISR_INT_RX_DATA_READY  = 0b0100
ISR_INT_RX_TIMEOUT     = 0b1100
ISR_INT_THR_EMPTY      = 0b0010

FCR_FIFO_ENABLE   = 0x01

LCR_DLAB          = 0x80

LSR_DATA_READY    = 0x01
LSR_OVERRUN_ERR   = 0x02
LSR_PARITY_ERR    = 0x04
LSR_FRAME_ERR     = 0x08
LSR_BREAK_INT     = 0x10
LSR_THR_EMPTY     = 0x20
LSR_TX_EMPTY      = 0x40
LSR_FIFO_ERR      = 0x80

