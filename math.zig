const std = @import("std");
const math = std.math;

const pico = @import("pico.zig");
const stdio = pico.stdio;

/// T must be an unsigned integer.
/// Expects val to be in the domain [-1 : 1]
pub fn rescaleAsInt(T: anytype, val: f32, max_int: T) T {
    return @intFromFloat(@as(f32, @floatFromInt(max_int)) * (val + 1.0) / 2.0);
}

/// https://en.wikipedia.org/wiki/Modulo
pub const ModType = enum {
    builtin,

    /// "Truncated division" on Wikipedia.
    /// Range (-denominator, denominator)
    truncated,

    /// "Euclidean division" on Wikipedia.
    /// Range: [0, denominator)
    euclidean,

    /// "Floored division" on Wikipedia.
    /// Positive denominator Range: [0, denominator)
    /// Negative denominator Range: (-denominator, 0]
    floored,

    /// "Rounded division" on Wikipedia
    /// Range: (-denominator/2, denominator/2)
    rounded,

    /// Not shown on wikipedia. This is the modulo of the abs value.
    /// Range: [0, denominator)
    mirror_y_axis,
};

pub inline fn mod(T: type, numerator: T, denominator: T, comptime mod_type: ModType) T {
    switch (mod_type) {
        .builtin => {
            //Builtin mod seems to behave like euclidean when denominator>0 and like truncated when denominator<0
            return @mod(numerator, denominator);
        },

        .truncated => {
            // const quotient = @divTrunc(numerator, denominator);
            // const modulo = numerator - denominator * quotient;
            // return modulo;

            //Builtin mod seems to behave like truncated when denominator<0
            return @mod(numerator, -@abs(denominator));
        },

        .euclidean => {
            // const abs_denominator = @abs(denominator);
            // const quotient = @divFloor(numerator, abs_denominator);
            // const modulo = numerator - abs_denominator * quotient;
            // return modulo;

            //Builtin mod seems to behave like euclidean when denominator>0
            return @mod(numerator, @abs(denominator));
        },

        .floored => {
            const quotient = @divFloor(numerator, denominator);
            const modulo = numerator - denominator * quotient;
            return modulo;
        },

        .rounded => {
            const quotient = @round(numerator / denominator);
            const modulo = numerator - denominator * quotient;
            return modulo;
        },

        .mirror_y_axis => {
            return @mod(@abs(numerator), denominator);
        },
    }
}

/// Output domain: [-modulo/2, modulo/2].
/// Positive when measured > target.
/// Negative when measured < target.
pub fn deltaError(T: type, measured: T, target: T, modulo: T) T {
    // return (mod(T, measured - target + modulo / 2.0, modulo, .regular) catch 0) - modulo / 2.0;
    return mod(T, measured - target, modulo, .rounded);
}

pub fn demoModFunctions() void {
    inline for (comptime std.enums.values(ModType)) |mod_type| {
        stdio.print("== {s} ==\n", .{@tagName(mod_type)});
        stdio.print("Numerator, Modulo (+Denominator), Modulo (-Denominator)\n", .{});

        const range_lower = -2;
        const range_upper = 2;
        const multiplier = 10;
        const num_steps = (range_upper - range_lower) * multiplier;

        for (0..num_steps + 1) |numerator_idx| {
            const numerator: f32 = (@as(f32, @floatFromInt(numerator_idx)) / @as(f32, num_steps)) * (range_upper - range_lower) + range_lower;
            const modulo_positive = mod(f32, numerator, 1.0, mod_type);
            const modulo_negative = mod(f32, numerator, -1.0, mod_type);
            stdio.print("{d:.2}, {d:.2}, {d:.2}\n", .{ numerator, modulo_positive, modulo_negative });
        }

        stdio.print("\n", .{});
    }
}

// https://www.ronja-tutorials.com/post/047-invlerp_remap/
pub fn remap(T: type, value: T, orig_from: T, orig_to: T, target_from: T, target_to: T) T {
    return lerp(T, lerpInv(T, value, orig_from, orig_to), target_from, target_to);
}

pub fn lerp(T: type, value: T, from: T, to: T) T {
    return (@as(T, 1) - value) * from + value * to;
}

pub fn lerpInv(T: type, value: T, from: T, to: T) T {
    return (value - from) / (to - from);
}
