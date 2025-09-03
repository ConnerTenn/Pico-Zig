const std = @import("std");
const math = std.math;

pub fn Vector4(T: type) type {
    return struct {
        const Self = @This();
        pub const Vec4 = @Vector(4, T);

        wxyz: Vec4 = @splat(0.0),

        pub fn create(w_val: T, x_val: T, y_val: T, z_val: T) Self {
            return Self{
                .wxyz = Vec4{ w_val, x_val, y_val, z_val },
            };
        }

        pub fn createScalar(scalar: T) Self {
            return Self{
                .wxyz = @as(Vec4, @splat(scalar)),
            };
        }

        pub inline fn w(self: *const Self) T {
            return self.wxyz[0];
        }

        pub inline fn x(self: *const Self) T {
            return self.wxyz[1];
        }

        pub inline fn y(self: *const Self) T {
            return self.wxyz[2];
        }

        pub inline fn z(self: *const Self) T {
            return self.wxyz[3];
        }

        pub fn add(self: *const Self, other: Self) Self {
            return Self{
                .wxyz = self.wxyz + other.wxyz,
            };
        }

        pub fn sub(self: *const Self, other: Self) Self {
            return Self{
                .wxyz = self.wxyz - other.wxyz,
            };
        }

        pub fn mul(self: *const Self, other: Self) Self {
            return Self{
                .wxyz = self.wxyz * other.wxyz,
            };
        }

        pub fn div(self: *const Self, other: Self) Self {
            return Self{
                .wxyz = self.wxyz / other.wxyz,
            };
        }

        pub fn dot(self: *const Self, other: Self) T {
            return @reduce(.Add, self.wxyz * other.wxyz);
        }

        pub fn length(self: *const Self) T {
            return @sqrt(self.dot(self.*));
        }

        pub fn normalize(self: *const Self) Self {
            const vec_length = self.length();
            return Self{
                .wxyz = self.wxyz / @as(Vec4, @splat(vec_length)),
            };
        }

        pub fn angleBetween(self: *const Self, other: Self) T {
            return math.acos(self.normalize().dot(other.normalize()));
        }

        pub fn approxEqAbs(self: *const Self, other: Self, tolerance: T) bool {
            return math.approxEqAbs(T, self.w(), other.w(), tolerance) and
                math.approxEqAbs(T, self.x(), other.x(), tolerance) and
                math.approxEqAbs(T, self.y(), other.y(), tolerance) and
                math.approxEqAbs(T, self.z(), other.z(), tolerance);
        }

        pub fn approxAlignedAbs(self: *const Self, other: Self, tolerance: T) bool {
            return math.approxEqAbs(T, self.angleBetween(other), 0.0, tolerance);
        }

        /// Accumulate the integrand into the current vector
        pub fn integrate(self: *Self, integrand: Self, delta_time: T) void {
            self.* = self.add(integrand.mul(Self.createScalar(delta_time)));
        }

        /// Calculate the derivative of prev_value->self.
        ///
        /// prev_value is the value from the previous sample
        pub fn differentiate(self: *const Self, prev_value: Self, delta_time: T) Self {
            return self.sub(prev_value).div(delta_time);
        }

        pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt; // autofix
            _ = options;

            try std.fmt.format(writer, "Vec4{{{d: >12.6}, {d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.w(), self.x(), self.y(), self.z() });
        }
    };
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "trivial length" {
    const vec = Vector4(f32).create(0.0, 0.0, 1.0, 0.0);

    try expectEqual(1, vec.length());
}

test "normalize" {
    const vec = Vector4(f32).create(1.0, 1.0, 1.0, 1.0);
    const normalized = vec.normalize();

    try expect(@abs(normalized.length() - 1.0) < 0.001);
    try expect(normalized.approxAlignedAbs(Vector4(f32).create(1.0, 1.0, 1.0, 1.0), 0.001));
}
