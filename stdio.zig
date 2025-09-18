const std = @import("std");
const pico = @import("pico.zig");
const csdk = pico.csdk;
const terminal = pico.library.terminal;

pub fn init() void {
    _ = pico.csdk.stdio_init_all();
}

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

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    const label_style = terminal.bold ++ terminal.yellow;
    const message_style = terminal.reset ++ terminal.magenta;

    print(
        label_style ++ "Warning: " ++ message_style ++ fmt ++ terminal.reset,
        args,
    );
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    const label_style = terminal.bold ++ terminal.red;
    const message_style = terminal.reset ++ terminal.magenta;

    print(
        label_style ++ "Error: " ++ message_style ++ fmt ++ terminal.reset,
        args,
    );
}

pub fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    const label_style = terminal.bold ++ terminal.red;
    const message_style = terminal.reset ++ terminal.magenta;

    print(
        label_style ++ "Fatal: " ++ message_style ++ fmt ++ terminal.reset,
        args,
    );

    @trap();
}

pub fn trace(comptime fmt: []const u8, args: anytype) void {
    // const darker = terminal.Csi.Graphic.string(comptime self: Graphic);
    const lighter = comptime (terminal.Csi{ .graphic = .{ .colour = .{ .bright = true, .colour = .black } } }).string();
    const darker = comptime (terminal.Csi{ .graphic = .{ .colour = .{ .colour = .black } } }).string();
    const label_style = terminal.bold ++ darker;
    const message_style = terminal.reset ++ lighter;

    print(
        label_style ++ "Trace: " ++ message_style ++ fmt ++ terminal.reset,
        args,
    );
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
