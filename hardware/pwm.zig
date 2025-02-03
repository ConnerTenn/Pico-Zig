const std = @import("std");
const math = std.math;

const pico = @import("../pico.zig");
const csdk = pico.csdk;

const hardware = pico.hardware;

pub const PwmSlice = struct {
    const Self = @This();
    pub const SliceNum = u8;

    slice_num: SliceNum,
    counter_wrap: u16,

    pub fn create(slice_num: SliceNum, counter_wrap: ?u16) Self {
        const self = Self{
            .slice_num = slice_num,
            .counter_wrap = counter_wrap orelse math.maxInt(u16),
        };

        return self;
    }

    pub fn createFromGpio(gpio_num: hardware.gpio.Pin, counter_wrap: ?u16) Self {
        const slice_num = gpioToSliceNum(gpio_num);
        return create(slice_num, counter_wrap);
    }

    pub inline fn gpioToSliceNum(gpio_num: hardware.gpio.Pin) SliceNum {
        return csdk.pwm_gpio_to_slice_num(gpio_num);
    }

    pub fn init(self: Self) void {
        var config = csdk.pwm_get_default_config();

        csdk.pwm_config_set_output_polarity(&config, true, false);
        csdk.pwm_config_set_clkdiv_int(&config, 1);
        csdk.pwm_config_set_wrap(&config, self.counter_wrap);
        // csdk.pwm_config_set_phase_correct(&config, true);

        csdk.pwm_init(self.slice_num, &config, false);

        csdk.pwm_set_counter(self.slice_num, 0);
    }

    pub fn disable(self: Self) void {
        csdk.pwm_set_enabled(self.slice_num, false);
    }

    pub inline fn setLevel(self: Self, level: u16) void {
        csdk.pwm_set_both_levels(self.slice_num, level, level);
    }
};

pub fn enableSlices(slices: []const PwmSlice) void {
    var mask: u32 = 0;

    for (slices) |slice| {
        mask = mask | (@as(u32, 1) << @truncate(slice.slice_num));
    }

    csdk.pwm_set_mask_enabled(mask);
}
