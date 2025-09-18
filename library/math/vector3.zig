const std = @import("std");
const math = std.math;

pub fn Vector3(T: type) type {
    return struct {
        const Self = @This();
        pub const Vec3 = @Vector(3, T);

        xyz: Vec3 = @splat(0.0),

        pub fn create(x_val: T, y_val: T, z_val: T) Self {
            return Self{
                .xyz = Vec3{ x_val, y_val, z_val },
            };
        }

        pub fn createScalar(scalar: T) Self {
            return Self{
                .xyz = @as(Vec3, @splat(scalar)),
            };
        }

        pub inline fn x(self: *const Self) T {
            return self.xyz[0];
        }

        pub inline fn y(self: *const Self) T {
            return self.xyz[1];
        }

        pub inline fn z(self: *const Self) T {
            return self.xyz[2];
        }

        pub fn add(self: *const Self, other: Self) Self {
            return Self{
                .xyz = self.xyz + other.xyz,
            };
        }

        pub fn sub(self: *const Self, other: Self) Self {
            return Self{
                .xyz = self.xyz - other.xyz,
            };
        }

        pub fn mul(self: *const Self, other: Self) Self {
            return Self{
                .xyz = self.xyz * other.xyz,
            };
        }

        pub fn div(self: *const Self, other: Self) Self {
            return Self{
                .xyz = self.xyz / other.xyz,
            };
        }

        pub fn dot(self: *const Self, other: Self) T {
            // return self.x() * other.x() +
            //     self.y() * other.y() +
            //     self.z() * other.z();
            return @reduce(.Add, self.xyz * other.xyz);
        }

        pub fn cross(self: *const Self, other: Self) Self {
            // return Self.create(
            //     self.y() * other.z() - self.z() * other.y(),
            //     self.z() * other.x() - self.x() * other.z(),
            //     self.x() * other.y() - self.y() * other.x(),
            // );

            const self_yzx = @shuffle(T, self.xyz, undefined, @Vector(3, i32){ 1, 2, 0 });
            const self_zxy = @shuffle(T, self.xyz, undefined, @Vector(3, i32){ 2, 0, 1 });
            const other_yzx = @shuffle(T, other.xyz, undefined, @Vector(3, i32){ 1, 2, 0 });
            const other_zxy = @shuffle(T, other.xyz, undefined, @Vector(3, i32){ 2, 0, 1 });

            return Self{
                .xyz = self_yzx * other_zxy - self_zxy * other_yzx,
            };
        }

        pub fn length(self: *const Self) T {
            return @sqrt(self.dot(self.*));
        }

        pub fn normalize(self: *const Self) Self {
            const vec_length = self.length();
            return Self{
                .xyz = self.xyz / @as(Vec3, @splat(vec_length)),
            };
        }

        pub fn rotate(self: *const Self, axis: Self, angle: T) Self {
            // Normalize the axis
            const axis_normalized = axis.normalize();

            // Perpendicular to self and the axis, and in the plane of rotation
            const perpendicular_in_rot_plane = axis_normalized.cross(self.*);
            // Inline with the vector, but in the plane of rotation
            // This is essentially the vector projected onto the rotation plane
            const inline_in_rot_plane = perpendicular_in_rot_plane.cross(axis_normalized);

            // The vector projected onto the axis of rotation
            // This could also be achieved with a dot product
            const inline_on_rot_axis = self.sub(inline_in_rot_plane);

            //Scalar vectors for sin and cos
            const cos_vec = Self.createScalar(math.cos(angle));
            const sin_vec = Self.createScalar(math.sin(angle));

            // cos * axis1 + sin * axis2
            // When the angle is 0, cos will be 1, passing through the vector that is inline with the original (inline_in_rot_plane)
            // When the angle is tau/4, sin will be 1, passing through the vector that is perpendicular with the original (perpendicular_in_rot_plane)
            // inline_in_rot_plane and perpendicular_in_rot_plane both store the components of the original vector that are in the rotation plane.
            // These components are multiplied with sin & cos to perform the rotation, and then are added back to the portion of the vector that
            // is inline with the rotation axis (inline_on_rot_axis).
            // This re-forms the vector, but with a rotation applied in the plane of rotation (perpendicular to the rotor)
            return inline_on_rot_axis.add(
                inline_in_rot_plane.mul(cos_vec),
            ).add(
                perpendicular_in_rot_plane.mul(sin_vec),
            );
        }

        pub fn angleBetween(self: *const Self, other: Self) T {
            return math.acos(self.normalize().dot(other.normalize()));
        }

        pub fn approxEqAbs(self: *const Self, other: Self, tolerance: T) bool {
            return math.approxEqAbs(T, self.x(), other.x(), tolerance) and
                math.approxEqAbs(T, self.y(), other.y(), tolerance) and
                math.approxEqAbs(T, self.z(), other.z(), tolerance);
        }

        pub fn approxAlignedAbs(self: *const Self, other: Self, tolerance: T) bool {
            return math.approxEqAbs(T, self.angleBetween(other), 0.0, tolerance);
        }

        /// Y: Forwards
        ///
        /// Z: Up
        pub fn rotatePitchYaw(self: *const Self, pitch: T, yaw: T) Self {
            // const roll_axis = Self.create(0.0, 1.0, 0.0);
            const pitch_axis = Self.create(1.0, 0.0, 0.0);
            const yaw_axis = Self.create(0.0, 0.0, 1.0);

            // Roll is inline with final rotor
            return self.rotate(pitch_axis, pitch).rotate(yaw_axis, yaw);
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

            try std.fmt.format(writer, "Vec3{{{d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.x(), self.y(), self.z() });
        }
    };
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "trivial length" {
    const vec = Vector3(f32).create(0.0, 1.0, 0.0);

    try expectEqual(1, vec.length());
}

test "normalize" {
    const vec = Vector3(f32).create(1.0, 1.0, 1.0);
    const normalized = vec.normalize();

    try expect(@abs(normalized.length() - 1.0) < 0.001);
    try expect(normalized.approxAlignedAbs(Vector3(f32).create(1.0, 1.0, 1.0), 0.001));
}

test "Rotate a perpendicular vector" {
    const axis = Vector3(f32).create(0.0, 0.0, 1.0);
    const vec = Vector3(f32).create(1.0, 0.0, 0.0);

    const result = vec.rotate(axis, math.tau / 4.0);
    // std.debug.print("result: {}\n", .{result});

    try expect(result.approxAlignedAbs(Vector3(f32).create(0.0, 1.0, 0.0), 0.001));
}

test "Rotate a mixed vector" {
    const axis = Vector3(f32).create(0.0, 0.0, 1.0);
    const vec = Vector3(f32).create(1.0, 1.0, 1.0);

    const result = vec.rotate(axis, math.tau / 4.0);
    // std.debug.print("result: {}\n", .{result});

    try expect(result.approxAlignedAbs(Vector3(f32).create(-1.0, 1.0, 1.0), 0.001));
}

test "Yaw" {
    const vec = Vector3(f32).create(0.0, 1.0, 0.0);

    const result = vec.rotatePitchYaw(0.0, math.tau / 8.0);
    // std.debug.print("result: {}\n", .{result});

    try expect(result.approxAlignedAbs(Vector3(f32).create(-1.0, 1.0, 0.0), 0.001));
}

test "Pitch" {
    const vec = Vector3(f32).create(0.0, 1.0, 0.0);

    const result = vec.rotatePitchYaw(math.tau / 8.0, 0.0);
    // std.debug.print("result: {}\n", .{result});

    try expect(result.approxAlignedAbs(Vector3(f32).create(0.0, 1.0, 1.0), 0.001));
}

test "PitchYaw" {
    const vec = Vector3(f32).create(0.0, 1.0, 0.0);

    const angle = math.tau / 8.0;

    const result = vec.rotatePitchYaw(angle, angle);
    // std.debug.print("result: {}\n", .{result});

    const pitch_z_component = vec.y() * math.sin(angle);
    const pitch_y_component = vec.y() * math.cos(angle);
    const yaw_x_component = pitch_y_component * math.sin(-angle);
    const yaw_y_component = pitch_y_component * math.cos(-angle);

    try expect(result.approxAlignedAbs(Vector3(f32).create(yaw_x_component, yaw_y_component, pitch_z_component), 0.001));
}
