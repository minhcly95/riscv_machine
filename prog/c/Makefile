TARGET ?= riscv32-unknown-linux-gnu

PROGS     = to_upper demo_echo
PROG_DIR = $(PROJ_DIR)/build/c
PROG_BIN  = $(addprefix $(PROG_DIR)/,$(addsuffix .bin,$(PROGS)))
PROG_OBJ  = $(addprefix $(PROG_DIR)/,$(addsuffix .o,$(PROGS)))
PROG_DUMP = $(addprefix $(PROG_DIR)/,$(addsuffix .dump,$(PROGS)))

GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -O3 -march=rv32ima_zicsr -mabi=ilp32 

.PHONY: build clean

build: $(PROG_BIN) $(PROG_DUMP)

$(PROG_BIN) $(PROG_OBJ) $(PROG_DUMP): | $(PROG_DIR)

$(PROG_DIR):
	mkdir -p $(PROG_DIR)

$(PROG_DIR)/to_upper.o: to_upper.c uart.c

$(PROG_DIR)/demo_echo.o: demo_echo.c uart.c

$(PROG_DIR)/%.bin: $(PROG_DIR)/%.o
	$(TARGET)-objcopy -j .text -O binary $< $@

$(PROG_DIR)/%.o: start.s
	$(TARGET)-gcc $(GCC_OPTS) -T link.ld -o $@ $^

$(PROG_DIR)/%.dump: $(PROG_DIR)/%.o
	$(TARGET)-objdump -D $< > $@

clean:
	rm -f $(PROG_BIN)
	rm -f $(PROG_OBJ)
	rm -f $(PROG_DUMP)
