const std = @import("std");
const math = std.math;

/// T must be an unsigned integer.
/// Expects val to be in the domain [-1 : 1]
pub fn rescaleAsInt(T: anytype, val: f32, max_int: T) T {
    return @intFromFloat(@as(f32, @floatFromInt(max_int)) * (val + 1.0) / 2.0);
}

/// https://en.wikipedia.org/wiki/Modulo
pub const ModType = enum {
    regular,
    mirror_y_axis,
    mirror_xy_axis,
};

pub inline fn mod(T: type, numerator: T, denominator: T, comptime mod_type: ModType) T {
    switch (mod_type) {
        .regular => {
            return math.mod(T, numerator, denominator) catch 0;
        },
        .mirror_y_axis => {
            const modulo = mod(T, numerator, denominator, .regular);

            //Check the sign of the original result
            if (numerator * denominator >= 0) {
                return modulo;
            } else {
                return denominator - modulo;
            }
        },
        .mirror_xy_axis => {
            const modulo = mod(T, numerator, denominator, .regular);

            //Check the sign of the original result
            if (numerator * denominator >= 0) {
                return modulo;
            } else {
                return modulo - denominator;
            }
        },
    }
}

/// Output domain: [-modulo/2, modulo/2].
/// Positive when measured > target.
/// Negative when measured < target.
pub fn deltaError(T: type, measured: T, target: T, modulo: T) T {
    return mod(T, measured - target + modulo / 2.0, modulo, .regular) - modulo / 2.0;
}
