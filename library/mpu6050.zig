const std = @import("std");
const math = std.math;
const tau = math.tau;

const pico = @import("../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const hardware = pico.hardware;

pub const MPU6050 = struct {
    const Self = @This();

    // pub const baudrate = 400 * 1000;
    pub const baudrate = 40 * 1000;
    pub const i2c_addr = 0x68;

    i2c: hardware.i2c.I2C,

    pub fn create(i2c: hardware.i2c.I2C) Self {
        return Self{
            .i2c = i2c,
        };
    }

    pub fn init(self: *Self) void {
        // stdio.print("Init MPU6050\n", .{});

        // stdio.print("Init i2c\n", .{});
        self.i2c.init();

        stdio.print("WhoAmI: 0x{x}\n", .{self.readReg(WhoAmI).byte});

        self.reset();

        // self.writeReg(pico.library.mpu6050.MPU6050.InterruptConfig{
        //     .data_ready_enable = 1,
        //     .i2c_master_int_enable = 0,
        //     .fifo_overflow_enable = 0,
        //     .motion_enable = 0,
        // });
    }

    pub fn reset(self: *Self) void {
        stdio.print("Put into reset\n", .{});
        self.writeReg(PowerManagement1{
            .clk_sel = .internal_8MHz,
            .temp_disable = 0,
            .cycle = 0,
            .sleep = 0,
            .device_reset = 1,
        });
        csdk.sleep_ms(100); // Allow device to reset and stabilize

        self.writeReg(pico.library.mpu6050.MPU6050.SignalPathReset{
            .temp_reset = 1,
            .accel_reset = 1,
            .gyro_reset = 1,
        });

        stdio.print("Take out of sleep\n", .{});
        self.writeReg(PowerManagement1{
            .clk_sel = .pll_x_gyro,
            .temp_disable = 0,
            .cycle = 0,
            .sleep = 0,
            .device_reset = 0,
        });

        csdk.sleep_ms(100); // Allow stabilization after waking up
    }

    const RawImuData = struct {
        accel_x: i16,
        accel_y: i16,
        accel_z: i16,
        gyro_x: i16,
        gyro_y: i16,
        gyro_z: i16,

        fn create(accel_data: AccelerometerRegisters, gyro_data: GyroscopeRegisters) RawImuData {
            return RawImuData{
                .accel_x = @bitCast([2]i8{ accel_data.accel_x_low, accel_data.accel_x_high }),
                .accel_y = @bitCast([2]i8{ accel_data.accel_y_low, accel_data.accel_y_high }),
                .accel_z = @bitCast([2]i8{ accel_data.accel_z_low, accel_data.accel_z_high }),

                .gyro_x = @bitCast([2]i8{ gyro_data.gyro_x_low, gyro_data.gyro_x_high }),
                .gyro_y = @bitCast([2]i8{ gyro_data.gyro_y_low, gyro_data.gyro_y_high }),
                .gyro_z = @bitCast([2]i8{ gyro_data.gyro_z_low, gyro_data.gyro_z_high }),
            };
        }
    };

    pub fn getRawImuData(self: *Self) RawImuData {
        const accel_data = self.readReg(AccelerometerRegisters);
        const gyro_data = self.readReg(GyroscopeRegisters);

        return RawImuData.create(accel_data, gyro_data);
    }

    pub fn readReg(self: *Self, Reg: type) Reg {
        const addr: u8 = Reg.address;
        self.i2c.writeBlocking(i2c_addr, @ptrCast(&addr), 1, .restart);

        var reg: Reg = undefined;
        self.i2c.readBlocking(i2c_addr, @ptrCast(&reg), @bitSizeOf(Reg) / 8, .stop);
        return reg;
    }

    pub fn writeReg(self: *Self, reg: anytype) void {
        const Reg = @TypeOf(reg);
        const addr: u8 = Reg.address;
        self.i2c.writeBlocking(i2c_addr, @ptrCast(&addr), 1, .burst);
        self.i2c.writeBlocking(i2c_addr, @ptrCast(&reg), @bitSizeOf(Reg) / 8, .stop);
    }

    pub const SelfTestX = packed struct {
        const address = 0x0D;

        gyroscope_test: u5,
        accelerometer_test_upper: u3,
    };

    pub const SelfTestY = packed struct {
        const address = 0x0E;

        gyroscope_test: u5,
        accelerometer_test_upper: u3,
    };

    pub const SelfTestZ = packed struct {
        const address = 0x0F;

        gyroscope_test: u5,
        accelerometer_test_upper: u3,
    };

    pub const SelfTestExtra = packed struct {
        const address = 0x10;

        accelerometer_z_lower: u2,
        accelerometer_y_lower: u2,
        accelerometer_x_lower: u2,
        reserved0: u2 = 0,
    };

    pub const GeneralConfig = packed struct {
        const address = 0x1A;

        digital_filter_config: u3,
        ext_sync_set: u3,
        reserved0: u2 = 0,
    };

    pub const GyroscopeConfig = packed struct {
        const address = 0x1B;

        reserved0: u3 = 0,
        fs_sel: enum(u2) {
            sel_250deg_sec = 0,
            sel_500deg_sec = 1,
            sel_1000deg_sec = 2,
            sel_2000deg_sec = 3,
        },
        z_self_test: u1,
        y_self_test: u1,
        x_self_test: u1,
    };

    pub const AccelerometerConfig = packed struct {
        const address = 0x1C;

        reserved0: u3 = 0,
        afs_sel: enum(u2) {
            sel_2g = 0,
            sel_4g = 1,
            sel_8g = 2,
            sel_16g = 3,
        },
        z_self_test: u1,
        y_self_test: u1,
        x_self_test: u1,
    };

    pub const InterruptConfig = packed struct {
        const address = 0x38;

        data_ready_enable: u1,
        reserved0: u2 = 0,
        i2c_master_int_enable: u1,
        fifo_overflow_enable: u1,
        reserved1: u1 = 0,
        motion_enable: u1,
        reserved2: u1 = 0,
    };

    pub const InterruptStatus = packed struct {
        const address = 0x3A;

        data_ready_int: u1,
        reserved0: u2 = 0,
        i2c_master_int: u1,
        fifo_overflow_int: u1,
        reserved1: u1 = 0,
        motion_int: u1,
        reserved2: u1 = 0,
    };

    pub const AccelerometerRegisters = packed struct {
        const address = 0x3B;

        accel_x_high: i8,
        accel_x_low: i8,
        accel_y_high: i8,
        accel_y_low: i8,
        accel_z_high: i8,
        accel_z_low: i8,
    };

    pub const TemperatureRegisters = packed struct {
        const address = 0x41;

        temp_high: u8,
        temp_low: u8,
    };

    pub const GyroscopeRegisters = packed struct {
        const address = 0x43;

        gyro_x_high: i8,
        gyro_x_low: i8,
        gyro_y_high: i8,
        gyro_y_low: i8,
        gyro_z_high: i8,
        gyro_z_low: i8,
    };

    pub const SignalPathReset = packed struct {
        const address = 0x68;

        temp_reset: u1,
        accel_reset: u1,
        gyro_reset: u1,
        reserved0: u5 = 0,
    };

    pub const PowerManagement1 = packed struct {
        const address = 0x6B;

        clk_sel: enum(u3) {
            internal_8MHz,
            pll_x_gyro,
            pll_y_gyro,
            pll_z_gyro,
            pll_external_32_768kHz,
            pll_external_19_2kHz,
            reserved,
            stopped_clock,
        },
        temp_disable: u1,
        reserved0: u1 = 0,
        cycle: u1,
        sleep: u1,
        device_reset: u1,
    };

    pub const WhoAmI = packed union {
        const address = 0x75;

        bits: packed struct {
            reserved0: u1 = 0,
            who_am_i: u6,
            reserved1: u1 = 0,
        },
        byte: u8,
    };
};

const expect = std.testing.expect;

test "AccelerometerRegisters" {
    try expect(@bitSizeOf(MPU6050.AccelerometerRegisters) == 6 * 8);
    const size = @bitSizeOf(MPU6050.AccelerometerRegisters) / 8;

    const accel_data = MPU6050.AccelerometerRegisters{
        .accel_x_high = 1,
        .accel_x_low = 2,
        .accel_y_high = 3,
        .accel_y_low = 4,
        .accel_z_high = 5,
        .accel_z_low = 6,
    };
    const data: []const u8 = @as([*]const u8, @ptrCast(&accel_data))[0..size];

    try expect(data[0] == 1);
    try expect(data[1] == 2);
    try expect(data[2] == 3);
    try expect(data[3] == 4);
    try expect(data[4] == 5);
    try expect(data[5] == 6);

    {
        const low: i8 = 1;
        const high: i8 = 1;
        const combined: i16 = @bitCast([2]i8{ low, high });
        try expect(combined == 0x0101);
    }

    {
        const low: i8 = -1;
        const high: i8 = 1;
        const combined: i16 = @bitCast([2]i8{ low, high });
        // std.debug.print("Result: {X}\n", .{combined});
        try expect(combined == 0x01FF);
    }

    {
        const low: i8 = 1;
        const high: i8 = -1;
        const combined: i16 = @bitCast([2]i8{ low, high });
        // std.debug.print("Result: {X}\n", .{combined});
        try expect(combined == @as(i16, @bitCast(@as(u16, 0xFF01))));
    }
}
