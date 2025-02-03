const std = @import("std");
const math = std.math;
const tau = math.tau;

const pico = @import("../pico.zig");

pub const PhaseVoltage = struct {
    const Self = @This();
    const u_axis_angle = 0.0 * tau / 3.0; //0 deg
    const v_axis_angle = 1.0 * tau / 3.0; //120 deg
    const w_axis_angle = 2.0 * tau / 3.0; //240 deg

    u_axis: f32,
    v_axis: f32,
    w_axis: f32,

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("U:", .{});
        try pico.stdio.printBarGraph(10, self.u_axis, writer);
        try writer.print("  V:", .{});
        try pico.stdio.printBarGraph(10, self.v_axis, writer);
        try writer.print("  W:", .{});
        try pico.stdio.printBarGraph(10, self.w_axis, writer);
    }
};

pub fn getPhaseVoltage(direct_torque: f32, tangent_torque: f32, angle: f32) PhaseVoltage {
    return PhaseVoltage{
        .u_axis = direct_torque * @cos(angle - PhaseVoltage.u_axis_angle) - tangent_torque * @sin(angle - PhaseVoltage.u_axis_angle),
        .v_axis = direct_torque * @cos(angle - PhaseVoltage.v_axis_angle) - tangent_torque * @sin(angle - PhaseVoltage.v_axis_angle),
        .w_axis = direct_torque * @cos(angle - PhaseVoltage.w_axis_angle) - tangent_torque * @sin(angle - PhaseVoltage.w_axis_angle),
    };
}
