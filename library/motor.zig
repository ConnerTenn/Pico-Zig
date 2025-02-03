const std = @import("std");
const math = std.math;
const tau = math.tau;

const pico = @import("../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const hardware = pico.hardware;
const library = pico.library;
const foc = library.foc;

pub const Motor = struct {
    const Self = @This();

    pub fn Parameters(T: type) type {
        return struct {
            angle: T, //rad
            velocity: T, // rad/sec
            torque: T, // [0,1]
            acceleration: T, // rad/(s^2)
        };
    }

    const num_calibration_samples = 512;

    driver: PwmDriver,
    windings_per_rotation: u8,

    sensor: library.sensor.Sensor,

    calibration_data: [num_calibration_samples]f32 = .{0} ** num_calibration_samples,

    target: Parameters(?f32) = .{ .angle = null, .velocity = null, .torque = null, .acceleration = null },
    limits: Parameters(?f32) = .{ .angle = null, .velocity = null, .torque = null, .acceleration = null },
    state: Parameters(f32) = .{ .angle = 0, .velocity = 0, .torque = 0, .acceleration = 0 },

    pid: library.pid.PIDcontrol,

    last_time_us: csdk.absolute_time_t = 0,

    pub fn create(u_axis_slice: hardware.pwm.PwmSlice.SliceNum, v_axis_slice: hardware.pwm.PwmSlice.SliceNum, w_axis_slice: hardware.pwm.PwmSlice.SliceNum, windings_per_rotation: u8, sensor: library.sensor.Sensor, pid: library.pid.PIDcontrol) Self {
        return Self{
            .driver = PwmDriver.create(u_axis_slice, v_axis_slice, w_axis_slice),
            .windings_per_rotation = windings_per_rotation,
            .sensor = sensor,
            .pid = pid,
        };
    }

    pub fn init(self: *Self) void {
        self.driver.init();

        self.setTorque(1.0, 0.0, 0);

        // //Settling time before measuring the angle bias
        // csdk.sleep_ms(1000);

        // self.calibrate();

        //Update the last time
        self.last_time_us = csdk.get_absolute_time();
    }

    pub fn calibrate(self: *Self) void {
        stdio.print("Running Calibration...\n", .{});

        const num_sample_iterations = 2;
        for (0..num_sample_iterations) |repeat_idx| {
            _ = repeat_idx; // autofix
            //Loop through every sample
            for (0..num_calibration_samples) |sample_idx| {
                //Drive to the target angle
                const target_angle = tau * @as(f32, @floatFromInt(sample_idx)) / @as(f32, @floatFromInt(num_calibration_samples));

                self.setTorque(1.0, 0.0, target_angle);
                csdk.sleep_ms(10);

                //Collect a number of samples and average them
                const measured_angle: f32 = self.sensor.getAngle();

                self.calibration_data[sample_idx] += pico.math.deltaError(f32, measured_angle, target_angle, tau); // target_angle - measured_angle;
                // stdio.print("\n", .{});
            }
        }

        //Finalize the averaging calculation
        for (0..num_calibration_samples) |sample_idx| {
            self.calibration_data[sample_idx] = self.calibration_data[sample_idx] / @as(f32, @floatFromInt(num_sample_iterations));
        }

        stdio.print("Calibration samples:\n", .{});
        for (0..num_calibration_samples) |sample_idx| {
            const target_angle = tau * @as(f32, @floatFromInt(sample_idx)) / @as(f32, @floatFromInt(num_calibration_samples));
            stdio.print("{d: >6.3} rad: {d: >6.3}\n", .{ target_angle, self.calibration_data[sample_idx] });
        }
    }

    pub fn setTorque(self: Self, direct_torque: f32, tangent_torque: f32, angle: f32) void {
        self.driver.setTorque(direct_torque, tangent_torque, angle * @as(f32, @floatFromInt(self.windings_per_rotation)));
    }

    pub fn getAngle(self: Self) f32 {
        const raw_angle = self.sensor.getAngle();
        // stdio.print("raw_angle:{d} ", .{raw_angle});

        //Offset to apply so that the selected sample is in the middle of the angle range
        const offset_for_centered_sample = tau / @as(f32, @floatFromInt(num_calibration_samples));
        const sample_bin = @as(f32, @floatFromInt(num_calibration_samples)) * raw_angle / tau + offset_for_centered_sample;
        const sample_idx = @mod(@as(u16, @intFromFloat(sample_bin)), num_calibration_samples);
        // stdio.print("sample_idx:{} ", .{sample_idx});

        //Get the compesated angle using the calibration data
        var compensated_angle = raw_angle - self.calibration_data[sample_idx];
        compensated_angle = pico.math.mod(f32, compensated_angle, tau, .regular);
        // stdio.print("{d: >3}:{d: >6.3}  ", .{ sample_idx, self.calibration_data[sample_idx] });
        // stdio.print("{d: >6.3} -> {d: >6.3}  ", .{ raw_angle, compensated_angle });

        // stdio.print("compensated_angle:{d}\n", .{compensated_angle});
        return compensated_angle;
    }

    pub fn setPosition(self: Self, angle: f32) void {
        _ = self; // autofix
        _ = angle; // autofix
    }

    pub fn setRate(self: Self, rad_per_sec: f32) void {
        _ = self; // autofix
        _ = rad_per_sec; // autofix
    }

    pub const TorqueFn = fn (angle: f32, delta_time_s: f32) f32;

    pub inline fn update(self: *Self, torqueFn: TorqueFn) void {
        const current_time_us = csdk.get_absolute_time();
        const delta_time_us = current_time_us - self.last_time_us;
        const delta_time_s: f32 = @as(f32, @floatFromInt(delta_time_us)) / (1000.0 * 1000.0);

        self.state.angle = self.getAngle();

        // const target_angle = 0.0 * tau;
        // const repetition = 6.0;
        // const delta_error = deltaError(f32, self.state.angle * repetition, target_angle * repetition, tau);

        // const torque_fn = struct {
        //     fn exponential_sigmoid(delta_err: f32) f32 {
        //         return (1.0 - math.pow(f32, 1.2, -@abs(delta_err))) * -math.sign(delta_err);
        //     }

        //     fn sin(delta_err: f32) f32 {
        //         return -math.sin(delta_err / 2.0);
        //     }

        //     fn skewed_sin(delta_err: f32) f32 {
        //         //https://www.desmos.com/calculator/04fgjt2y2l
        //         const skew_param = 2.0;
        //         const input_param = bldc.mod(f32, delta_err, tau, .regular) / math.pi - 1.0;
        //         const skew = math.pow(f32, @abs(input_param), skew_param) * math.sign(input_param);
        //         return -math.sin(tau * (skew + 1.0) / 2.0);
        //     }

        //     fn pid(delta_err: f32) f32 {
        //         return self.pid.update(delta_err, delta_time_s);
        //     }
        // }.skewed_sin;

        // const torque = torque_fn(delta_error);
        const torque = torqueFn(self.state.angle, delta_time_s);

        // const phase = bldc.mod(
        //     f32,
        //     self.state.angle * @as(f32, @floatFromInt(self.windings_per_rotation)),
        //     tau,
        //     .regular,
        // );
        // stdio.print("derror:{d: >6.3}  ", .{delta_error});
        // stdio.print("torque:{d: >6.3}  ", .{torque});
        // stdio.print("angle:{d: >6.3}  ", .{self.state.angle});
        // stdio.print("phase:{d: >6.3}  ", .{phase});

        self.setTorque(0.0, torque, self.state.angle);

        self.last_time_us = current_time_us;
        // stdio.print("\n", .{});
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("Position: {d:.3} ", .{self.state.angle / tau});
        try stdio.printPositionGraph(
            30,
            self.state.angle,
            0,
            tau,
            writer,
        );
        try writer.print("  state: {d:.3} ", .{self.state.angle / tau});
    }
};

pub const PwmDriver = struct {
    const Self = @This();

    u_axis_pins: hardware.pwm.PwmSlice,
    v_axis_pins: hardware.pwm.PwmSlice,
    w_axis_pins: hardware.pwm.PwmSlice,

    pub fn create(u_axis_slice: hardware.pwm.PwmSlice.SliceNum, v_axis_slice: hardware.pwm.PwmSlice.SliceNum, w_axis_slice: hardware.pwm.PwmSlice.SliceNum) Self {
        return Self{
            .u_axis_pins = hardware.pwm.PwmSlice.create(u_axis_slice, 0x0FFF),
            .v_axis_pins = hardware.pwm.PwmSlice.create(v_axis_slice, 0x0FFF),
            .w_axis_pins = hardware.pwm.PwmSlice.create(w_axis_slice, 0x0FFF),
        };
    }

    pub fn init(self: Self) void {
        self.u_axis_pins.init();
        self.v_axis_pins.init();
        self.w_axis_pins.init();

        hardware.pwm.enableSlices(&[_]hardware.pwm.PwmSlice{
            self.u_axis_pins,
            self.v_axis_pins,
            self.w_axis_pins,
        });
    }

    fn setPwmFromVoltages(self: Self, voltages: foc.PhaseVoltage) void {
        // stdio.print("{}\n", .{voltages});
        self.u_axis_pins.setLevel(pico.math.rescaleAsInt(u16, math.clamp(voltages.u_axis, -1, 1), self.u_axis_pins.counter_wrap));
        self.v_axis_pins.setLevel(pico.math.rescaleAsInt(u16, math.clamp(voltages.v_axis, -1, 1), self.u_axis_pins.counter_wrap));
        self.w_axis_pins.setLevel(pico.math.rescaleAsInt(u16, math.clamp(voltages.w_axis, -1, 1), self.u_axis_pins.counter_wrap));
    }

    pub fn setTorque(self: Self, direct_torque: f32, tangent_torque: f32, angle: f32) void {
        const voltages = foc.getPhaseVoltage(direct_torque, tangent_torque, angle);
        // stdio.print("{}", .{voltages});
        self.setPwmFromVoltages(voltages);
    }
};
