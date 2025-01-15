const std = @import("std");
const math = std.math;

pub fn rescaleAsInt(T: anytype, val: f32, max_int: T) T {
    //T must be an unsigned integer
    //Expects val to be in the domain [-1 : 1]
    return @intFromFloat(@as(f32, @floatFromInt(max_int)) * (val + 1.0) / 2.0);
}
