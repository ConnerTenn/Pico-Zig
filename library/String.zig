const std = @import("std");
const builtin = @import("builtin");

const pico = @import("../pico.zig");
const allocator = if (builtin.is_test) std.testing.allocator else pico.library.alloc.global_allocator;

const String = @This();
pub const Char = u8;

string: ?[:0]Char,

pub fn create(str: []const Char) String {
    const new_str = allocator.alloc(Char, str.len + 1) catch unreachable;

    @memcpy(new_str[0..str.len], str);
    new_str[str.len] = '\x00';

    return String{
        .string = new_str[0..str.len :0],
    };
}

pub fn destroy(self: *String) void {
    if (self.string) |string| {
        allocator.free(string);
        self.string = null;
    }
}

pub fn length(self: String) usize {
    return self.string.?.len;
}

pub fn getSlice(self: String) []Char {
    return self.string.?;
}

pub fn getSentinal(self: String) [:0]Char {
    return self.string.?;
}

pub fn concat(self: String, other: String) String {
    const new_str = std.mem.concatWithSentinel(allocator, Char, &[_][]const Char{ self.string.?, other.string.? }, '\x00') catch unreachable;

    return String{
        .string = new_str,
    };
}

pub fn equal(self: String, other: String) bool {
    return std.mem.eql(Char, self.string.?, other.string.?);
}

pub fn format(
    self: String,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print(self.string.?, .{});
}

const testing = std.testing;

test "Create string" {
    var str = String.create("abc");
    defer str.destroy();

    try testing.expect(str.string != null);
    try testing.expectEqual(3, str.length());
    try testing.expectEqualStrings("abc", str.getSlice());
}

test "Concat string" {
    var str1 = String.create("abc");
    defer str1.destroy();

    var str2 = String.create("def");
    defer str2.destroy();

    var str_combined = str1.concat(str2);
    defer str_combined.destroy();

    try testing.expect(str_combined.string != null);
    try testing.expectEqual(6, str_combined.length());
    try testing.expectEqualStrings("abcdef", str_combined.getSlice());
}

test "sentinals" {
    const src_str: [:0]const Char = "abc";

    var str = String.create(src_str);
    defer str.destroy();

    try testing.expect(str.string != null);
    try testing.expectEqual(3, str.length());
    try testing.expectEqualStrings(src_str, str.getSlice());
    try testing.expectEqualSentinel(Char, '\x00', src_str, str.getSentinal());
}
