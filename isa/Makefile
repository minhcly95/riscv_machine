TARGET ?= riscv32-unknown-linux-gnu

ISA += $(shell cat rv32ui.txt)
ISA += $(shell cat rv32um.txt)
ISA += $(shell cat rv32ua.txt)
ISA += $(shell cat rv32mi.txt)
ISA += $(shell cat rv32si.txt)
ISA_DIR = $(PROJ_DIR)/build/isa
ISA_BIN = $(addprefix $(ISA_DIR)/,$(addsuffix .bin,$(ISA)))

.PHONY: isa clean

isa: $(ISA_BIN)

$(ISA_BIN): | $(ISA_DIR)

$(ISA_DIR):
	mkdir -p $(ISA_DIR)

$(ISA_DIR)/%.bin: $(RISCV_TESTS)/isa/%
	$(TARGET)-objcopy -O binary $< $@

clean:
	rm -f $(ISA_BIN)
