TARGET ?= riscv32-unknown-linux-gnu

ASM = fibonacci seq_mul seq_div
ASM_DIR = $(PROJ_DIR)/build/asm
ASM_BIN = $(addprefix $(ASM_DIR)/,$(addsuffix .bin,$(ASM)))
ASM_OBJ = $(addprefix $(ASM_DIR)/,$(addsuffix .o,$(ASM)))

GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles

.PHONY: asm clean

asm: $(ASM_BIN)

$(ASM_BIN): | $(ASM_DIR)

$(ASM_DIR):
	mkdir -p $(ASM_DIR)

$(ASM_DIR)/%.bin: $(ASM_DIR)/%.o
	$(TARGET)-objcopy -j .text -O binary $< $@

$(ASM_DIR)/%.o: %.s
	$(TARGET)-gcc $(GCC_OPTS) -march=rv32ima_zicsr -mabi=ilp32 -T link.ld -o $@ $<

clean:
	rm -f $(ASM_BIN)
	rm -f $(ASM_OBJ)
