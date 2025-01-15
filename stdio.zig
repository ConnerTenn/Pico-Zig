const std = @import("std");
const pico = @import("pico.zig");
const csdk = pico.csdk;

fn writeFn(context: *const anyopaque, bytes: []const u8) anyerror!usize {
    _ = context; // autofix
    const len = csdk.stdio_put_string(bytes.ptr, @intCast(bytes.len), false, false);
    return @intCast(len);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(
        std.io.AnyWriter{
            .context = @ptrFromInt(std.math.maxInt(usize)), // Unused
            .writeFn = writeFn,
        },
        fmt,
        args,
    ) catch {};
}
