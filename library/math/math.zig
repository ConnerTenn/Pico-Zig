pub const Vector2 = @import("vector2.zig").Vector2;
pub const Vector3 = @import("vector3.zig").Vector3;
pub const Vector4 = @import("vector4.zig").Vector4;
pub const Quaternion = @import("quaternion.zig").Quaternion;

comptime {
    _ = Vector2;
    _ = Vector3;
    _ = Vector4;
    _ = Quaternion;
}
