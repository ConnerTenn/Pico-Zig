// https://eater.net/quaternions

const std = @import("std");

const math = @import("math.zig");
const Vector3 = math.Vector3;

pub fn Quaternion(T: type) type {
    return struct {
        const Self = @This();
        pub const Vec4 = @Vector(4, T);

        const RealImag = struct {
            r: T,
            ijk: Vector3(T),
        };

        // r represents the 'real' component
        // The rest are standard quaternion component naming
        rijk: Vec4 = Vec4{ 1, 0, 0, 0 },

        pub fn create(r_val: T, i_val: T, j_val: T, k_val: T) Self {
            return Self{
                .rijk = Vec4{ r_val, i_val, j_val, k_val },
            };
        }

        pub fn fromVector(vec: Vector3(T)) Self {
            return fromRealImag(RealImag{
                .r = 0.0,
                .ijk = vec,
            });
        }

        pub fn fromAxisAngle(axis: Vector3(T), angle: T) Self {
            const half_angle = angle / 2.0;
            return fromRealImag(RealImag{
                .r = @cos(half_angle),
                .ijk = axis.normalize().mul(Vector3(T).createScalar(@sin(half_angle))),
            });
        }

        /// Y: Forward
        ///
        /// X: Right
        ///
        /// Z: Up
        pub fn fromRollPitchYaw(roll: T, pitch: T, yaw: T) Self {
            return fromAxisAngle(
                Vector3(T).create(0.0, 0.0, 1.0),
                yaw,
            ).mul(fromAxisAngle(
                Vector3(T).create(1.0, 0.0, 0.0),
                pitch,
            ).mul(fromAxisAngle(
                Vector3(T).create(0.0, 1.0, 0.0),
                roll,
            )));
        }

        /// Y: Forward
        ///
        /// X: Right
        ///
        /// Z: Up
        pub fn fromEulerAngles(x: T, y: T, z: T) Self {
            const pitch = x;
            const roll = y;
            const yaw = z;

            return fromRollPitchYaw(roll, pitch, yaw);
        }

        pub inline fn r(self: *const Self) T {
            return self.rijk[0];
        }

        pub inline fn i(self: *const Self) T {
            return self.rijk[1];
        }

        pub inline fn j(self: *const Self) T {
            return self.rijk[2];
        }

        pub inline fn k(self: *const Self) T {
            return self.rijk[3];
        }

        pub inline fn toRealImag(self: Self) RealImag {
            return RealImag{
                .r = self.rijk[0],
                .ijk = Vector3(T){ .xyz = @shuffle(T, self.rijk, undefined, @Vector(3, i32){ 1, 2, 3 }) },
            };
        }

        pub inline fn fromRealImag(vec_scalar: RealImag) Self {
            return Self{
                .rijk = @shuffle(
                    T,
                    @Vector(1, T){vec_scalar.r},
                    vec_scalar.ijk.xyz,
                    @Vector(4, T){ 0, -1, -2, -3 },
                ),
            };
        }

        pub fn inverse(self: *const Self) Self {
            return Self{
                .rijk = self.rijk * Vec4{ 1.0, -1.0, -1.0, -1.0 },
            };
        }

        // pub fn add(self: *const Self, other: Self) Self {
        //     return self.rijk + other.rijk;
        // }

        // https://en.wikipedia.org/wiki/Selfs_and_spatial_rotation
        pub fn mul(self: *const Self, other: Self) Self {
            const q1 = self.toRealImag();
            const q2 = other.toRealImag();

            const result = RealImag{
                .r = q1.r * q2.r - q1.ijk.dot(q2.ijk),
                .ijk = Vector3(T).createScalar(q1.r).mul(q2.ijk).add(Vector3(T).createScalar(q2.r).mul(q1.ijk)).add(q1.ijk.cross(q2.ijk)),
            };
            return fromRealImag(result);
        }

        pub fn rotateVector(self: *const Self, vec: Vector3(T)) Vector3(T) {
            const result = self.mul(fromVector(vec)).mul(self.inverse());

            return result.toRealImag().ijk;
        }

        pub fn approxEqAbs(self: *const Self, other: Self, tolerance: T) bool {
            return std.math.approxEqAbs(T, self.r(), other.r(), tolerance) and
                std.math.approxEqAbs(T, self.i(), other.i(), tolerance) and
                std.math.approxEqAbs(T, self.j(), other.j(), tolerance) and
                std.math.approxEqAbs(T, self.k(), other.k(), tolerance);
        }

        pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt; // autofix
            _ = options;

            try std.fmt.format(writer, "Self{{{d: >12.6}, {d: >12.6}, {d: >12.6}, {d: >12.6}}}", .{ self.r(), self.i(), self.j(), self.k() });
        }
    };
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "to and from RealImag" {
    const quaternion = Quaternion(f32).create(1, 2, 3, 4);
    const vec_scalar = quaternion.toRealImag();
    try expectEqual(
        1,
        vec_scalar.r,
    );
    try expectEqual(Vector3(f32).create(2, 3, 4), vec_scalar.ijk);

    const recovered = Quaternion(f32).fromRealImag(vec_scalar);

    try expectEqual(quaternion, recovered);
}

