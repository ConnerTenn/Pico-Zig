pub const csdk = @cImport({
    // @cInclude("stdio.h");
    @cInclude("pico/stdlib.h");
    @cInclude("hardware/clocks.h");
    @cInclude("hardware/gpio.h");
    @cInclude("hardware/pwm.h");
    @cInclude("hardware/pio.h");
    // @cInclude("pico/time.h");
    @cInclude("hardware/spi.h");
});

// Missing GPIO coprocessor functions
// This is a hack since Zig currently fails to parse the inline ASM for these functions
// and instead treats them as extern functions instead. We must make sure they are implemented

pub export fn gpioc_bit_out_put(pin: c_uint, val: bool) void {
    asm volatile ("mcrr p0, #4, %[pin], %[val], c0"
        :
        : [pin] "r" (pin),
          [val] "r" (val),
    );
}

pub export fn gpioc_bit_oe_put(pin: c_uint, val: bool) void {
    asm volatile ("mcrr p0, #4, %[pin], %[val], c4"
        :
        : [pin] "r" (pin),
          [val] "r" (val),
    );
}
