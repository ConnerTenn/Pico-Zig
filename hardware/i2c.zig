const std = @import("std");

const pico = @import("../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const hardware = pico.hardware;
const Pin = hardware.gpio.Pin;

pub const I2C = struct {
    const Self = @This();

    i2c_instance: *csdk.i2c_inst_t,
    baudrate: u32,
    sda_pin: Pin,
    scl_pin: Pin,

    const Instance = enum {
        i2c0,
        i2c1,
    };

    pub fn create(instance: Instance, baudrate: u32, sda_pin: Pin, scl_pin: Pin) Self {
        const i2c_instance = switch (instance) {
            .i2c0 => &csdk.i2c0_inst,
            .i2c1 => &csdk.i2c1_inst,
        };

        return Self{
            .i2c_instance = i2c_instance,
            .baudrate = baudrate,
            .sda_pin = sda_pin,
            .scl_pin = scl_pin,
        };
    }

    pub fn init(self: *Self) void {
        _ = csdk.i2c_init(self.i2c_instance, self.baudrate);

        csdk.gpio_set_function(csdk.PICO_DEFAULT_I2C_SDA_PIN, csdk.GPIO_FUNC_I2C);
        csdk.gpio_set_function(csdk.PICO_DEFAULT_I2C_SCL_PIN, csdk.GPIO_FUNC_I2C);
        csdk.gpio_pull_up(self.sda_pin.toSdkPin());
        csdk.gpio_pull_up(self.scl_pin.toSdkPin());
    }

    const StopCondition = enum {
        nostop,
        stop,
    };

    pub fn readBlocking(self: *Self, i2c_addr: u7, data: *anyopaque, size: usize, stop_condition: StopCondition) void {
        const nostop = switch (stop_condition) {
            .nostop => true,
            .stop => false,
        };
        _ = csdk.i2c_read_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size, nostop);
    }

    pub fn writeBlocking(self: *Self, i2c_addr: u7, data: *const anyopaque, size: usize, stop_condition: StopCondition) void {
        const nostop = switch (stop_condition) {
            .nostop => true,
            .stop => false,
        };
        _ = csdk.i2c_write_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size, nostop);
    }
};
