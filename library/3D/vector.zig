const std = @import("std");
const math = std.math;

pub const Vector = struct {
    const Self = @This();
    pub const Vec3 = @Vector(3, f32);

    xyz: Vec3,

    pub fn create(x_val: f32, y_val: f32, z_val: f32) Self {
        return Self{
            .xyz = Vec3{ x_val, y_val, z_val },
        };
    }

    pub fn create_scalar(scalar: f32) Self {
        return Self{
            .xyz = @as(Vec3, @splat(scalar)),
        };
    }

    pub inline fn x(self: *const Self) f32 {
        return self.xyz[0];
    }

    pub inline fn y(self: *const Self) f32 {
        return self.xyz[1];
    }

    pub inline fn z(self: *const Self) f32 {
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

    pub fn dot(self: *const Self, other: Self) f32 {
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

        const self_yzx = @shuffle(f32, self.xyz, undefined, @Vector(3, i32){ 1, 2, 0 });
        const self_zxy = @shuffle(f32, self.xyz, undefined, @Vector(3, i32){ 2, 0, 1 });
        const other_yzx = @shuffle(f32, other.xyz, undefined, @Vector(3, i32){ 1, 2, 0 });
        const other_zxy = @shuffle(f32, other.xyz, undefined, @Vector(3, i32){ 2, 0, 1 });

        return Self{
            .xyz = self_yzx * other_zxy - self_zxy * other_yzx,
        };
    }

    pub fn length(self: *const Self) f32 {
        return @sqrt(self.dot(self));
    }

    pub fn normalize(self: *const Self) Self {
        const vec_length = self.length();
        return Self{
            .xyz = self.xyz / @as(Vec3, @splat(vec_length)),
        };
    }
};
