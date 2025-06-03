// https://eater.net/quaternions

const std = @import("std");
const math = std.math;

const math3D = @import("math3D.zig");
const Vector3 = math3D.Vector3;

const Quaternion = @This();
pub const Vec4 = @Vector(4, f32);

const RealImag = struct {
    r: f32,
    ijk: Vector3,
};

// r represents the 'real' component
// The rest are standard quaternion component naming
rijk: Vec4 = Vec4{ 1, 0, 0, 0 },

pub fn create(r_val: f32, i_val: f32, j_val: f32, k_val: f32) Quaternion {
    return Quaternion{
        .rijk = Vec4{ r_val, i_val, j_val, k_val },
    };
}

pub fn fromVector(vec: Vector3) Quaternion {
    return fromRealImag(RealImag{
        .r = 0.0,
        .ijk = vec,
    });
}

pub fn fromAxisAngle(axis: Vector3, angle: f32) Quaternion {
    const half_angle = angle / 2.0;
    return fromRealImag(RealImag{
        .r = @cos(half_angle),
        .ijk = axis.normalize().mul(Vector3.createScalar(@sin(half_angle))),
    });
}

/// Y: Forward
///
/// Z: Up
pub fn fromRollPitchYaw(roll: f32, pitch: f32, yaw: f32) Quaternion {
    return fromAxisAngle(
        Vector3.create(0.0, 0.0, 1.0),
        yaw,
    ).mul(fromAxisAngle(
        Vector3.create(1.0, 0.0, 0.0),
        pitch,
    ).mul(fromAxisAngle(
        Vector3.create(0.0, 1.0, 0.0),
        roll,
    )));
}

pub inline fn r(self: *const Quaternion) f32 {
    return self.rijk[0];
}

pub inline fn i(self: *const Quaternion) f32 {
    return self.rijk[1];
}

pub inline fn j(self: *const Quaternion) f32 {
    return self.rijk[2];
}

pub inline fn k(self: *const Quaternion) f32 {
    return self.rijk[3];
}

pub inline fn toRealImag(self: Quaternion) RealImag {
    return RealImag{
        .r = self.rijk[0],
        .ijk = Vector3{ .xyz = @shuffle(f32, self.rijk, undefined, @Vector(3, i32){ 1, 2, 3 }) },
    };
}

pub inline fn fromRealImag(vec_scalar: RealImag) Quaternion {
    return Quaternion{
        .rijk = @shuffle(
            f32,
            @Vector(1, f32){vec_scalar.r},
            vec_scalar.ijk.xyz,
            @Vector(4, f32){ 0, -1, -2, -3 },
        ),
    };
}

pub fn inverse(self: *const Quaternion) Quaternion {
    return Quaternion{
        .rijk = self.rijk * Vec4{ 1.0, -1.0, -1.0, -1.0 },
    };
}

// pub fn add(self: *const Quaternion, other: Quaternion) Quaternion {
//     return self.rijk + other.rijk;
// }

// https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
pub fn mul(self: *const Quaternion, other: Quaternion) Quaternion {
    const q1 = self.toRealImag();
    const q2 = other.toRealImag();

    const result = RealImag{
        .r = q1.r * q2.r - q1.ijk.dot(q2.ijk),
        .ijk = Vector3.createScalar(q1.r).mul(q2.ijk).add(Vector3.createScalar(q2.r).mul(q1.ijk)).add(q1.ijk.cross(q2.ijk)),
    };
    return fromRealImag(result);
}

pub fn rotateVector(self: *const Quaternion, vec: Vector3) Vector3 {
    const result = self.mul(fromVector(vec)).mul(self.inverse());

    return result.toRealImag().ijk;
}

pub fn approxEqAbs(self: *const Quaternion, other: Quaternion, tolerance: f32) bool {
    return math.approxEqAbs(f32, self.r(), other.r(), tolerance) and
        math.approxEqAbs(f32, self.i(), other.i(), tolerance) and
        math.approxEqAbs(f32, self.j(), other.j(), tolerance) and
        math.approxEqAbs(f32, self.k(), other.k(), tolerance);
}

pub fn format(self: Quaternion, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt; // autofix
    _ = options;

    try std.fmt.format(writer, "Quaternion{{{d: >12.6}, {d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.r(), self.i(), self.j(), self.k() });
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "to and from RealImag" {
    const quaternion = Quaternion.create(1, 2, 3, 4);
    const vec_scalar = quaternion.toRealImag();
    try expectEqual(
        1,
        vec_scalar.r,
    );
    try expectEqual(Vector3.create(2, 3, 4), vec_scalar.ijk);

    const recovered = fromRealImag(vec_scalar);

    try expectEqual(quaternion, recovered);
}

test "1*1" {
    const q1 = Quaternion.create(1, 0, 0, 0);
    const q2 = Quaternion.create(1, 0, 0, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        1,
        0,
        0,
        0,
    ), 0.001));
}

