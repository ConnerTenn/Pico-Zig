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

pub fn printBarGraph(size: comptime_int, value: f32, writer: anytype) !void {
    try writer.print("[", .{});
    for (0..size * 2 + 1) |i| {
        const idx = @as(i32, @intCast(i)) - size;
        const compare_val = @as(f32, @floatFromInt(idx)) / @as(f32, @floatFromInt(size));
        if (idx > 0) {
            try writer.print("{s}", .{if (compare_val <= value) "=" else " "});
        } else if (idx < 0) {
            try writer.print("{s}", .{if (compare_val >= value) "=" else " "});
        } else {
            try writer.print("|", .{});
        }
    }
    try writer.print("]", .{});
}

pub fn printPositionGraph(size: comptime_int, value: f32, lower: f32, upper: f32, writer: anytype) !void {
    try writer.print("[", .{});
    for (0..size) |i| {
        const compare_val = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(size));
        const step_size: f32 = 1.0 / @as(f32, @floatFromInt(size));

        //Convert to domain [0,1]
        const normalized_value = (value - lower) / (upper - lower);

        if (@abs(normalized_value - compare_val) < step_size) {
            try writer.print("|", .{});
        } else {
            try writer.print(" ", .{});
        }
    }
    try writer.print("]", .{});
}
