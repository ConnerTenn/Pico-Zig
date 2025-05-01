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
    pub const i2c_addr = 0x68;

    i2c: hardware.i2c.I2C,

    pub fn create(i2c: hardware.i2c.I2C) Self {
        return Self{
            .i2c = i2c,
        };
    }

    pub fn init(self: *Self) void {
        self.i2c.init();

        self.reset();
    }

    pub fn reset(self: *Self) void {
        self.writeReg(PowerManagement1{
            .clk_sel = 0,
            .temp_disable = 0,
            .cycle = 0,
            .sleep = 0,
            .device_reset = 1,
        });
        csdk.sleep_ms(100); // Allow device to reset and stabilize

        self.writeReg(PowerManagement1{
            .clk_sel = 0,
            .temp_disable = 0,
            .cycle = 0,
            .sleep = 0,
            .device_reset = 0,
        });
        csdk.sleep_ms(10); // Allow stabilization after waking up
    }

    const RawImuData = struct {
        const address = 0x3B;

        accel_x: i16,
        accel_y: i16,
        accel_z: i16,
        gyro_x: i16,
        gyro_y: i16,
        gyro_z: i16,

        fn create(accel_data: AccelerometerRegisters, gyro_data: GyroscopeRegisters) RawImuData {
            return RawImuData{
                .accel_x = (@as(i16, @intCast(accel_data.accel_x_high)) << 8) | (accel_data.accel_x_low),
                .accel_y = (@as(i16, @intCast(accel_data.accel_y_high)) << 8) | (accel_data.accel_y_low),
                .accel_z = (@as(i16, @intCast(accel_data.accel_z_high)) << 8) | (accel_data.accel_z_low),

                .gyro_x = (@as(i16, @intCast(gyro_data.gyro_x_high)) << 8) | (gyro_data.gyro_x_low),
                .gyro_y = (@as(i16, @intCast(gyro_data.gyro_y_high)) << 8) | (gyro_data.gyro_y_low),
                .gyro_z = (@as(i16, @intCast(gyro_data.gyro_z_high)) << 8) | (gyro_data.gyro_z_low),
            };
        }
    };

    pub fn getRawImuData(self: *Self) RawImuData {
        const accel_data = self.readReg(AccelerometerRegisters);
        const gyro_data = self.readReg(GyroscopeRegisters);

        return RawImuData.create(accel_data, gyro_data);
    }

    pub fn readReg(self: *Self, Reg: type) Reg {
        const addr: usize = Reg.address;
        self.i2c.writeBlocking(i2c_addr, @ptrCast(&addr), 1, .nostop);

        var reg: Reg = undefined;
        self.i2c.readBlocking(i2c_addr, @ptrCast(&reg), @sizeOf(Reg), .stop);
        return reg;
    }

    pub fn writeReg(self: *Self, reg: anytype) void {
        const Reg = @TypeOf(reg);
        const addr: usize = Reg.address;
        self.i2c.writeBlocking(i2c_addr, @ptrCast(&addr), 1, .nostop);
        self.i2c.writeBlocking(i2c_addr, @ptrCast(&reg), @sizeOf(Reg), .stop);
    }

    const AccelerometerRegisters = packed struct {
        const address = 0x3B;

        accel_x_high: i8,
        accel_x_low: i8,
        accel_y_high: i8,
        accel_y_low: i8,
        accel_z_high: i8,
        accel_z_low: i8,
        gyro_x: i16,
        gyro_y: i16,
        gyro_z: i16,
    };

    const GyroscopeRegisters = packed struct {
        const address = 0x43;

        gyro_x_high: i8,
        gyro_x_low: i8,
        gyro_y_high: i8,
        gyro_y_low: i8,
        gyro_z_high: i8,
        gyro_z_low: i8,
    };

    const PowerManagement1 = packed struct {
        const address = 0x68;

        clk_sel: u3,
        temp_disable: u1,
        _: u1 = 0,
        cycle: u1,
        sleep: u1,
        device_reset: u1,
    };
};
