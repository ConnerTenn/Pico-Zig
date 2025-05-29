const std = @import("std");
const math = std.math;

const Vector3 = @This();
pub const Vec3 = @Vector(3, f32);

xyz: Vec3 = @splat(0.0),

pub fn create(x_val: f32, y_val: f32, z_val: f32) Vector3 {
    return Vector3{
        .xyz = Vec3{ x_val, y_val, z_val },
    };
}

pub fn create_scalar(scalar: f32) Vector3 {
    return Vector3{
        .xyz = @as(Vec3, @splat(scalar)),
    };
}

pub inline fn x(self: *const Vector3) f32 {
    return self.xyz[0];
}

pub inline fn y(self: *const Vector3) f32 {
    return self.xyz[1];
}

pub inline fn z(self: *const Vector3) f32 {
    return self.xyz[2];
}

pub fn add(self: *const Vector3, other: Vector3) Vector3 {
    return Vector3{
        .xyz = self.xyz + other.xyz,
    };
}

pub fn sub(self: *const Vector3, other: Vector3) Vector3 {
    return Vector3{
        .xyz = self.xyz - other.xyz,
    };
}

pub fn mul(self: *const Vector3, other: Vector3) Vector3 {
    return Vector3{
        .xyz = self.xyz * other.xyz,
    };
}

pub fn div(self: *const Vector3, other: Vector3) Vector3 {
    return Vector3{
        .xyz = self.xyz / other.xyz,
    };
}

pub fn dot(self: *const Vector3, other: Vector3) f32 {
    // return self.x() * other.x() +
    //     self.y() * other.y() +
    //     self.z() * other.z();
    return @reduce(.Add, self.xyz * other.xyz);
}

pub fn cross(self: *const Vector3, other: Vector3) Vector3 {
    // return Vector3.create(
    //     self.y() * other.z() - self.z() * other.y(),
    //     self.z() * other.x() - self.x() * other.z(),
    //     self.x() * other.y() - self.y() * other.x(),
    // );

    const self_yzx = @shuffle(f32, self.xyz, undefined, @Vector(3, i32){ 1, 2, 0 });
    const self_zxy = @shuffle(f32, self.xyz, undefined, @Vector(3, i32){ 2, 0, 1 });
    const other_yzx = @shuffle(f32, other.xyz, undefined, @Vector(3, i32){ 1, 2, 0 });
    const other_zxy = @shuffle(f32, other.xyz, undefined, @Vector(3, i32){ 2, 0, 1 });

    return Vector3{
        .xyz = self_yzx * other_zxy - self_zxy * other_yzx,
    };
}

pub fn length(self: *const Vector3) f32 {
    return @sqrt(self.dot(self.*));
}

pub fn normalize(self: *const Vector3) Vector3 {
    const vec_length = self.length();
    return Vector3{
        .xyz = self.xyz / @as(Vec3, @splat(vec_length)),
    };
}

pub fn rotate(self: *const Vector3, axis: Vector3, angle: f32) Vector3 {
    // Perpendicular to self and the axis, and in the plane of rotation
    const perpendicular_in_rot_plane = axis.cross(self.*);
    // Inline with the vector, but in the plane of rotation
    // This is essentially the vector projected onto the rotation plane
    const inline_in_rot_plane = perpendicular_in_rot_plane.cross(axis);

    // The vector projected onto the axis of rotation
    // This could also be achieved with a dot product
    const inline_on_rot_axis = self.sub(inline_in_rot_plane);

    //Scalar vectors for sin and cos
    const cos_vec = Vector3.create_scalar(math.cos(angle));
    const sin_vec = Vector3.create_scalar(math.sin(angle));

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

/// Y-Forwards
///
/// Z-Up
pub fn rotatePitchYaw(self: *const Vector3, pitch: f32, yaw: f32) Vector3 {
    // const roll_axis = Vector3.create(0.0, 1.0, 0.0);
    const pitch_axis = Vector3.create(1.0, 0.0, 0.0);
    const yaw_axis = Vector3.create(0.0, 0.0, 1.0);

    // Roll is inline with final rotor
    return self.rotate(pitch_axis, pitch).rotate(yaw_axis, yaw);
}

pub fn integrate(self: *Vector3, higher_order: Vector3, delta_time: f32) void {
    self.* = self.add(higher_order.mul(Vector3.create_scalar(delta_time)));
}

pub fn differentiate(self: *Vector3, new_value: Vector3, delta_time: f32) Vector3 {
    return new_value.sub(self.*).div(delta_time);
}

pub fn format(self: Vector3, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt; // autofix
    _ = options;

    try std.fmt.format(writer, "Vec3{{{d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.x(), self.y(), self.z() });
}

const expect = std.testing.expect;

fn checkAligned(vec1: Vector3, vec2: Vector3, precision: f32) bool {
    const alignment = vec1.normalize().dot(vec2.normalize());
    std.debug.print("alignment: {}\n", .{alignment});
    return alignment > 1.0 - precision;
}

test "trivial length" {
    const vec = Vector3.create(0.0, 1.0, 0.0);

    try expect(vec.length() == 1);
}

test "normalize" {
    const vec = Vector3.create(1.0, 1.0, 1.0);
    const normalized = vec.normalize();

    try expect(@abs(normalized.length() - 1.0) < 0.001);
    try expect(checkAligned(normalized, Vector3.create(1.0, 1.0, 1.0), 0.001));
}

test "Rotate a perpendicular vector" {
    const axis = Vector3.create(0.0, 0.0, 1.0);
    const vec = Vector3.create(1.0, 0.0, 0.0);

    const result = vec.rotate(axis, math.tau / 4.0);
    std.debug.print("result: {}\n", .{result});

    try expect(checkAligned(result, Vector3.create(0.0, 1.0, 0.0), 0.001));
}

test "Rotate a mixed vector" {
    const axis = Vector3.create(0.0, 0.0, 1.0);
    const vec = Vector3.create(1.0, 1.0, 1.0);

    const result = vec.rotate(axis, math.tau / 4.0);
    std.debug.print("result: {}\n", .{result});

    try expect(checkAligned(result, Vector3.create(-1.0, 1.0, 1.0), 0.001));
}

test "Yaw" {
    const vec = Vector3.create(0.0, 1.0, 0.0);

    const result = vec.rotatePitchYaw(0.0, math.tau / 8.0);
    std.debug.print("result: {}\n", .{result});

    try expect(checkAligned(result, Vector3.create(-1.0, 1.0, 0.0), 0.001));
}

test "Pitch" {
    const vec = Vector3.create(0.0, 1.0, 0.0);

    const result = vec.rotatePitchYaw(math.tau / 8.0, 0.0);
    std.debug.print("result: {}\n", .{result});

    try expect(checkAligned(result, Vector3.create(0.0, 1.0, 1.0), 0.001));
}

test "PitchYaw" {
    const vec = Vector3.create(0.0, 1.0, 0.0);

    const angle = math.tau / 8.0;

    const result = vec.rotatePitchYaw(angle, angle);
    std.debug.print("result: {}\n", .{result});

    const pitch_z_component = vec.y() * math.sin(angle);
    const pitch_y_component = vec.y() * math.cos(angle);
    const yaw_x_component = pitch_y_component * math.sin(-angle);
    const yaw_y_component = pitch_y_component * math.cos(-angle);

    try expect(checkAligned(result, Vector3.create(yaw_x_component, yaw_y_component, pitch_z_component), 0.001));
}
