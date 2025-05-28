const std = @import("std");
const math = std.math;

const math3D = @import("math3D.zig");
const Vector = math3D.vector.Vector;

pub const Rotor = struct {
    const Self = @This();

    vector: Vector,
    angle: f32,

    pub fn create(vector: Vector, angle: f32) Self {
        return Self{
            .vector = vector,
            .angle = angle,
        };
    }

    /// The order of these operations is important and non-commutative
    ///
    /// Y-Forwards
    ///
    /// Z-Up
    pub fn fromRollPitchYaw(roll: f32, pitch: f32, yaw: f32) Self {
        const forward = Vector.create(0.0, 1.0, 0.0);

        // const roll_rotor = Rotor.create(Vector.create(0.0, 1.0, 0.0), roll);
        const pitch_rotor = Rotor.create(Vector.create(1.0, 0.0, 0.0), pitch);
        const yaw_rotor = Rotor.create(Vector.create(0.0, 0.0, 1.0), yaw);

        // Roll is inline with final rotor
        return Rotor.create(yaw_rotor.rotate(pitch_rotor.rotate(forward)), roll);
    }

    pub fn rotate(self: *const Self, other: Vector) Vector {
        // Perpendicular to the rotor and the other vector, and in the plane of rotation
        const perpendicular_in_rot_plane = self.vector.cross(other);
        // Inline with the other vector, but in the plane of rotation
        // This is essentially the other vector projected onto the rotation plane
        const inline_in_rot_plane = perpendicular_in_rot_plane.cross(self.vector);

        // The other vector projected onto the axis of rotation
        // This could also be achieved with a dot product
        const inline_on_rot_axis = other.sub(inline_in_rot_plane);

        //Scalar vectors for sin and cos
        const cos_vec = Vector.create_scalar(math.cos(self.angle));
        const sin_vec = Vector.create_scalar(math.sin(self.angle));

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
};

const expect = std.testing.expect;

test "Rotate a perpendicular vector" {
    const rotor = Rotor.create(Vector.create(0.0, 0.0, 1.0), math.tau / 4.0);
    const vec = Vector.create(1.0, 0.0, 0.0);

    const result = rotor.rotate(vec);
    std.debug.print("result: {}\n", .{result});

    try expect(result.dot(Vector.create(0, 1, 0)) > 0.999);
}

test "Rotate a mixed vector" {
    const rotor = Rotor.create(Vector.create(0.0, 0.0, 1.0), math.tau / 4.0);
    const vec = Vector.create(1.0, 1.0, 1.0);

    const result = rotor.rotate(vec);
    std.debug.print("result: {}\n", .{result});

    try expect(result.dot(Vector.create(-1.0, 1, 1.0)) > 0.999);
}
