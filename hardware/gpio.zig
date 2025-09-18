const pico = @import("../pico.zig");
const csdk = pico.csdk;
const config = @import("config");

pub const default_led: Pin = Pin.create(csdk.PICO_DEFAULT_LED_PIN);

pub const Pin = enum(u5) {
    const Self = @This();
    _,

    pub const Count = u5;

    pub const Config = struct {
        direction: enum { in, out },
        pull: struct {
            up: bool,
            down: bool,
        } = .{
            .up = false,
            .down = false,
        },
        schmitt_trigger: bool = false,
    };

    pub fn create(pin: anytype) Self {
        return @enumFromInt(pin);
    }

    pub fn init(self: Self, pin_config: Config) void {
        csdk.gpio_init(self.toSdkPin());

        switch (pin_config.direction) {
            .in => csdk.gpio_set_dir(self.toSdkPin(), false),
            .out => csdk.gpio_set_dir(self.toSdkPin(), true),
        }
        csdk.gpio_set_input_hysteresis_enabled(self.toSdkPin(), pin_config.schmitt_trigger);

        csdk.gpio_set_pulls(self.toSdkPin(), pin_config.pull.up, pin_config.pull.down);
    }

    pub inline fn put(self: Self, state: bool) void {
        csdk.gpio_put(self.toSdkPin(), state);
    }

    pub inline fn get(self: Self) bool {
        return csdk.gpio_get(self.toSdkPin());
    }

    pub inline fn toInt(self: Self, T: type) T {
        return @intFromEnum(self);
    }

    pub inline fn toSdkPin(self: Self) c_uint {
        return self.toInt(c_uint);
    }
};

var initialized = false;
fn led_init() void {
    switch (config.board) {
        .pico, .pico2 => default_led.init(Pin.Config{
            .direction = .out,
        }),
        .pico_w, .pico2_w => pico.library.network.init() catch unreachable,
    }
}

pub fn led_put(state: bool) void {
    if (!initialized) {
        led_init();
        initialized = true;
    }
    switch (config.board) {
        .pico, .pico2 => default_led.put(state),
        .pico_w, .pico2_w => csdk.cyw43_arch_gpio_put(
            csdk.CYW43_WL_GPIO_LED_PIN,
            state,
        ),
    }
}
