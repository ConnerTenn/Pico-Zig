const std = @import("std");
const math = std.math;
const tau = math.tau;

const pico = @import("pico");
const csdk = pico.csdk;
const stdio = pico.stdio;
const hardware = pico.hardware;

pub const Sensor = struct {
    const Self = @This();
    ctx: *anyopaque,
    getAngleFn: *const fn (ctx: *anyopaque) f32,

    pub fn getAngle(self: Self) f32 {
        return self.getAngleFn(self.ctx);
    }
};

pub const LIS3MDL = struct {
    const Self = @This();

    const RawData = struct {
        x_axis: i16,
        y_axis: i16,
        // z_axis: i16,

        pub fn format(self: RawData, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("X:", .{});
            try stdio.printBarGraph(
                15,
                self.xF32(),
                writer,
            );
            try writer.print("  Y:", .{});
            try stdio.printBarGraph(
                15,
                self.yF32(),
                writer,
            );
            // try writer.print("  Z:", .{});
            // try bldc.printBarGraph(
            //     15,
            //     @as(f32, @floatFromInt(self.z_axis)) / @as(f32, @floatFromInt(std.math.maxInt(i16))),
            //     writer,
            // );
        }

        pub inline fn xF32(self: RawData) f32 {
            if (self.x_axis == std.math.maxInt(i16) or self.x_axis == std.math.minInt(i16)) {
                stdio.print("WARNING: x axis maxed out range\n", .{});
            }

            return @as(f32, @floatFromInt(self.x_axis)) / @as(f32, @floatFromInt(std.math.maxInt(i16)));
        }

        pub inline fn yF32(self: RawData) f32 {
            if (self.y_axis == std.math.maxInt(i16) or self.y_axis == std.math.minInt(i16)) {
                stdio.print("WARNING: y axis maxed out range\n", .{});
            }

            return @as(f32, @floatFromInt(self.y_axis)) / @as(f32, @floatFromInt(std.math.maxInt(i16)));
        }
    };
    // const FieldData = struct {
    //     x_axis: f32,
    //     y_axis: f32,
    //     z_axis: f32,
    // };

    // The magnetometer ranges
    const Range = enum(u2) {
        range_4_gauss = 0b00, // +/- 4g (default value)
        range_8_gauss = 0b01, // +/- 8g
        range_12_gauss = 0b10, // +/- 12g
        range_16_gauss = 0b11, // +/- 16g
    };

    // The magnetometer data rate, includes FAST_ODR bit */
    const DataRate = enum(u4) {
        data_rate_0_625_HZ = 0b0000, // 0.625 Hz
        data_rate_1_25_HZ = 0b0010, // 1.25 Hz
        data_rate_2_5_HZ = 0b0100, // 2.5 Hz
        data_rate_5_HZ = 0b0110, // 5 Hz
        data_rate_10_HZ = 0b1000, // 10 Hz
        data_rate_20_HZ = 0b1010, // 20 Hz
        data_rate_40_HZ = 0b1100, // 40 Hz
        data_rate_80_HZ = 0b1110, // 80 Hz
        fast_output_data_rate = 0b0001, // 80 Hz+
    };

    // The magnetometer performance mode
    const PerformanceMode = enum(u2) {
        low_mode_1000_HZ = 0b00, // Low power mode
        medium_mode_560_HZ = 0b01, // Medium performance mode
        high_mode_300_HZ = 0b10, // High performance mode
        ultra_high_mode_155_HZ = 0b11, // Ultra-high performance mode
    };

    // The magnetometer operation mode
    const OperationMode = enum(u2) {
        continuous_mode = 0b00, // Continuous conversion
        single_mode = 0b01, // Single-shot conversion
        power_down_mode = 0b11, // Powered-down mode
    };

    const Endian = enum(u1) {
        little = 0b0,
        big = 0b1,
    };

    const CtrlReg1 = packed struct {
        pub const address = 0x20;

        st: u1,
        data_rate: DataRate,
        operating_mode_xy: PerformanceMode,
        temp_en: u1,
    };

    const CtrlReg2 = packed struct {
        pub const address = 0x21;

        res0_1: u2 = 0,
        soft_reset: u1,
        reboot: u1,
        res0_2: u1 = 0,
        range: Range,
        res0_3: u1 = 0,
    };

    const CtrlReg3 = packed struct {
        pub const address = 0x22;

        mode: OperationMode,
        sim: u1,
        res0_1: u2 = 0,
        lp: u1,
        res0_2: u2 = 0,
    };

    const CtrlReg4 = packed struct {
        pub const address = 0x23;

        res0_1: u1 = 0,
        ble: Endian,
        operating_mode_z: PerformanceMode,
        res0_2: u4 = 0,
    };

    const StatusReg = packed struct {
        pub const address = 0x27;

        xda: u1,
        yda: u1,
        zda: u1,
        zyxda: u1,
        xor: u1,
        yor: u1,
        zor: u1,
        zyxor: u1,
    };

    const OutX_L = packed struct {
        pub const address = 0x28;

        lower: u8,
    };
    const OutX_H = packed struct {
        pub const address = 0x29;

        higher: u8,
    };
    const OutY_L = packed struct {
        pub const address = 0x2A;

        lower: u8,
    };
    const OutY_H = packed struct {
        pub const address = 0x2B;

        higher: u8,
    };
    const OutZ_L = packed struct {
        pub const address = 0x2C;

        lower: u8,
    };
    const OutZ_H = packed struct {
        pub const address = 0x2D;

        higher: u8,
    };

    spi: hardware.spi.SPI,

    pub fn create(sck_pin: c_uint, tx_pin: c_uint, rx_pin: c_uint, cs_pin: c_uint, spi_hw: [*c]csdk.spi_hw_t) Self {
        return Self{
            .spi = hardware.spi.SPI.create(sck_pin, tx_pin, rx_pin, cs_pin, spi_hw),
        };
    }

    pub fn init(self: Self) void {
        self.spi.init();

        var ctrl_reg1 = self.spi.readReg(LIS3MDL.CtrlReg1);
        ctrl_reg1.operating_mode_xy = .low_mode_1000_HZ;
        ctrl_reg1.data_rate = .fast_output_data_rate;
        self.spi.writeReg(LIS3MDL.CtrlReg1, ctrl_reg1);

        var ctrl_reg2 = self.spi.readReg(LIS3MDL.CtrlReg2);
        ctrl_reg2.range = .range_16_gauss;
        self.spi.writeReg(LIS3MDL.CtrlReg2, ctrl_reg2);

        var ctrl_reg3 = self.spi.readReg(LIS3MDL.CtrlReg3);
        ctrl_reg3.mode = .continuous_mode;
        self.spi.writeReg(LIS3MDL.CtrlReg3, ctrl_reg3);

        var ctrl_reg4 = self.spi.readReg(LIS3MDL.CtrlReg4);
        ctrl_reg4.ble = .little;
        ctrl_reg4.operating_mode_z = .low_mode_1000_HZ;
        self.spi.writeReg(LIS3MDL.CtrlReg4, ctrl_reg4);
    }

    fn dataAvailable(self: Self) void {
        const status = self.spi.readReg(StatusReg);
        return status.zyxda;
    }

    pub fn getRawData(self: Self) RawData {
        const x_l = @as(u16, self.spi.readReg(OutX_L).lower);
        const x_h = @as(u16, self.spi.readReg(OutX_H).higher);
        const y_l = @as(u16, self.spi.readReg(OutY_L).lower);
        const y_h = @as(u16, self.spi.readReg(OutY_H).higher);
        // const z_l = @as(u16, self.spi.readReg(OutZ_L).lower);
        // const z_h = @as(u16, self.spi.readReg(OutZ_H).higher);

        return RawData{
            .x_axis = @bitCast((x_h << 8) | x_l),
            .y_axis = @bitCast((y_h << 8) | y_l),
            // .z_axis = @bitCast((z_h << 8) | z_l),
        };
    }

    pub fn getAngle(self: Self) f32 {
        const raw_data = self.getRawData();

        const x_axis: f32 = raw_data.xF32();
        const y_axis: f32 = raw_data.yF32();

        return switch (math.sign(raw_data.x_axis)) {
            //Vertical
            0 => switch (math.sign(raw_data.y_axis)) {
                0 => 0, //Somehow all zeros. Treat as angle zero
                1 => tau / 2.0, //Directly up
                -1 => tau * 3.0 / 2.0, //Directly down
                else => unreachable,
            },

            //Right half
            1 => switch (math.sign(raw_data.y_axis)) {
                0 => 0, //Directly right
                1 => math.atan(y_axis / x_axis),
                -1 => math.atan(y_axis / x_axis) + tau,
                else => unreachable,
            },

            //Left half
            -1 => switch (math.sign(raw_data.y_axis)) {
                0 => tau / 2.0, //Directly left
                1, -1 => math.atan(y_axis / x_axis) + tau / 2.0,
                else => unreachable,
            },

            else => unreachable,
        };
    }

    pub fn getSensor(self: *Self) Sensor {
        return Sensor{
            .ctx = self,
            .getAngleFn = _getAngle,
        };
    }

    fn _getAngle(ctx: *anyopaque) f32 {
        const self: *Self = @alignCast(@ptrCast(ctx));
        return self.getAngle();
    }
};

pub fn demo() noreturn {
    var sensor = LIS3MDL.create(18, 19, 16, 17, csdk.spi0_hw);
    sensor.init();

    stdio.print("CtrlReg1: {}\n", .{sensor.spi.readReg(LIS3MDL.CtrlReg1)});
    stdio.print("CtrlReg2: {}\n", .{sensor.spi.readReg(LIS3MDL.CtrlReg2)});
    stdio.print("CtrlReg3: {}\n", .{sensor.spi.readReg(LIS3MDL.CtrlReg3)});
    stdio.print("CtrlReg4: {}\n", .{sensor.spi.readReg(LIS3MDL.CtrlReg4)});
    var raw_data = sensor.getRawData();
    // stdio.print("X:{d: <8}  Y:{d: <8}  Z:{d: <8}\n\n", .{ raw_data.x_axis, raw_data.y_axis, raw_data.z_axis });

    while (true) {
        raw_data = sensor.getRawData();
        stdio.print("{}   {d: <.4}\r", .{ raw_data, sensor.getAngle() / tau });
    }
}
