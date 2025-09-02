const std = @import("std");
const math = std.math;

const Vector2 = @This();
pub const Vec2 = @Vector(2, f32);

xy: Vec2 = @splat(0.0),

pub fn create(x_val: f32, y_val: f32) Vector2 {
    return Vector2{
        .xy = Vec2{ x_val, y_val },
    };
}

pub fn createScalar(scalar: f32) Vector2 {
    return Vector2{
        .xy = @as(Vec2, @splat(scalar)),
    };
}

pub inline fn x(self: *const Vector2) f32 {
    return self.xy[0];
}

pub inline fn y(self: *const Vector2) f32 {
    return self.xy[1];
}

pub fn add(self: *const Vector2, other: Vector2) Vector2 {
    return Vector2{
        .xy = self.xy + other.xy,
    };
}

pub fn sub(self: *const Vector2, other: Vector2) Vector2 {
    return Vector2{
        .xy = self.xy - other.xy,
    };
}

pub fn mul(self: *const Vector2, other: Vector2) Vector2 {
    return Vector2{
        .xy = self.xy * other.xy,
    };
}

pub fn div(self: *const Vector2, other: Vector2) Vector2 {
    return Vector2{
        .xy = self.xy / other.xy,
    };
}

pub fn dot(self: *const Vector2, other: Vector2) f32 {
    // return self.x() * other.x() +
    //     self.y() * other.y() +
    //     self.z() * other.z();
    return @reduce(.Add, self.xy * other.xy);
}

pub fn length(self: *const Vector2) f32 {
    return @sqrt(self.dot(self.*));
}

pub fn normalize(self: *const Vector2) Vector2 {
    const vec_length = self.length();
    return Vector2{
        .xy = self.xy / @as(Vec2, @splat(vec_length)),
    };
}

pub fn rotate(self: *const Vector2, angle: f32) Vector2 {
    const cos = math.cos(angle);
    const sin = math.sin(angle);

    // (x*cos - y*sin, x*sin + y*cos)
    return Vector2.create(self.x() * cos - self.y() * sin, self.x() * sin + self.y() * cos);
}

pub fn angleBetween(self: *const Vector2, other: Vector2) f32 {
    return math.acos(self.normalize().dot(other.normalize()));
}

pub fn approxEqAbs(self: *const Vector2, other: Vector2, tolerance: f32) bool {
    return math.approxEqAbs(f32, self.x(), other.x(), tolerance) and
        math.approxEqAbs(f32, self.y(), other.y(), tolerance) and
        math.approxEqAbs(f32, self.z(), other.z(), tolerance);
}

pub fn approxAlignedAbs(self: *const Vector2, other: Vector2, tolerance: f32) bool {
    return math.approxEqAbs(f32, self.angleBetween(other), 0.0, tolerance);
}

pub fn integrate(self: *Vector2, higher_order: Vector2, delta_time: f32) void {
    self.* = self.add(higher_order.mul(Vector2.createScalar(delta_time)));
}

/// Calculate the derivative of prev_value->self.
///
/// prev_value is the value from the previous sample
pub fn differentiate(self: *Vector2, prev_value: Vector2, delta_time: f32) Vector2 {
    return self.sub(prev_value).div(delta_time);
}

pub fn format(self: Vector2, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt; // autofix
    _ = options;

    try std.fmt.format(writer, "Vec2{{{d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.x(), self.y(), self.z() });
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "trivial length" {
    const vec = Vector2.create(0.0, 1.0);

    try expectEqual(1, vec.length());
}

test "normalize" {
    const vec = Vector2.create(1.0, 1.0);
    const normalized = vec.normalize();

    try expect(@abs(normalized.length() - 1.0) < 0.001);
    try expect(normalized.approxAlignedAbs(Vector2.create(1.0, 1.0), 0.001));
}

test "Rotate a perpendicular vector" {
    const vec = Vector2.create(1.0, 0.0);

    const result = vec.rotate(math.tau / 4.0);
    // std.debug.print("result: {}\n", .{result});

    try expect(result.approxAlignedAbs(Vector2.create(0.0, 1.0), 0.001));
}
