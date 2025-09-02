pub const Vector2 = @import("Vector2.zig");
pub const Vector3 = @import("Vector3.zig");
pub const Quaternion = @import("Quaternion.zig");

comptime {
    _ = Vector2;
    _ = Vector3;
    _ = Quaternion;
}