test "1*1" {
    const q1 = Quaternion(f32).create(1, 0, 0, 0);
    const q2 = Quaternion(f32).create(1, 0, 0, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        1,
        0,
        0,
        0,
    ), 0.001));
}

test "1 * (i+j+k)" {
    const q1 = Quaternion(f32).create(1, 0, 0, 0);
    const q2 = Quaternion(f32).create(0, 1, 1, 1);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        0,
        1,
        1,
        1,
    ), 0.001));
}

test "i*i" {
    const q1 = Quaternion(f32).create(0, 1, 0, 0);
    const q2 = Quaternion(f32).create(0, 1, 0, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        -1,
        0,
        0,
        0,
    ), 0.001));
}

test "j*j" {
    const q1 = Quaternion(f32).create(0, 0, 1, 0);
    const q2 = Quaternion(f32).create(0, 0, 1, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        -1,
        0,
        0,
        0,
    ), 0.001));
}

test "k*k" {
    const q1 = Quaternion(f32).create(0, 0, 0, 1);
    const q2 = Quaternion(f32).create(0, 0, 0, 1);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        -1,
        0,
        0,
        0,
    ), 0.001));
}

test "i*j" {
    const q1 = Quaternion(f32).create(0, 1, 0, 0);
    const q2 = Quaternion(f32).create(0, 0, 1, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        0,
        0,
        0,
        1,
    ), 0.001));
}

test "j*k" {
    const q1 = Quaternion(f32).create(0, 0, 1, 0);
    const q2 = Quaternion(f32).create(0, 0, 0, 1);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        0,
        1,
        0,
        0,
    ), 0.001));
}

test "k*i" {
    const q1 = Quaternion(f32).create(0, 0, 0, 1);
    const q2 = Quaternion(f32).create(0, 1, 0, 0);
    const result = q1.mul(q2);
    try expect(result.approxEqAbs(Quaternion(f32).create(
        0,
        0,
        1,
        0,
    ), 0.001));
}

test "inverse" {
    const quaternion = Quaternion(f32).create(0.5, 0.2, -0.7, 0.1);
    const result = quaternion.inverse();
    try expect(result.approxEqAbs(Quaternion(f32).create(
        0.5,
        -0.2,
        0.7,
        -0.1,
    ), 0.001));
}

test "rotate yaw" {
    const axis = Vector3(f32).create(0, 0, 1);
    const angle = std.math.tau * 0.25;
    const quaternion = Quaternion(f32).fromAxisAngle(axis, angle);

    const point = Vector3(f32).create(1, 0, 0);
    const expected = Vector3(f32).create(0, 1, 0);

    const result_quaternion = quaternion.rotateVector(point);
    try expect(result_quaternion.approxEqAbs(expected, 0.001));

    const result_vector = point.rotate(axis, angle);
    try expect(result_vector.approxEqAbs(expected, 0.001));
}

test "rotate pitch" {
    const axis = Vector3(f32).create(1, 0, 0);
    const angle = std.math.tau * 0.25;
    const quaternion = Quaternion(f32).fromAxisAngle(axis, angle);

    const point = Vector3(f32).create(0, 1, 0);
    const expected = Vector3(f32).create(0, 0, 1);

    const result_quaternion = quaternion.rotateVector(point);
    try expect(result_quaternion.approxEqAbs(expected, 0.001));

    const result_vector = point.rotate(axis, angle);
    try expect(result_vector.approxEqAbs(expected, 0.001));
}

test "rotate roll" {
    const axis = Vector3(f32).create(0, 1, 0);
    const angle = std.math.tau * 0.25;
    const quaternion = Quaternion(f32).fromAxisAngle(axis, angle);

    const point = Vector3(f32).create(1, 0, 0);
    const expected = Vector3(f32).create(0, 0, -1);

    const result_quaternion = quaternion.rotateVector(point);
    try expect(result_quaternion.approxEqAbs(expected, 0.001));

    const result_vector = point.rotate(axis, angle);
    try expect(result_vector.approxEqAbs(expected, 0.001));
}

test "rotate off axis" {
    const axis = Vector3(f32).create(1, 1, 1);
    const angle = std.math.tau * 0.87;
    const quaternion = Quaternion(f32).fromAxisAngle(axis, angle);

    const point = Vector3(f32).create(-1.79, 2.46, 0.88);

    const expected = point.rotate(axis, angle);
    const result = quaternion.rotateVector(point);
    // std.debug.print("expected: {}\n", .{expected});
    // std.debug.print("result: {}\n", .{result});
    try expect(result.approxEqAbs(expected, 0.001));
}

test "RollPitchYaw" {
    const point = Vector3(f32).create(0.0, 0.0, 1.0);

    const roll = std.math.tau / 8.0;
    const pitch = std.math.tau / 5.6;
    const yaw = std.math.tau / 2.7;
    const quaternion = Quaternion(f32).fromRollPitchYaw(roll, pitch, yaw);

    const result = quaternion.rotateVector(point);

    const expected = point
        .rotate(Vector3(f32).create(0, 1, 0), roll)
        .rotate(Vector3(f32).create(1, 0, 0), pitch)
        .rotate(Vector3(f32).create(0, 0, 1), yaw);

    try expect(result.approxAlignedAbs(expected, 0.001));
}
