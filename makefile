
DIR := ${CURDIR}

BUILD_DIR := ${DIR}/build
PROJECT_NAME := pico
BIN := ${BUILD_DIR}/${PROJECT_NAME}.uf2
PICO_DEV := /dev/disk/by-label/RPI-RP2
MNT_DIR := /mnt

help:
	@echo "Commands:"
	@echo "  env                  - Load the dev environment shell"
	@echo "  build                - Build the project"
	@echo "  program              - Program the pico"
	@echo "  serial               - Connect to the serial term"
	@echo "  program-then-serial  - Program the pico and then automatically connect to serial"
	@echo "  lsblk                - Monitor lsblk"
	@echo "  clean                - Clean build products"
	@echo "  clean-all            - Clean everything"
	@echo

env:
	nix develop -c $$SHELL

.PHONY:build
build: $(BIN)

lsblk:
	watch -n 0 lsblk -T -o NAME,SIZE,MOUNTPOINTS,LABEL

program: $(BIN)
	sudo mount -o uid=$(shell id -u),gid=$(shell id -g) $(PICO_DEV) $(MNT_DIR)
	cp $(BIN) $(MNT_DIR)
	sudo umount $(MNT_DIR)

serial:
	sudo picocom -b 115200 /dev/ttyACM0 --imap lfcrlf

program-then-serial:
	$(MAKE) program
	sleep 1.5
	$(MAKE) serial

clean:
	rm -rf zig-out
	rm -rf zig-cache .zig-cache
	rm -rf $(BUILD_DIR)

clean-all: clean
	rm -rf pico-sdk pico-examples



# Build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Zig build
zig-out/lib/lib${PROJECT_NAME}.a: *.zig $(BUILD_DIR)/generated/pico_base/pico
	@# zig build test && zig build -freference-trace build
	zig build -freference-trace build
	@echo

# == Repos ==
pico-examples:
	git clone https://github.com/raspberrypi/pico-examples.git

pico-sdk:
	git clone https://github.com/raspberrypi/pico-sdk.git
	cd $@; \
	git submodule update --init

# == CMAKE rules ==
$(BUILD_DIR)/generated/pico_base/pico: CMakeLists.txt | pico-sdk $(BUILD_DIR)
	@cd $(BUILD_DIR) && PICO_SDK_PATH=$(CURDIR)/pico-sdk cmake .. && make -j 20 depend

$(BIN): zig-out/lib/lib${PROJECT_NAME}.a CMakeLists.txt | pico-sdk Arduino-FOC $(BUILD_DIR)
	@cd $(BUILD_DIR) && PICO_SDK_PATH=$(CURDIR)/pico-sdk cmake .. && make -j 20 motor-demo
	@echo
	@echo == Done ==
	@echo

