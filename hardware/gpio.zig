const pico = @import("../pico.zig");
const csdk = pico.csdk;

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
    };

    pub fn create(pin: anytype) Self {
        return @enumFromInt(pin);
    }

    pub fn init(self: Self, config: Config) void {
        csdk.gpio_init(self.toSdkPin());
        switch (config.direction) {
            .in => csdk.gpio_set_dir(self.toSdkPin(), false),
            .out => csdk.gpio_set_dir(self.toSdkPin(), true),
        }

        csdk.gpio_set_pulls(self.toSdkPin(), config.pull.up, config.pull.down);
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
