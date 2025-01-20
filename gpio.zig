const pico = @import("pico.zig");
const csdk = pico.csdk;

pub const default_led_pin: Gpio = Gpio.create(csdk.PICO_DEFAULT_LED_PIN);

pub const Gpio = enum(u5) {
    const Self = @This();
    _,

    pub const Config = struct {
        direction: enum { in, out },
        pull: struct {
            up: bool,
            down: bool,
        } = .{
            .up = false,
            .down = false,
        },
    };

    pub fn create(pin: anytype) Self {
        return @enumFromInt(pin);
    }

    pub fn init(self: Self, config: Config) void {
        csdk.gpio_init(self.toInt(c_uint));
        switch (config.direction) {
            .in => csdk.gpio_set_dir(self.toInt(c_uint), false),
            .out => csdk.gpio_set_dir(self.toInt(c_uint), true),
        }

        csdk.gpio_set_pulls(self.toInt(c_uint), config.pull.up, config.pull.down);
    }

    pub inline fn toInt(self: Self, T: type) T {
        return @intFromEnum(self);
    }

    pub inline fn put(self: Self, state: bool) void {
        csdk.gpio_put(self.toInt(c_uint), state);
    }

    pub inline fn get(self: Self) bool {
        return csdk.gpio_get(self.toInt(c_uint));
    }
};
