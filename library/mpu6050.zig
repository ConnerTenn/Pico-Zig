const std = @import("std");
const math = std.math;
const tau = math.tau;

const pico = @import("../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const hardware = pico.hardware;

pub const MPU6050 = struct {
    const Self = @This();

    pub const baudrate = 400 * 1000;

    i2c: hardware.i2c.I2C,

    pub fn create(i2c: hardware.i2c.I2C) Self {
        return Self{
            .i2c = i2c,
        };
    }
};
