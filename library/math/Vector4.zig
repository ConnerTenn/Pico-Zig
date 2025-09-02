const std = @import("std");
const math = std.math;

const Vector4 = @This();
pub const Vec4 = @Vector(4, f32);

wxyz: Vec4 = @splat(0.0),

pub fn create(w_val: f32, x_val: f32, y_val: f32, z_val: f32) Vector4 {
    return Vector4{
        .wxyz = Vec4{ w_val, x_val, y_val, z_val },
    };
}

pub fn createScalar(scalar: f32) Vector4 {
    return Vector4{
        .wxyz = @as(Vec4, @splat(scalar)),
    };
}

pub inline fn w(self: *const Vector4) f32 {
    return self.wxyz[0];
}

pub inline fn x(self: *const Vector4) f32 {
    return self.wxyz[1];
}

pub inline fn y(self: *const Vector4) f32 {
    return self.wxyz[2];
}

pub inline fn z(self: *const Vector4) f32 {
    return self.wxyz[3];
}

pub fn add(self: *const Vector4, other: Vector4) Vector4 {
    return Vector4{
        .wxyz = self.wxyz + other.wxyz,
    };
}

pub fn sub(self: *const Vector4, other: Vector4) Vector4 {
    return Vector4{
        .wxyz = self.wxyz - other.wxyz,
    };
}

pub fn mul(self: *const Vector4, other: Vector4) Vector4 {
    return Vector4{
        .wxyz = self.wxyz * other.wxyz,
    };
}

pub fn div(self: *const Vector4, other: Vector4) Vector4 {
    return Vector4{
        .wxyz = self.wxyz / other.wxyz,
    };
}

pub fn dot(self: *const Vector4, other: Vector4) f32 {
    return @reduce(.Add, self.wxyz * other.wxyz);
}

pub fn length(self: *const Vector4) f32 {
    return @sqrt(self.dot(self.*));
}

pub fn normalize(self: *const Vector4) Vector4 {
    const vec_length = self.length();
    return Vector4{
        .wxyz = self.wxyz / @as(Vec4, @splat(vec_length)),
    };
}

pub fn angleBetween(self: *const Vector4, other: Vector4) f32 {
    return math.acos(self.normalize().dot(other.normalize()));
}

pub fn approxEqAbs(self: *const Vector4, other: Vector4, tolerance: f32) bool {
    return math.approxEqAbs(f32, self.w(), other.w(), tolerance) and
        math.approxEqAbs(f32, self.x(), other.x(), tolerance) and
        math.approxEqAbs(f32, self.y(), other.y(), tolerance) and
        math.approxEqAbs(f32, self.z(), other.z(), tolerance);
}

pub fn approxAlignedAbs(self: *const Vector4, other: Vector4, tolerance: f32) bool {
    return math.approxEqAbs(f32, self.angleBetween(other), 0.0, tolerance);
}

/// Accumulate the integrand into the current vector
pub fn integrate(self: *Vector4, integrand: Vector4, delta_time: f32) void {
    self.* = self.add(integrand.mul(Vector4.createScalar(delta_time)));
}

/// Calculate the derivative of prev_value->self.
///
/// prev_value is the value from the previous sample
pub fn differentiate(self: *const Vector4, prev_value: Vector4, delta_time: f32) Vector4 {
    return self.sub(prev_value).div(delta_time);
}

pub fn format(self: Vector4, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt; // autofix
    _ = options;

    try std.fmt.format(writer, "Vec4{{{d: >12.6}, {d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.w(), self.x(), self.y(), self.z() });
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "trivial length" {
    const vec = Vector4.create(0.0, 0.0, 1.0, 0.0);

    try expectEqual(1, vec.length());
}

test "normalize" {
    const vec = Vector4.create(1.0, 1.0, 1.0, 1.0);
    const normalized = vec.normalize();

    try expect(@abs(normalized.length() - 1.0) < 0.001);
    try expect(normalized.approxAlignedAbs(Vector4.create(1.0, 1.0, 1.0, 1.0), 0.001));
}
