const std = @import("std");
const math = std.math;

pub fn Vector2(T: type) type {
    return struct {
        const Self = @This();
        pub const Vec2 = @Vector(2, T);

        xy: Vec2 = @splat(0.0),

        pub fn create(x_val: T, y_val: T) Self {
            return Self{
                .xy = Vec2{ x_val, y_val },
            };
        }

        pub fn createScalar(scalar: T) Self {
            return Self{
                .xy = @as(Vec2, @splat(scalar)),
            };
        }

        pub inline fn x(self: *const Self) T {
            return self.xy[0];
        }

        pub inline fn y(self: *const Self) T {
            return self.xy[1];
        }

        pub fn add(self: *const Self, other: Self) Self {
            return Self{
                .xy = self.xy + other.xy,
            };
        }

        pub fn sub(self: *const Self, other: Self) Self {
            return Self{
                .xy = self.xy - other.xy,
            };
        }

        pub fn mul(self: *const Self, other: Self) Self {
            return Self{
                .xy = self.xy * other.xy,
            };
        }

        pub fn div(self: *const Self, other: Self) Self {
            return Self{
                .xy = self.xy / other.xy,
            };
        }

        pub fn dot(self: *const Self, other: Self) T {
            return @reduce(.Add, self.xy * other.xy);
        }

        pub fn length(self: *const Self) T {
            return @sqrt(self.dot(self.*));
        }

        pub fn normalize(self: *const Self) Self {
            const vec_length = self.length();
            return Self{
                .xy = self.xy / @as(Vec2, @splat(vec_length)),
            };
        }

        pub fn rotate(self: *const Self, angle: T) Self {
            const cos = math.cos(angle);
            const sin = math.sin(angle);

            // (x*cos - y*sin, x*sin + y*cos)
            return Self.create(self.x() * cos - self.y() * sin, self.x() * sin + self.y() * cos);
        }

        pub fn angleBetween(self: *const Self, other: Self) T {
            return math.acos(self.normalize().dot(other.normalize()));
        }

        pub fn approxEqAbs(self: *const Self, other: Self, tolerance: T) bool {
            return math.approxEqAbs(T, self.x(), other.x(), tolerance) and
                math.approxEqAbs(T, self.y(), other.y(), tolerance);
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

            try std.fmt.format(writer, "Vec2{{{d: >12.6}, {d: >12.6}}}", .{ self.x(), self.y() });
        }
    };
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "trivial length" {
    const vec = Vector2(f32).create(0.0, 1.0);

    try expectEqual(1, vec.length());
}

test "normalize" {
    const vec = Vector2(f32).create(1.0, 1.0);
    const normalized = vec.normalize();

    try expect(@abs(normalized.length() - 1.0) < 0.001);
    try expect(normalized.approxAlignedAbs(Vector2(f32).create(1.0, 1.0), 0.001));
}

test "Rotate a perpendicular vector" {
    const vec = Vector2(f32).create(1.0, 0.0);

    const result = vec.rotate(math.tau / 4.0);
    // std.debug.print("result: {}\n", .{result});

    try expect(result.approxAlignedAbs(Vector2(f32).create(0.0, 1.0), 0.001));
}
