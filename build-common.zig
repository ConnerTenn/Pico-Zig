const std = @import("std");
const Build = std.Build;

pub const PicoTargets = enum {
    rp2040,
    rp2350,
};

const CpuFeature = std.Target.Cpu.Feature;
const CpuModel = std.Target.Cpu.Model;
const featureSet = CpuFeature.FeatureSetFns(std.Target.arm.Feature).featureSet;

pub const rp2040_target = std.Target.Query{
    .os_tag = .freestanding,
    .cpu_arch = .thumb,
    .cpu_model = .{
        .explicit = &std.Target.arm.cpu.cortex_m0plus,
    },
    .abi = .eabi,
};

pub const rp2350_target = std.Target.Query{
    .os_tag = .freestanding,
    .cpu_arch = .thumb,
    .cpu_model = .{
        .explicit = &std.Target.arm.cpu.cortex_m33,
    },
    .cpu_features_add = featureSet(&[_]std.Target.arm.Feature{
        .fp_armv8, //Single precision floats
        .dsp, //DSP unit
    }),
    .abi = .eabi,
};

pub fn build(
    build_config: *Build,
    root_source_file: Build.LazyPath,
    default_optimize_mode: std.builtin.OptimizeMode,
) void {
    // == Get Options ==
    const target_arg = build_config.option(
        PicoTargets,
        "pico-target",
        "Select which pico you want to target",
    ) orelse default: {
        std.debug.print("Warning: You must select a pico target. Using default...", .{});
        break :default .rp2040;
    };
    const name_arg = build_config.option(
        []const u8,
        "project-name",
        "Configure the name of the project",
    ) orelse default: {
        std.debug.print("Warning: You must provide a project name. Using default...", .{});
        break :default "default";
    };

    // == Create the static libarary ==
    const options = Build.StaticLibraryOptions{
        .name = name_arg,
        .optimize = build_config.standardOptimizeOption(Build.StandardOptimizeOptionOptions{
            .preferred_optimize_mode = default_optimize_mode,
        }),
        .target = build_config.resolveTargetQuery(switch (target_arg) {
            .rp2040 => rp2040_target,
            .rp2350 => rp2350_target,
        }),
        .root_source_file = root_source_file,
    };

    const lib = build_config.addStaticLibrary(options);

    // == Add the pico module ==
    const pico_module = build_config.addModule("pico", .{
        .root_source_file = build_config.path("Pico-Zig/pico.zig"),
    });

    configureOptions(build_config, pico_module, target_arg);

    lib.root_module.addImport("pico", pico_module);

    // == Add the required includes ==
    addPicoIncludes(build_config, pico_module, target_arg);
    addArmIncludes(build_config, pico_module);

    // == Define the install artifact ==
    const lib_artifact = build_config.addInstallArtifact(lib, .{});

    const build_step = build_config.step("build", "Build the application static library");
    build_step.dependOn(&lib_artifact.step);
}

pub fn configureOptions(build_config: *Build, module: *Build.Module, target: PicoTargets) void {
    const config_options = build_config.addOptions();
    config_options.addOption(PicoTargets, "target", target);
    module.addOptions("config", config_options);
}

pub fn addInclude(build_config: *Build, module: *Build.Module, include_path: []const u8) void {
    std.debug.print("Adding include [{}]: '{s}'\n", .{ include_path.len, include_path });

    if (std.fs.path.isAbsolute(include_path)) {
        module.addIncludePath(std.Build.LazyPath{ .cwd_relative = include_path });
    } else {
        module.addIncludePath(build_config.path(include_path));
    }
}

