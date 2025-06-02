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
rijk: Vec4 = @splat(0.0),

pub fn create(r_val: f32, i_val: f32, j_val: f32, k_val: f32) Quaternion {
    return Quaternion{
        .rijk = Vec4{ r_val, i_val, j_val, k_val },
    };
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

pub fn approxEqAbs(self: *const Quaternion, other: Quaternion, tolerance: f32) bool {
    return math.approxEqAbs(f32, self.r(), other.r(), tolerance) and
        math.approxEqAbs(f32, self.i(), other.i(), tolerance) and
        math.approxEqAbs(f32, self.j(), other.j(), tolerance) and
        math.approxEqAbs(f32, self.k(), other.k(), tolerance);
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
