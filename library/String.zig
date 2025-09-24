const std = @import("std");
const builtin = @import("builtin");

const pico = @import("../pico.zig");
const allocator = if (builtin.is_test) std.testing.allocator else pico.library.alloc.global_allocator;

const String = @This();
pub const Char = u8;
string: ?[]Char,

pub fn create(str: []const Char) String {
    const new_str = allocator.alloc(Char, str.len) catch unreachable;

    @memcpy(new_str, str);

    return String{
        .string = new_str,
    };
}

pub fn destroy(self: *String) void {
    if (self.string) |string| {
        allocator.free(string);
        self.string = null;
    }
}

pub fn len(self: String) usize {
    return self.string.?.len;
}

pub fn slice(self: String) []Char {
    return self.string.?;
}

pub fn concat(self: String, other: String) String {
    const new_str = std.mem.concat(allocator, Char, &[_][]const Char{ self.string.?, other.string.? }) catch unreachable;

    return String{
        .string = new_str,
    };
}

pub fn equal(self: String, other: String) bool {
    return std.mem.eql(Char, self.string.?, other.string.?);
}

const testing = std.testing;

test "Create string" {
    var str = String.create("abc");
    defer str.destroy();

    try testing.expect(str.string != null);
    try testing.expectEqualStrings("abc", str.slice());
}

test "Concat string" {
    var str1 = String.create("abc");
    defer str1.destroy();

    var str2 = String.create("def");
    defer str2.destroy();

    var str_combined = str1.concat(str2);
    defer str_combined.destroy();

    try testing.expect(str_combined.string != null);
    try testing.expectEqualStrings("abcdef", str_combined.slice());
}