// features: -32bit,+8msecext,-a76,-aapcs-frame-chain,-aapcs-frame-chain-leaf,-aclass,+acquire-release,-aes,-atomics-32,-avoid-movs-shop,-avoid-partial-cpsr,-bf16,-big-endian-instructions,-cde,-cdecp0,-cdecp1,-cdecp2,-cdecp3,-cdecp4,-cdecp5,-cdecp6,-cdecp7,-cheap-predicable-cpsr,-clrbhb,-crc,-crypto,-d32,+db,-dfb,-disable-postra-scheduler,-dont-widen-vmovs,-dotprod,-dsp,-execute-only,-expand-fp-mlx,-exynos,+fix-cmse-cve-2021-35465,-fix-cortex-a57-aes-1742098,-fp16,-fp16fml,-fp64,-fp-armv8,-fp-armv8d16,-fp-armv8d16sp,-fp-armv8sp,-fpao,-fpregs,-fpregs16,-fpregs64,-fullfp16,-fuse-aes,-fuse-literals,-harden-sls-blr,-harden-sls-nocomdat,-harden-sls-retbr,+v4t,+v5t,+v5te,+v6,+v6k,+v6m,+v6t2,+v7,+v7clrex,-v8,-v8.1a,-v8.1m.main,-v8.2a,-v8.3a,-v8.4a,-v8.5a,-v8.6a,-v8.7a,-v8.8a,-v8.9a,+v8m,+v8m.main,-v9.1a,-v9.2a,-v9.3a,-v9.4a,-v9a,+hwdiv,-hwdiv-arm,-i8mm,-iwmmxt,-iwmmxt2,-lob,-long-calls,+loop-align,-m3,+mclass,-mp,-muxed-units,-mve,-mve1beat,-mve2beat,-mve4beat,-mve.fp,-nacl-trap,-neon,-neon-fpmovs,-neonfp,+no-branch-predictor,-no-bti-at-return-twice,-no-movt,-no-neg-immediates,+noarm,-nonpipelined-vfp,-pacbti,-perfmon,-prefer-ishst,-prefer-vmovsr,-prof-unpr,-r4,-ras,-rclass,-read-tp-tpidrprw,-read-tp-tpidruro,-read-tp-tpidrurw,-reserve-r9,-ret-addr-stack,-sb,-sha2,-slow-fp-brcc,-slow-load-D-subreg,-slow-odd-reg,-slow-vdup32,-slow-vgetlni32,+slowfpvfmx,+slowfpvmlx,-soft-float,-splat-vfp-neon,-strict-align,-swift,+thumb2,+thumb-mode,-trustzone,-use-mipipeliner,+use-misched,-armv4,-armv4t,-armv5t,-armv5te,-armv5tej,-armv6,-armv6j,-armv6k,-armv6kz,-armv6-m,-armv6s-m,-armv6t2,-armv7-a,-armv7e-m,-armv7k,-armv7-m,-armv7-r,-armv7s,-armv7ve,-armv8.1-a,-armv8.1-m.main,-armv8.2-a,-armv8.3-a,-armv8.4-a,-armv8.5-a,-armv8.6-a,-armv8.7-a,-armv8.8-a,-armv8.9-a,-armv8-a,-armv8-m.base,+armv8-m.main,-armv8-r,-armv9.1-a,-armv9.2-a,-armv9.3-a,-armv9.4-a,-v9.5a,-armv9-a,-vfp2,-vfp2sp,-vfp3,-vfp3d16,-vfp3d16sp,-vfp3sp,-vfp4,-vfp4d16,-vfp4d16sp,-vfp4sp,-virtualization,-vldn-align,-vmlx-forwarding,-vmlx-hazards,-wide-stride-vfp,-xscale,-zcz
// features: -32bit,+8msecext,-a76,-aapcs-frame-chain,-aapcs-frame-chain-leaf,-aclass,+acquire-release,-aes,-atomics-32,-avoid-movs-shop,-avoid-partial-cpsr,-bf16,-big-endian-instructions,-cde,-cdecp0,-cdecp1,-cdecp2,-cdecp3,-cdecp4,-cdecp5,-cdecp6,-cdecp7,-cheap-predicable-cpsr,-clrbhb,-crc,-crypto,-d32,+db,-dfb,-disable-postra-scheduler,-dont-widen-vmovs,-dotprod,-dsp,-execute-only,-expand-fp-mlx,-exynos,+fix-cmse-cve-2021-35465,-fix-cortex-a57-aes-1742098,-fp16,-fp16fml,-fp64,-fp-armv8,-fp-armv8d16,-fp-armv8d16sp,-fp-armv8sp,-fpao,-fpregs,-fpregs16,-fpregs64,-fullfp16,-fuse-aes,-fuse-literals,-harden-sls-blr,-harden-sls-nocomdat,-harden-sls-retbr,+v4t,+v5t,+v5te,+v6,+v6k,+v6m,+v6t2,+v7,+v7clrex,-v8,-v8.1a,-v8.1m.main,-v8.2a,-v8.3a,-v8.4a,-v8.5a,-v8.6a,-v8.7a,-v8.8a,-v8.9a,+v8m,+v8m.main,-v9.1a,-v9.2a,-v9.3a,-v9.4a,-v9a,+hwdiv,-hwdiv-arm,-i8mm,-iwmmxt,-iwmmxt2,-lob,-long-calls,+loop-align,-m3,+mclass,-mp,-muxed-units,-mve,-mve1beat,-mve2beat,-mve4beat,-mve.fp,-nacl-trap,-neon,-neon-fpmovs,-neonfp,+no-branch-predictor,-no-bti-at-return-twice,-no-movt,-no-neg-immediates,+noarm,-nonpipelined-vfp,-pacbti,-perfmon,-prefer-ishst,-prefer-vmovsr,-prof-unpr,-r4,-ras,-rclass,-read-tp-tpidrprw,-read-tp-tpidruro,-read-tp-tpidrurw,-reserve-r9,-ret-addr-stack,-sb,-sha2,-slow-fp-brcc,-slow-load-D-subreg,-slow-odd-reg,-slow-vdup32,-slow-vgetlni32,+slowfpvfmx,+slowfpvmlx,-soft-float,-splat-vfp-neon,-strict-align,-swift,+thumb2,+thumb-mode,-trustzone,-use-mipipeliner,+use-misched,-armv4,-armv4t,-armv5t,-armv5te,-armv5tej,-armv6,-armv6j,-armv6k,-armv6kz,-armv6-m,-armv6s-m,-armv6t2,-armv7-a,-armv7e-m,-armv7k,-armv7-m,-armv7-r,-armv7s,-armv7ve,-armv8.1-a,-armv8.1-m.main,-armv8.2-a,-armv8.3-a,-armv8.4-a,-armv8.5-a,-armv8.6-a,-armv8.7-a,-armv8.8-a,-armv8.9-a,-armv8-a,-armv8-m.base,+armv8-m.main,-armv8-r,-armv9.1-a,-armv9.2-a,-armv9.3-a,-armv9.4-a,-v9.5a,-armv9-a,-vfp2,-vfp2sp,-vfp3,-vfp3d16,-vfp3d16sp,-vfp3sp,-vfp4,-vfp4d16,-vfp4d16sp,-vfp4sp,-virtualization,-vldn-align,-vmlx-forwarding,-vmlx-hazards,-wide-stride-vfp,-xscale,-zcz

