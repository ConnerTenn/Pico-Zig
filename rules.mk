.ONESHELL:

export PROJECT_NAME ?= pico
# PICO_TARGET ?= rp2040
EXTRA_LIB_DEPENDENCIES ?= 


RUN_DIR := ${CURDIR}
FILE_DIR := ${realpath ${dir ${lastword ${MAKEFILE_LIST}}}}

BUILD_DIR := ${RUN_DIR}/build
BIN := ${BUILD_DIR}/${PROJECT_NAME}.uf2
MNT_DIR := /mnt

# rp2040, rp2350, rp2350-riscv, rp2350-arm-s
PICO_PLATFORM ?=
# See pico-sdk/src/boards/include/boards
# pico, pico_w, pico2, pico2_w
PICO_BOARD ?=
# /dev/disk/by-label/<name>
PICO_DEV ?=

ifeq (${PICO_PLATFORM},)
$(error "You must specify PICO_PLATFORM")
endif

ifeq (${PICO_BOARD},)
$(error "You must specify PICO_BOARD")
endif

ifeq (${PICO_DEV},)
$(error "You must specify PICO_DEV")
endif


ifeq (${PICO_PLATFORM}, rp2040)
ZIG_TARGET:= rp2040
else ifeq (${PICO_PLATFORM}, rp2350)
ZIG_TARGET:= rp2350
else ifeq (${PICO_PLATFORM}, rp2350-riscv)
ZIG_TARGET:= rp2350
else ifeq (${PICO_PLATFORM}, rp2350-arm-s)
ZIG_TARGET:= rp2350
else
$(error "Invalid PICO_PLATFORM selected: ${PICO_PLATFORM}")
endif



# == Rules ==
help:
	@echo "Commands:"
	@echo "  env                  - Load the dev environment shell"
	@echo "  build                - Build the project"
	@echo "  test                 - Run tests for the project"
	@echo "  program              - Program the pico"
	@echo "  serial               - Connect to the serial term"
	@echo "  program-then-serial  - Program the pico and then automatically connect to serial"
	@echo "  lsblk                - Monitor lsblk"
	@echo "  examples             - Download the examples"
	@echo "  clean                - Clean build products"
	@echo "  clean-all            - Clean everything"
	@echo

env: ${RUN_DIR}/flake.nix
	cd ${RUN_DIR}/
	nix --show-trace develop .?submodules=1 -c $$SHELL

.PHONY:build
build: $(BIN)

.PHONY: test
test:
	zig test Pico-Zig/test.zig

.PHONY: program
program: | $(BIN)
	sudo mount -o uid=$(shell id -u),gid=$(shell id -g) $(PICO_DEV) $(MNT_DIR)
	cp $(BIN) $(MNT_DIR)
	sudo umount $(MNT_DIR)

.PHONY: serial
serial:
	sudo picocom -b 115200 /dev/ttyACM0 --imap lfcrlf

.PHONY: program-then-serial
program-then-serial:
	$(MAKE) program
	sleep 1.5
	$(MAKE) serial

.PHONY: lsblk
lsblk:
	watch -n 0 lsblk -T -o NAME,SIZE,MOUNTPOINTS,LABEL

.PHONY: examples
examples: ${RUN_DIR}/pico-examples

.PHONY: clean
clean:
	rm -rf ${RUN_DIR}/zig-out
	rm -rf ${RUN_DIR}/zig-cache ${RUN_DIR}/.zig-cache
	rm -rf $(BUILD_DIR)

.PHONY: clean-all
clean-all: clean
	rm -rf ${RUN_DIR}/pico-sdk ${RUN_DIR}/pico-examples
	rm -rf ${RUN_DIR}/flake.lock



# == Internal Rules ==

# Build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# # Flake handling
# ${RUN_DIR}/flake.nix:
# 	cp ${FILE_DIR}/flake.nix ${RUN_DIR}

# Zig build
${RUN_DIR}/zig-out/lib/lib${PROJECT_NAME}.a: *.zig src/*.zig | $(BUILD_DIR)/generated/pico_base/pico ${EXTRA_LIB_DEPENDENCIES}
	#zig build -freference-trace --verbose-llvm-cpu-features build
	zig build -freference-trace -Dpico-target=${ZIG_TARGET} -Dproject-name=${PROJECT_NAME} build

# Repos
${RUN_DIR}/pico-examples:
	git clone https://github.com/raspberrypi/pico-examples.git

${RUN_DIR}/pico-sdk:
	git clone https://github.com/raspberrypi/pico-sdk.git
	cd $@; \
	git submodule update --init

# CMAKE rules
$(BUILD_DIR)/generated/pico_base/pico: ${RUN_DIR}/CMakeLists.txt | ${RUN_DIR}/pico-sdk $(BUILD_DIR)
	cd $(BUILD_DIR)
	cmake .. -DPICO_SDK_PATH=${RUN_DIR}/pico-sdk -DPICO_PLATFORM:STRING="${PICO_PLATFORM}" -DPICO_BOARD:STRING="${PICO_BOARD}"
	make -j 20 depend

$(BIN): ${RUN_DIR}/zig-out/lib/lib${PROJECT_NAME}.a ${RUN_DIR}/CMakeLists.txt | ${RUN_DIR}/pico-sdk $(BUILD_DIR)
	cd $(BUILD_DIR)
	cmake .. -DPICO_SDK_PATH=${RUN_DIR}/pico-sdk -DPICO_PLATFORM:STRING="${PICO_PLATFORM}" -DPICO_BOARD:STRING="${PICO_BOARD}"
	make -j 20 ${PROJECT_NAME}
	echo
	echo == Done ==
	echo



