// pub const pico = @import("pico.zig");
const config = @import("config");

pub const csdk = @cImport({
    switch (config.target) {
        .rp2040 => {
            @cDefine("CFG_TUSB_DEBUG", "0");
            @cDefine("CFG_TUSB_MCU", "OPT_MCU_RP2040");
            @cDefine("CFG_TUSB_OS", "OPT_OS_PICO");
            @cDefine("LIB_BOOT_STAGE2_HEADERS", "1");
            @cDefine("LIB_PICO_ATOMIC", "1");
            @cDefine("LIB_PICO_BIT_OPS", "1");
            @cDefine("LIB_PICO_BIT_OPS_PICO", "1");
            @cDefine("LIB_PICO_CLIB_INTERFACE", "1");
            @cDefine("LIB_PICO_CRT0", "1");
            @cDefine("LIB_PICO_CXX_OPTIONS", "1");
            @cDefine("LIB_PICO_DIVIDER", "1");
            @cDefine("LIB_PICO_DIVIDER_HARDWARE", "1");
            @cDefine("LIB_PICO_DOUBLE", "1");
            @cDefine("LIB_PICO_DOUBLE_PICO", "1");
            @cDefine("LIB_PICO_FIX_RP2040_USB_DEVICE_ENUMERATION", "1");
            @cDefine("LIB_PICO_FLASH", "1");
            @cDefine("LIB_PICO_FLOAT", "1");
            @cDefine("LIB_PICO_FLOAT_PICO", "1");
            @cDefine("LIB_PICO_INT64_OPS", "1");
            @cDefine("LIB_PICO_INT64_OPS_PICO", "1");
            @cDefine("LIB_PICO_MALLOC", "1");
            @cDefine("LIB_PICO_MEM_OPS", "1");
            @cDefine("LIB_PICO_MEM_OPS_PICO", "1");
            @cDefine("LIB_PICO_NEWLIB_INTERFACE", "1");
            @cDefine("LIB_PICO_PLATFORM", "1");
            @cDefine("LIB_PICO_PLATFORM_COMPILER", "1");
            @cDefine("LIB_PICO_PLATFORM_PANIC", "1");
            @cDefine("LIB_PICO_PLATFORM_SECTIONS", "1");
            @cDefine("LIB_PICO_PRINTF", "1");
            @cDefine("LIB_PICO_PRINTF_PICO", "1");
            @cDefine("LIB_PICO_RUNTIME", "1");
            @cDefine("LIB_PICO_RUNTIME_INIT", "1");
            @cDefine("LIB_PICO_STANDARD_BINARY_INFO", "1");
            @cDefine("LIB_PICO_STANDARD_LINK", "1");
            @cDefine("LIB_PICO_STDIO", "1");
            @cDefine("LIB_PICO_STDIO_USB", "1");
            @cDefine("LIB_PICO_STDLIB", "1");
            @cDefine("LIB_PICO_SYNC", "1");
            @cDefine("LIB_PICO_SYNC_CRITICAL_SECTION", "1");
            @cDefine("LIB_PICO_SYNC_MUTEX", "1");
            @cDefine("LIB_PICO_SYNC_SEM", "1");
            @cDefine("LIB_PICO_TIME", "1");
            @cDefine("LIB_PICO_TIME_ADAPTER", "1");
            @cDefine("LIB_PICO_UNIQUE_ID", "1");
            @cDefine("LIB_PICO_UTIL", "1");
            @cDefine("PICO_32BIT", "1");
            @cDefine("PICO_BOARD", "pico");
            @cDefine("PICO_BUILD", "1");
            @cDefine("PICO_CMAKE_BUILD_TYPE", "Release");
            @cDefine("PICO_COPY_TO_RAM", "0");
            @cDefine("PICO_CXX_ENABLE_EXCEPTIONS", "0");
            @cDefine("PICO_NO_FLASH", "0");
            @cDefine("PICO_NO_HARDWARE", "0");
            @cDefine("PICO_ON_DEVICE", "1");
            @cDefine("PICO_RP2040", "1");
            @cDefine("PICO_RP2040_USB_DEVICE_UFRAME_FIX", "1");
            @cDefine("PICO_TARGET_NAME", "csdk");
            @cDefine("PICO_USE_BLOCKED_RAM", "0");
        },

        .rp2350 => {
            @cDefine("CFG_TUSB_DEBUG", "0");
            @cDefine("CFG_TUSB_MCU", "OPT_MCU_RP2040");
            @cDefine("CFG_TUSB_OS", "OPT_OS_PICO");
            @cDefine("LIB_BOOT_STAGE2_HEADERS", "1");
            @cDefine("LIB_PICO_ATOMIC", "1");
            @cDefine("LIB_PICO_BIT_OPS", "1");
            @cDefine("LIB_PICO_BIT_OPS_PICO", "1");
            @cDefine("LIB_PICO_CLIB_INTERFACE", "1");
            @cDefine("LIB_PICO_CRT0", "1");
            @cDefine("LIB_PICO_CXX_OPTIONS", "1");
            @cDefine("LIB_PICO_DIVIDER", "1");
            @cDefine("LIB_PICO_DIVIDER_COMPILER", "1");
            @cDefine("LIB_PICO_DOUBLE", "1");
            @cDefine("LIB_PICO_DOUBLE_PICO", "1");
            @cDefine("LIB_PICO_FIX_RP2040_USB_DEVICE_ENUMERATION", "1");
            @cDefine("LIB_PICO_FLASH", "1");
            @cDefine("LIB_PICO_FLOAT", "1");
            @cDefine("LIB_PICO_FLOAT_PICO", "1");
            @cDefine("LIB_PICO_FLOAT_PICO_VFP", "1");
            @cDefine("LIB_PICO_INT64_OPS", "1");
            @cDefine("LIB_PICO_INT64_OPS_COMPILER", "1");
            @cDefine("LIB_PICO_MALLOC", "1");
            @cDefine("LIB_PICO_MEM_OPS", "1");
            @cDefine("LIB_PICO_MEM_OPS_COMPILER", "1");
            @cDefine("LIB_PICO_NEWLIB_INTERFACE", "1");
            @cDefine("LIB_PICO_PLATFORM", "1");
            @cDefine("LIB_PICO_PLATFORM_COMPILER", "1");
            @cDefine("LIB_PICO_PLATFORM_PANIC", "1");
            @cDefine("LIB_PICO_PLATFORM_SECTIONS", "1");
            @cDefine("LIB_PICO_PRINTF", "1");
            @cDefine("LIB_PICO_PRINTF_PICO", "1");
            @cDefine("LIB_PICO_RUNTIME", "1");
            @cDefine("LIB_PICO_RUNTIME_INIT", "1");
            @cDefine("LIB_PICO_STANDARD_BINARY_INFO", "1");
            @cDefine("LIB_PICO_STANDARD_LINK", "1");
            @cDefine("LIB_PICO_STDIO", "1");
            @cDefine("LIB_PICO_STDIO_USB", "1");
            @cDefine("LIB_PICO_STDLIB", "1");
            @cDefine("LIB_PICO_SYNC", "1");
            @cDefine("LIB_PICO_SYNC_CRITICAL_SECTION", "1");
            @cDefine("LIB_PICO_SYNC_MUTEX", "1");
            @cDefine("LIB_PICO_SYNC_SEM", "1");
            @cDefine("LIB_PICO_TIME", "1");
            @cDefine("LIB_PICO_TIME_ADAPTER", "1");
            @cDefine("LIB_PICO_UNIQUE_ID", "1");
            @cDefine("LIB_PICO_UTIL", "1");
            @cDefine("PICO_32BIT", "1");
            @cDefine("PICO_BOARD", "pico2");
            @cDefine("PICO_BUILD", "1");
            @cDefine("PICO_CMAKE_BUILD_TYPE", "Release");
            @cDefine("PICO_COPY_TO_RAM", "0");
            @cDefine("PICO_CXX_ENABLE_EXCEPTIONS", "0");
            @cDefine("PICO_NO_FLASH", "0");
            @cDefine("PICO_NO_HARDWARE", "0");
            @cDefine("PICO_ON_DEVICE", "1");
            @cDefine("PICO_RP2040_USB_DEVICE_UFRAME_FIX", "1");
            @cDefine("PICO_RP2350", "1");
            @cDefine("PICO_TARGET_NAME", "csdk");
            @cDefine("PICO_USE_BLOCKED_RAM", "0");
        },
    }

    // @cInclude("stdio.h");
    @cInclude("pico/stdlib.h");
    // @cInclude("hardware/pll.h");
    @cInclude("hardware/clocks.h");
    @cInclude("hardware/gpio.h");
    @cInclude("hardware/pwm.h");
    @cInclude("hardware/pio.h");
    @cInclude("hardware/spi.h");
    @cInclude("hardware/i2c.h");
    @cInclude("hardware/dma.h");
    // @cInclude("pico/time.h");
});

// Missing GPIO coprocessor functions
// This is a hack since Zig currently fails to parse the inline ASM for these functions
// and instead treats them as extern functions instead. We must make sure they are implemented

pub export fn gpioc_bit_out_put(pin: c_uint, val: bool) void {
    if (config.target == .rp2350) {
        asm volatile ("mcrr p0, #4, %[pin], %[val], c0"
            :
            : [pin] "r" (pin),
              [val] "r" (val),
        );
    }
}

pub export fn gpioc_bit_oe_put(pin: c_uint, val: bool) void {
    if (config.target == .rp2350) {
        asm volatile ("mcrr p0, #4, %[pin], %[val], c4"
            :
            : [pin] "r" (pin),
              [val] "r" (val),
        );
    }
}

pub export fn __compiler_memory_barrier() void {
    asm volatile ("" ::: "memory");
}