pub fn addPicoIncludes(build_config: *Build, module: *Build.Module, target: PicoTargets) void {
    const common_includes = [_][]const u8{
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
        "./pico-sdk/src/common/pico_stdlib_headers/include/",
        "./pico-sdk/src/common/pico_sync/include",
        "./pico-sdk/src/common/pico_time/include",
        "./pico-sdk/src/common/pico_usb_reset_interface_headers/include",
        "./pico-sdk/src/common/pico_util/include",
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
        "./pico-sdk/src/rp2_common/pico_platform_common/include",
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

    const target_includes = switch (target) {
        .rp2040 => [_][]const u8{
            "./pico-sdk/src/rp2040/boot_stage2/include",
            "./pico-sdk/src/rp2040/hardware_regs/include",
            "./pico-sdk/src/rp2040/hardware_structs/include",
            "./pico-sdk/src/rp2040/pico_platform/include",
        },
        .rp2350 => [_][]const u8{
            "./pico-sdk/src/rp2350/boot_stage2/include",
            "./pico-sdk/src/rp2350/hardware_regs/include",
            "./pico-sdk/src/rp2350/hardware_structs/include",
            "./pico-sdk/src/rp2350/pico_platform/include",
        },
    };

    const includes = common_includes ++ target_includes;

    inline for (includes) |include| {
        addInclude(build_config, module, include);
    }
}

pub fn addArmIncludes(build_config: *Build, module: *Build.Module) void {
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
        addInclude(build_config, module, include);
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
