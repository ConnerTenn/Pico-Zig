const std = @import("std");

pub const csdk = @import("csdk.zig").csdk;
pub const stdio = @import("stdio.zig");
pub const math = @import("math.zig");
pub const pwm = @import("pwm.zig");

const GpioNum = u8;

pub const GPIO_IN = false;
pub const GPIO_OUT = true;

pub const GPIO_HIGH = true;
pub const GPIO_LOW = false;

pub const LED_PIN = csdk.PICO_DEFAULT_LED_PIN;
