BUILD_DIR = $(PROJ_DIR)/build/dt

.PHONY: build clean

build: $(BUILD_DIR)/riscv_machine.dtb

$(BUILD_DIR)/riscv_machine.dtb: $(PROJ_DIR)/dt/riscv_machine.dts | $(BUILD_DIR)
	dtc -O dtb -o $@ $<

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -f $(BUILD_DIR)/riscv_machine.dtb
