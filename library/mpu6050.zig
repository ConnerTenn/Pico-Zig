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

    accel_sensitivity: AccelerometerConfig.Sensitivity,
    gyro_sensitivity: GyroscopeConfig.Sensitivity,

    pub fn create(i2c: hardware.i2c.I2C) Self {
        return Self{
            .i2c = i2c,
            .accel_sensitivity = .sel_8g,
            .gyro_sensitivity = .sel_1000deg_sec,
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
        self.setSensitivity(self.accel_sensitivity, self.gyro_sensitivity);
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

        self.writeReg(SignalPathReset{
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

    const RawXYZData = struct {
        x: i16,
        y: i16,
        z: i16,
    };

    const RawImuData = struct {
        accel: RawXYZData,
        gyro: RawXYZData,
    };

    pub fn getRawImuData(self: *Self) RawImuData {
        const accel_data = self.readReg(AccelerometerRegisters);
        const gyro_data = self.readReg(GyroscopeRegisters);

        return RawImuData{
            .accel = accel_data.getXYZ(),
            .gyro = gyro_data.getXYZ(),
        };
    }

    const AccelData = struct {
        x: f32 = 0.0,
        y: f32 = 0.0,
        z: f32 = 0.0,

        fn fromRawXYZ(raw_xyz: RawXYZData, sensitivity: AccelerometerConfig.Sensitivity) AccelData {
            return AccelData{
                .x = sensitivity.rawToGram(raw_xyz.x),
                .y = sensitivity.rawToGram(raw_xyz.y),
                .z = sensitivity.rawToGram(raw_xyz.z),
            };
        }
    };

    const GyroData = struct {
        x: f32 = 0.0,
        y: f32 = 0.0,
        z: f32 = 0.0,

        fn fromRawXYZ(raw_xyz: RawXYZData, sensitivity: GyroscopeConfig.Sensitivity) GyroData {
            return GyroData{
                .x = sensitivity.rawToDegPerSec(raw_xyz.x),
                .y = sensitivity.rawToDegPerSec(raw_xyz.y),
                .z = sensitivity.rawToDegPerSec(raw_xyz.z),
            };
        }
    };

    pub const ImuData = struct {
        accel: AccelData = AccelData{},
        gyro: GyroData = GyroData{},
    };

    pub fn getImuData(self: *Self) ImuData {
        const raw_imu_data = self.getRawImuData();

        return ImuData{
            .accel = AccelData.fromRawXYZ(raw_imu_data.accel, self.accel_sensitivity),
            .gyro = GyroData.fromRawXYZ(raw_imu_data.gyro, self.gyro_sensitivity),
        };
    }

    pub fn setSensitivity(self: *Self, accel_sensitivity: AccelerometerConfig.Sensitivity, gyro_sensitivity: GyroscopeConfig.Sensitivity) void {
        self.accel_sensitivity = accel_sensitivity;
        self.gyro_sensitivity = gyro_sensitivity;

        self.writeReg(AccelerometerConfig{
            .afs_sel = self.accel_sensitivity,
            .x_self_test = 0,
            .y_self_test = 0,
            .z_self_test = 0,
        });

        self.writeReg(GyroscopeConfig{
            .fs_sel = self.gyro_sensitivity,
            .x_self_test = 0,
            .y_self_test = 0,
            .z_self_test = 0,
        });
    }

    fn calibrateAccelerometer(self: *Self) void {
        // The influence of gravity must be subtracted during calibration
        const full_scale_val = self.readReg(AccelerometerConfig).afs_sel;
        const gravity: i16 = @as(i16, 16384) >> @intFromEnum(full_scale_val);

        // Loop to slowly refine the offset calibration value
        for (0..50) |_| {
            const prev_offset = self.readReg(AccelOffset).getOffsets();
            const accel = self.readReg(AccelerometerRegisters).getXYZ();

            // The target acceleration is 0 (we assume the sensor is not moving), therefore it is the 'error'.
            // Subtract half the error each loop
            const offset = RawXYZData{
                .x = prev_offset.x - @divTrunc(accel.x, 2),
                .y = prev_offset.y - @divTrunc(accel.y, 2),
                .z = prev_offset.z - @divTrunc(accel.z - gravity, 2), //Assume gravity is acting through the z axis
            };
            // stdio.print("Offset: {}\n", .{offset});

            self.writeReg(AccelOffset.fromXYZData(offset));
        }
    }

    fn calibrateGyro(self: *Self) void {
        // Loop to slowly refine the offset calibration value
        for (0..50) |_| {
            const prev_offset = self.readReg(GyroOffset).getOffsets();
            const gyro = self.readReg(GyroscopeRegisters).getXYZ();

            // The target acceleration is 0 (we assume the sensor is not moving), therefore it is the 'error'.
            // Subtract half the error each loop
            const offset = RawXYZData{
                .x = prev_offset.x - @divTrunc(gyro.x, 2),
                .y = prev_offset.y - @divTrunc(gyro.y, 2),
                .z = prev_offset.z - @divTrunc(gyro.z, 2),
            };
            // stdio.print("Offset: {}\n", .{offset});

            self.writeReg(GyroOffset.fromXYZData(offset));
        }
    }

    pub fn calibrate(self: *Self) void {
        // stdio.print("Pre Calibrate: {}\n", .{self.readReg(AccelOffset).getOffsets()});
        stdio.print("Calibrate...\n", .{});
        self.calibrateAccelerometer();
        self.calibrateGyro();
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

    pub const AccelOffset = packed struct {
        const address = 0x06;
        offset_x_high: u8,
        offset_x_low: u8,
        offset_y_high: u8,
        offset_y_low: u8,
        offset_z_high: u8,
        offset_z_low: u8,

        pub fn getOffsets(self: AccelOffset) RawXYZData {
            return RawXYZData{
                .x = @bitCast([2]u8{ self.offset_x_low, self.offset_x_high }),
                .y = @bitCast([2]u8{ self.offset_y_low, self.offset_y_high }),
                .z = @bitCast([2]u8{ self.offset_z_low, self.offset_z_high }),
            };
        }

        pub fn fromXYZData(xyz: RawXYZData) AccelOffset {
            const offset_x_bytes: [2]u8 = @bitCast(xyz.x);
            const offset_y_bytes: [2]u8 = @bitCast(xyz.y);
            const offset_z_bytes: [2]u8 = @bitCast(xyz.z);
            return AccelOffset{
                .offset_x_high = offset_x_bytes[1],
                .offset_x_low = offset_x_bytes[0],
                .offset_y_high = offset_y_bytes[1],
                .offset_y_low = offset_y_bytes[0],
                .offset_z_high = offset_z_bytes[1],
                .offset_z_low = offset_z_bytes[0],
            };
        }
    };

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

    pub const GyroOffset = packed struct {
        const address = 0x13;
        offset_x_high: u8,
        offset_x_low: u8,
        offset_y_high: u8,
        offset_y_low: u8,
        offset_z_high: u8,
        offset_z_low: u8,

        pub fn getOffsets(self: GyroOffset) RawXYZData {
            return RawXYZData{
                .x = @bitCast([2]u8{ self.offset_x_low, self.offset_x_high }),
                .y = @bitCast([2]u8{ self.offset_y_low, self.offset_y_high }),
                .z = @bitCast([2]u8{ self.offset_z_low, self.offset_z_high }),
            };
        }

        pub fn fromXYZData(xyz: RawXYZData) GyroOffset {
            const offset_x_bytes: [2]u8 = @bitCast(xyz.x);
            const offset_y_bytes: [2]u8 = @bitCast(xyz.y);
            const offset_z_bytes: [2]u8 = @bitCast(xyz.z);
            return GyroOffset{
                .offset_x_high = offset_x_bytes[1],
                .offset_x_low = offset_x_bytes[0],
                .offset_y_high = offset_y_bytes[1],
                .offset_y_low = offset_y_bytes[0],
                .offset_z_high = offset_z_bytes[1],
                .offset_z_low = offset_z_bytes[0],
            };
        }
    };

    pub const GeneralConfig = packed struct {
        const address = 0x1A;

        digital_filter_config: u3,
        ext_sync_set: u3,
        reserved0: u2 = 0,
    };

    pub const GyroscopeConfig = packed struct {
        const address = 0x1B;

        const Sensitivity = enum(u2) {
            sel_250deg_sec = 0,
            sel_500deg_sec = 1,
            sel_1000deg_sec = 2,
            sel_2000deg_sec = 3,

            fn rawToDegPerSec(self: Sensitivity, raw: i16) f32 {
                //normalized val
                const val: f32 = @as(f32, @floatFromInt(raw)) / @as(f32, @floatFromInt(std.math.maxInt(i16)));
                return switch (self) {
                    .sel_250deg_sec => val * 250.0,
                    .sel_500deg_sec => val * 500.0,
                    .sel_1000deg_sec => val * 1000.0,
                    .sel_2000deg_sec => val * 2000.0,
                };
            }
        };

        reserved0: u3 = 0,
        fs_sel: Sensitivity,
        z_self_test: u1,
        y_self_test: u1,
        x_self_test: u1,
    };

    pub const AccelerometerConfig = packed struct {
        const address = 0x1C;

        const Sensitivity = enum(u2) {
            sel_2g = 0,
            sel_4g = 1,
            sel_8g = 2,
            sel_16g = 3,

            fn rawToGram(self: Sensitivity, raw: i16) f32 {
                //normalized val
                const val: f32 = @as(f32, @floatFromInt(raw)) / @as(f32, @floatFromInt(std.math.maxInt(i16)));
                return switch (self) {
                    .sel_2g => val * 2.0,
                    .sel_4g => val * 4.0,
                    .sel_8g => val * 8.0,
                    .sel_16g => val * 16.0,
                };
            }
        };

        reserved0: u3 = 0,
        afs_sel: Sensitivity,
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

        accel_x_high: u8,
        accel_x_low: u8,
        accel_y_high: u8,
        accel_y_low: u8,
        accel_z_high: u8,
        accel_z_low: u8,

        pub fn getXYZ(self: AccelerometerRegisters) RawXYZData {
            return RawXYZData{
                .x = @bitCast([2]u8{ self.accel_x_low, self.accel_x_high }),
                .y = @bitCast([2]u8{ self.accel_y_low, self.accel_y_high }),
                .z = @bitCast([2]u8{ self.accel_z_low, self.accel_z_high }),
            };
        }
    };

    pub const TemperatureRegisters = packed struct {
        const address = 0x41;

        temp_high: u8,
        temp_low: u8,
    };

    pub const GyroscopeRegisters = packed struct {
        const address = 0x43;

        gyro_x_high: u8,
        gyro_x_low: u8,
        gyro_y_high: u8,
        gyro_y_low: u8,
        gyro_z_high: u8,
        gyro_z_low: u8,

        pub fn getXYZ(self: GyroscopeRegisters) RawXYZData {
            return RawXYZData{
                .x = @bitCast([2]u8{ self.gyro_x_low, self.gyro_x_high }),
                .y = @bitCast([2]u8{ self.gyro_y_low, self.gyro_y_high }),
                .z = @bitCast([2]u8{ self.gyro_z_low, self.gyro_z_high }),
            };
        }
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
