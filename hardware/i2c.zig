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

    pub fn init(self: Self) void {
        // stdio.print("Init I2C\n", .{});
        const actual_baudrate = csdk.i2c_init(self.i2c_instance, self.baudrate);
        _ = actual_baudrate; // autofix
        // stdio.print("Target Baudrate:{}, Actual Baudrate:{}\n", .{ self.baudrate, actual_baudrate });

        csdk.gpio_set_function(self.sda_pin.toSdkPin(), csdk.GPIO_FUNC_I2C);
        csdk.gpio_set_function(self.scl_pin.toSdkPin(), csdk.GPIO_FUNC_I2C);
        csdk.gpio_pull_up(self.sda_pin.toSdkPin());
        csdk.gpio_pull_up(self.scl_pin.toSdkPin());
    }

    const StopCondition = enum {
        stop, //Issue a stop
        restart, //Do not issue a stop, but will cause a re-start to be issued
        burst, //Will transmit as a burst
    };

    pub fn readBlocking(self: Self, i2c_addr: u7, data: *anyopaque, size: usize, stop_condition: StopCondition) void {
        switch (stop_condition) {
            .stop => {
                _ = csdk.i2c_read_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size, false);
            },
            .restart => {
                _ = csdk.i2c_read_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size, true);
            },
            .burst => {
                _ = csdk.i2c_read_burst_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size);
            },
        }
    }

    pub fn writeBlocking(self: Self, i2c_addr: u7, data: *const anyopaque, size: usize, stop_condition: StopCondition) void {
        switch (stop_condition) {
            .stop => {
                _ = csdk.i2c_write_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size, false);
            },
            .restart => {
                _ = csdk.i2c_write_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size, true);
            },
            .burst => {
                _ = csdk.i2c_write_burst_blocking(self.i2c_instance, @intCast(i2c_addr), @ptrCast(data), size);
            },
        }
    }
};