test "1 * (i+j+k)" {
    const q1 = Quaternion.create(1, 0, 0, 0);
    const q2 = Quaternion.create(0, 1, 1, 1);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        0,
        1,
        1,
        1,
    ), 0.001));
}

test "i*i" {
    const q1 = Quaternion.create(0, 1, 0, 0);
    const q2 = Quaternion.create(0, 1, 0, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        -1,
        0,
        0,
        0,
    ), 0.001));
}

test "j*j" {
    const q1 = Quaternion.create(0, 0, 1, 0);
    const q2 = Quaternion.create(0, 0, 1, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        -1,
        0,
        0,
        0,
    ), 0.001));
}

test "k*k" {
    const q1 = Quaternion.create(0, 0, 0, 1);
    const q2 = Quaternion.create(0, 0, 0, 1);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        -1,
        0,
        0,
        0,
    ), 0.001));
}

test "i*j" {
    const q1 = Quaternion.create(0, 1, 0, 0);
    const q2 = Quaternion.create(0, 0, 1, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        0,
        0,
        0,
        1,
    ), 0.001));
}

test "j*k" {
    const q1 = Quaternion.create(0, 0, 1, 0);
    const q2 = Quaternion.create(0, 0, 0, 1);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        0,
        1,
        0,
        0,
    ), 0.001));
}

test "k*i" {
    const q1 = Quaternion.create(0, 0, 0, 1);
    const q2 = Quaternion.create(0, 1, 0, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion.create(
        0,
        0,
        1,
        0,
    ), 0.001));
}

test "inverse" {
    const quaternion = Quaternion.create(0.5, 0.2, -0.7, 0.1);
    const result = quaternion.inverse();
    try expect(result.approxEqAbs(Quaternion.create(
        0.5,
        -0.2,
        0.7,
        -0.1,
    ), 0.001));
}

test "rotate yaw" {
    const axis = Vector3.create(0, 0, 1);
    const angle = math.tau * 0.25;
    const quaternion = Quaternion.fromAxisAngle(axis, angle);

    const point = Vector3.create(1, 0, 0);
    const expected = Vector3.create(0, 1, 0);

    const result_quaternion = quaternion.rotateVector(point);
    try expect(result_quaternion.approxEqAbs(expected, 0.001));

    const result_vector = point.rotate(axis, angle);
    try expect(result_vector.approxEqAbs(expected, 0.001));
}

test "rotate pitch" {
    const axis = Vector3.create(1, 0, 0);
    const angle = math.tau * 0.25;
    const quaternion = Quaternion.fromAxisAngle(axis, angle);

    const point = Vector3.create(0, 1, 0);
    const expected = Vector3.create(0, 0, 1);

    const result_quaternion = quaternion.rotateVector(point);
    try expect(result_quaternion.approxEqAbs(expected, 0.001));

    const result_vector = point.rotate(axis, angle);
    try expect(result_vector.approxEqAbs(expected, 0.001));
}

test "rotate roll" {
    const axis = Vector3.create(0, 1, 0);
    const angle = math.tau * 0.25;
    const quaternion = Quaternion.fromAxisAngle(axis, angle);

    const point = Vector3.create(1, 0, 0);
    const expected = Vector3.create(0, 0, -1);

    const result_quaternion = quaternion.rotateVector(point);
    try expect(result_quaternion.approxEqAbs(expected, 0.001));

    const result_vector = point.rotate(axis, angle);
    try expect(result_vector.approxEqAbs(expected, 0.001));
}

test "rotate off axis" {
    const axis = Vector3.create(1, 1, 1);
    const angle = math.tau * 0.87;
    const quaternion = Quaternion.fromAxisAngle(axis, angle);

    const point = Vector3.create(-1.79, 2.46, 0.88);

    const expected = point.rotate(axis, angle);
    const result = quaternion.rotateVector(point);
    // std.debug.print("expected: {}\n", .{expected});
    // std.debug.print("result: {}\n", .{result});
    try expect(result.approxEqAbs(expected, 0.001));
}

test "RollPitchYaw" {
    const point = Vector3.create(0.0, 0.0, 1.0);

    const roll = math.tau / 8.0;
    const pitch = math.tau / 5.6;
    const yaw = math.tau / 2.7;
    const quaternion = Quaternion.fromRollPitchYaw(roll, pitch, yaw);

    const result = quaternion.rotateVector(point);

    const expected = point
        .rotate(Vector3.create(0, 1, 0), roll)
        .rotate(Vector3.create(1, 0, 0), pitch)
        .rotate(Vector3.create(0, 0, 1), yaw);

    try expect(result.approxAlignedAbs(expected, 0.001));
}
