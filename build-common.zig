const std = @import("std");
const Build = std.Build;

pub const rp2040_target = std.Target.Query{
    .os_tag = .freestanding,
    .cpu_arch = .thumb,
    .cpu_model = .{
        .explicit = &std.Target.arm.cpu.cortex_m0plus,
    },
    .abi = .eabi,
};

pub fn addPicoIncludes(build_config: *Build, compile_step: *Build.Step.Compile) void {
    const includes = [_][]const u8{
        // "./pico-sdk/bazel/include",
        "./pico-sdk/lib/btstack/3rd-party/bluedroid/decoder/include",
        "./pico-sdk/lib/btstack/3rd-party/bluedroid/encoder/include",
        "./pico-sdk/lib/btstack/3rd-party/lc3-google/include",
        "./pico-sdk/lib/btstack/3rd-party/lwip/core/src/include",
        "./pico-sdk/lib/btstack/port/esp32/components/btstack/include",
        "./pico-sdk/lib/btstack/port/samv71-xplained-atwilc3000/ASF/sam/utils/cmsis/samv71/include",
        "./pico-sdk/lib/btstack/test/le_audio/include",
        "./pico-sdk/lib/lwip/contrib/ports/freertos/include",
        "./pico-sdk/lib/lwip/contrib/ports/unix/port/include",
        "./pico-sdk/lib/lwip/contrib/ports/unix/posixlib/include",
        "./pico-sdk/lib/lwip/contrib/ports/win32/include",
        "./pico-sdk/lib/lwip/src/include",
        "./pico-sdk/lib/mbedtls/3rdparty/everest/include",
        "./pico-sdk/lib/mbedtls/include",
        "./pico-sdk/lib/mbedtls/tests/include",
        "./pico-sdk/lib/tinyusb/hw/bsp/espressif/components/led_strip/include",
        "./pico-sdk/lib/tinyusb/hw/bsp/fomu/include",
        "./pico-sdk/lib/tinyusb/hw/mcu/dialog/da1469x/SDK_10.0.8.105/sdk/bsp/include",
        "./pico-sdk/lib/tinyusb/hw/mcu/dialog/da1469x/include",
        "./pico-sdk/lib/tinyusb/hw/mcu/nordic/nrf5x/s140_nrf52_6.1.1_API/include",
        "./pico-sdk/src/boards/include",
        "./pico-sdk/src/common/boot_picobin_headers/include",
        "./pico-sdk/src/common/boot_picoboot_headers/include",
        "./pico-sdk/src/common/boot_uf2_headers/include",
        "./pico-sdk/src/common/hardware_claim/include",
        "./pico-sdk/src/common/pico_base_headers/include",
        "./pico-sdk/src/common/pico_binary_info/include",
        "./pico-sdk/src/common/pico_bit_ops_headers/include",
        "./pico-sdk/src/common/pico_divider_headers/include",
        "./pico-sdk/src/common/pico_stdlib_headers/include",
        "./pico-sdk/src/common/pico_sync/include",
        "./pico-sdk/src/common/pico_time/include",
        "./pico-sdk/src/common/pico_usb_reset_interface_headers/include",
        "./pico-sdk/src/common/pico_util/include",
        "./pico-sdk/src/rp2040/boot_stage2/include",
        "./pico-sdk/src/rp2040/hardware_regs/include",
        "./pico-sdk/src/rp2040/hardware_structs/include",
        "./pico-sdk/src/rp2040/pico_platform/include",
        // "./pico-sdk/src/rp2350/boot_stage2/include",
        // "./pico-sdk/src/rp2350/hardware_regs/include",
        // "./pico-sdk/src/rp2350/hardware_structs/include",
        // "./pico-sdk/src/rp2350/pico_platform/include",
        "./pico-sdk/src/rp2_common/cmsis/include",
        "./pico-sdk/src/rp2_common/hardware_adc/include",
        "./pico-sdk/src/rp2_common/hardware_base/include",
        "./pico-sdk/src/rp2_common/hardware_boot_lock/include",
        "./pico-sdk/src/rp2_common/hardware_clocks/include",
        "./pico-sdk/src/rp2_common/hardware_dcp/include",
        "./pico-sdk/src/rp2_common/hardware_divider/include",
        "./pico-sdk/src/rp2_common/hardware_dma/include",
        "./pico-sdk/src/rp2_common/hardware_exception/include",
        "./pico-sdk/src/rp2_common/hardware_flash/include",
        "./pico-sdk/src/rp2_common/hardware_gpio/include",
        "./pico-sdk/src/rp2_common/hardware_hazard3/include",
        "./pico-sdk/src/rp2_common/hardware_i2c/include",
        "./pico-sdk/src/rp2_common/hardware_interp/include",
        "./pico-sdk/src/rp2_common/hardware_irq/include",
        "./pico-sdk/src/rp2_common/hardware_pio/include",
        "./pico-sdk/src/rp2_common/hardware_pll/include",
        "./pico-sdk/src/rp2_common/hardware_powman/include",
        "./pico-sdk/src/rp2_common/hardware_pwm/include",
        "./pico-sdk/src/rp2_common/hardware_rcp/include",
        "./pico-sdk/src/rp2_common/hardware_resets/include",
        "./pico-sdk/src/rp2_common/hardware_riscv/include",
        "./pico-sdk/src/rp2_common/hardware_riscv_platform_timer/include",
        "./pico-sdk/src/rp2_common/hardware_rtc/include",
        "./pico-sdk/src/rp2_common/hardware_sha256/include",
        "./pico-sdk/src/rp2_common/hardware_spi/include",
        "./pico-sdk/src/rp2_common/hardware_sync/include",
        "./pico-sdk/src/rp2_common/hardware_sync_spin_lock/include",
        "./pico-sdk/src/rp2_common/hardware_ticks/include",
        "./pico-sdk/src/rp2_common/hardware_timer/include",
        "./pico-sdk/src/rp2_common/hardware_uart/include",
        "./pico-sdk/src/rp2_common/hardware_vreg/include",
        "./pico-sdk/src/rp2_common/hardware_watchdog/include",
        "./pico-sdk/src/rp2_common/hardware_xosc/include",
        "./pico-sdk/src/rp2_common/pico_aon_timer/include",
        "./pico-sdk/src/rp2_common/pico_async_context/include",
        "./pico-sdk/src/rp2_common/pico_atomic/include",
        "./pico-sdk/src/rp2_common/pico_bootrom/include",
        "./pico-sdk/src/rp2_common/pico_btstack/include",
        "./pico-sdk/src/rp2_common/pico_clib_interface/include",
        "./pico-sdk/src/rp2_common/pico_cyw43_arch/include",
        "./pico-sdk/src/rp2_common/pico_cyw43_driver/include",
        "./pico-sdk/src/rp2_common/pico_double/include",
        "./pico-sdk/src/rp2_common/pico_fix/rp2040_usb_device_enumeration/include",
        "./pico-sdk/src/rp2_common/pico_flash/include",
        "./pico-sdk/src/rp2_common/pico_float/include",
        "./pico-sdk/src/rp2_common/pico_i2c_slave/include",
        "./pico-sdk/src/rp2_common/pico_int64_ops/include",
        "./pico-sdk/src/rp2_common/pico_lwip/include",
        "./pico-sdk/src/rp2_common/pico_malloc/include",
        "./pico-sdk/src/rp2_common/pico_mbedtls/include",
        "./pico-sdk/src/rp2_common/pico_mem_ops/include",
        "./pico-sdk/src/rp2_common/pico_multicore/include",
        "./pico-sdk/src/rp2_common/pico_platform_compiler/include",
        "./pico-sdk/src/rp2_common/pico_platform_panic/include",
        "./pico-sdk/src/rp2_common/pico_platform_sections/include",
        "./pico-sdk/src/rp2_common/pico_printf/include",
        "./pico-sdk/src/rp2_common/pico_rand/include",
        "./pico-sdk/src/rp2_common/pico_runtime/include",
        "./pico-sdk/src/rp2_common/pico_runtime_init/include",
        "./pico-sdk/src/rp2_common/pico_sha256/include",
        "./pico-sdk/src/rp2_common/pico_stdio/include",
        "./pico-sdk/src/rp2_common/pico_stdio_rtt/include",
        "./pico-sdk/src/rp2_common/pico_stdio_semihosting/include",
        "./pico-sdk/src/rp2_common/pico_stdio_uart/include",
        "./pico-sdk/src/rp2_common/pico_stdio_usb/include",
        "./pico-sdk/src/rp2_common/pico_time_adapter/include",
        "./pico-sdk/src/rp2_common/pico_unique_id/include",
        "./pico-sdk/src/rp2_common/tinyusb/include",
        // "./pico-sdk/test/pico_test/include",
        // "./build/_deps/picotool-src/lib/include",
        // "./build/_deps/picotool-build/lib/mbedtls/include",

        "./build/generated/pico_base",
        "./build",
    };

    inline for (includes) |include| {
        compile_step.addIncludePath(build_config.path(include));
    }
}

pub fn addArmIncludes(build_config: *Build, compile_step: *Build.Step.Compile) void {
    //Run the which command to find the real install location of arm-none-eabi-gcc
    //On Nixos, it is under a hash so it's bad practice to reference it directly
    const cmd_result = std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{ "which", "arm-none-eabi-gcc" }, //: []const []const u8,
        //cwd: ?[]const u8 = null,
        //cwd_dir: ?fs.Dir = null,
        // env_map: ?*const EnvMap = null,
        // max_output_bytes: usize = 50 * 1024,
        // expand_arg0: Arg0Expand = .no_expand,
    }) catch |err| {
        std.debug.panic("Failed to run cmd: {}", .{err});
    };

    std.debug.print("Location of arm-none-eabi-gcc: {s}\n", .{
        cmd_result.stdout,
    });

    //Find the location of the include
    //Note: There's a sneaky newline hiding at the end of stdout
    const arm_gcc_inc_dir = str_replace(build_config.allocator, cmd_result.stdout, "/bin/arm-none-eabi-gcc\n", "/arm-none-eabi/include") catch "";

    const arm_includes = [_][]const u8{
        // "/nix/store/xds2q9qipa6123ycfbak5g5xpf0bxivf-gcc-arm-embedded-13.3.rel1/arm-none-eabi/include",
        arm_gcc_inc_dir,
    };

    inline for (arm_includes) |include| {
        std.debug.print("Adding include [{}]: {s} \n", .{ include.len, include });
        compile_step.addIncludePath(.{
            .cwd_relative = include,
        });
    }
}

pub fn str_replace(allocator: std.mem.Allocator, str: []const u8, find: []const u8, repl: []const u8) ![]const u8 {
    if (find.len == 0 or str.len == 0 or find.len > str.len) {
        return str;
    }

    const index = std.mem.indexOf(u8, str, find) orelse return str;

    const start = str[0..index];
    const end = str[index + find.len ..];

    // Allocate space for the new string.
    var buffer = try allocator.alloc(u8, start.len + repl.len + end.len);

    @memcpy(buffer[0..start.len], start);
    @memcpy(buffer[start.len..(start.len + repl.len)], repl);
    @memcpy(buffer[(start.len + repl.len)..], end);

    return buffer;
}
