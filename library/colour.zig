const std = @import("std");
const math = std.math;

const pico = @import("../pico.zig");
const terminal = pico.library.terminal;

// Reference: https://en.wikipedia.org/wiki/HSL_and_HSV

pub const RGB = struct {
    const Self = @This();

    /// Range: [0,1]
    red: f32,
    /// Range: [0,1]
    green: f32,
    /// Range: [0,1]
    blue: f32,

    pub fn create(red: f32, green: f32, blue: f32) Self {
        return (Self{
            .red = red,
            .green = green,
            .blue = blue,
        }).normalize();
    }

    pub fn normalize(self: Self) Self {
        return Self{
            .red = @max(@min(self.red, 1.0), 0.0),
            .green = @max(@min(self.green, 1.0), 0.0),
            .blue = @max(@min(self.blue, 1.0), 0.0),
        };
    }

    pub fn fromHSV(hsv: HSV) Self {
        const hue_region: u8 = @intFromFloat(6.0 * hsv.hue);
        const chroma = hsv.value * hsv.saturation;
        const chroma_fade = chroma * (1.0 - @abs(pico.math.mod(f32, 6.0 * hsv.hue, 2.0, .euclidean) - 1.0));

        var rgb = switch (hue_region) {
            0 => create(chroma, chroma_fade, 0.0),
            1 => create(chroma_fade, chroma, 0.0),
            2 => create(0.0, chroma, chroma_fade),
            3 => create(0.0, chroma_fade, chroma),
            4 => create(chroma_fade, 0.0, chroma),
            5 => create(chroma, 0.0, chroma_fade),
            else => unreachable,
        };

        const value_compensation = hsv.value - chroma;
        rgb.red += value_compensation;
        rgb.green += value_compensation;
        rgb.blue += value_compensation;

        return rgb;
    }

    pub fn fromHSL(hsl: HSL) Self {
        const hue_region: u8 = @intFromFloat(6.0 * hsl.hue);
        const chroma = (1.0 - @abs(2.0 * hsl.lightness - 1.0)) * hsl.saturation;
        const chroma_fade = chroma * (1.0 - @abs(pico.math.mod(f32, 6.0 * hsl.hue, 2.0, .euclidean) - 1.0));

        return switch (hue_region) {
            0 => create(chroma, chroma_fade, 0.0),
            1 => create(chroma_fade, chroma, 0.0),
            2 => create(0.0, chroma, chroma_fade),
            3 => create(0.0, chroma_fade, chroma),
            4 => create(chroma_fade, 0.0, chroma),
            5 => create(chroma, 0.0, chroma_fade),
            else => unreachable,
        };
    }

    pub fn add(
        self: Self,
        other: Self,
    ) Self {
        return Self{
            .red = self.red + other.red,
            .green = self.green + other.green,
            .blue = self.blue + other.blue,
        };
    }

    pub fn sub(
        self: Self,
        other: Self,
    ) Self {
        return Self{
            .red = self.red - other.red,
            .green = self.green - other.green,
            .blue = self.blue - other.blue,
        };
    }

    pub fn mul(
        self: Self,
        other: Self,
    ) Self {
        return Self{
            .red = self.red * other.red,
            .green = self.green * other.green,
            .blue = self.blue * other.blue,
        };
    }

    pub fn div(
        self: Self,
        other: Self,
    ) Self {
        return Self{
            .red = self.red / other.red,
            .green = self.green / other.green,
            .blue = self.blue / other.blue,
        };
    }

    pub fn addScalar(
        self: Self,
        other: f32,
    ) Self {
        return Self{
            .red = self.red + other,
            .green = self.green + other,
            .blue = self.blue + other,
        };
    }

    pub fn mulScalar(
        self: Self,
        other: f32,
    ) Self {
        return Self{
            .red = self.red * other,
            .green = self.green * other,
            .blue = self.blue * other,
        };
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print(
            "RGB{{" ++
                terminal.red ++ "{d:<.6} " ++
                terminal.green ++ "{d:<.6} " ++
                terminal.blue ++ "{d:<.6}" ++
                terminal.reset ++ "}}",
            .{ self.red, self.green, self.blue },
        );
    }
};

pub const HSV = struct {
    const Self = @This();

    /// Range: [0, 1]
    hue: f32,
    ///Range: [0,1]
    saturation: f32,
    ///Range: [0,1]
    value: f32,

    pub fn create(hue: f32, saturation: f32, value: f32) Self {
        return Self{
            .hue = pico.math.mod(f32, hue, 1.0, .euclidean),
            .saturation = @max(@min(saturation, 1.0), 0.0),
            .value = @max(@min(value, 1.0), 0.0),
        };
    }

    pub fn fromRGB(rgb: RGB) Self {
        const rgb_max = @max(@max(rgb.red, rgb.green), rgb.blue);
        const rgb_min = @min(@min(rgb.red, rgb.green), rgb.blue);

        const value = rgb_max;
        const chroma = rgb_max - rgb_min;

        var hue: f32 = 0.0;
        if (chroma == 0.0) {
            hue = 0.0;
        } else if (value == rgb.red) {
            hue = (pico.math.mod(f32, (rgb.green - rgb.blue) / chroma, 6.0, .euclidean)) / 6.0;
        } else if (value == rgb.green) {
            hue = ((rgb.blue - rgb.red) / chroma + 2) / 6.0;
        } else if (value == rgb.blue) {
            hue = ((rgb.red - rgb.green) / chroma + 4) / 6.0;
        }

        var saturation: f32 = 0.0;
        if (value != 0.0) {
            saturation = chroma / value;
        }

        return create(hue, saturation, value);
    }

    pub fn fromHSL(hsl: HSL) Self {
        const value = hsl.lightness + hsl.saturation * @min(hsl.lightness, 1 - hsl.lightness);

        var saturation: f32 = 0.0;
        if (value != 0.0) {
            saturation = 2.0 * (1.0 - hsl.lightness / value);
        }

        return create(hsl.hue, saturation, value);
    }
};

pub const HSL = struct {
    const Self = @This();

    /// Range: [0, 1]
    hue: f32,
    ///Range: [0,1]
    saturation: f32,
    ///Range: [0,1]
    lightness: f32,

    pub fn create(hue: f32, saturation: f32, lightness: f32) Self {
        return Self{
            .hue = pico.math.mod(f32, hue, 1.0, .euclidean),
            .saturation = @max(@min(saturation, 1.0), 0.0),
            .lightness = @max(@min(lightness, 1.0), 0.0),
        };
    }

    pub fn fromRGB(rgb: RGB) Self {
        const rgb_max = @max(@max(rgb.red, rgb.green), rgb.blue);
        const rgb_min = @min(@min(rgb.red, rgb.green), rgb.blue);

        const value = rgb_max;
        const chroma = rgb_max - rgb_min;
        const lightness = (rgb_max + rgb_min) / 2.0;

        var hue = 0.0;
        if (chroma == 0.0) {
            hue = 0.0;
        } else if (value == rgb.red) {
            hue = (pico.math.mod(f32, (rgb.green - rgb.blue) / chroma, 6.0, .euclidean)) / 6.0;
        } else if (value == rgb.green) {
            hue = ((rgb.blue - rgb.red) / chroma + 2) / 6.0;
        } else if (value == rgb.blue) {
            hue = ((rgb.red - rgb.green) / chroma + 4) / 6.0;
        }

        var saturation: f32 = 0.0;
        if (lightness != 0.0 and lightness != 1.0) {
            saturation = (value - lightness) / @min(lightness, 1 - lightness);
        }

        return create(hue, saturation, value);
    }

    pub fn fromHSV(hsv: HSV) Self {
        const lightness = hsv.value * (1.0 - hsv.saturation / 2.0);

        var saturation: f32 = 0.0;
        if (lightness != 0.0 and lightness != 1.0) {
            saturation = (hsv.value - lightness) / @min(lightness, 1 - lightness);
        }

        return create(hsv.hue, saturation, lightness);
    }
};

pub const RGBW = struct {
    const Self = @This();
    rgb: RGB,
    white: f32,

    pub fn create(red: f32, green: f32, blue: f32, white: f32) Self {
        return (Self{
            .rgb = RGB{
                .red = red,
                .green = green,
                .blue = blue,
            },
            .white = white,
        }).normalize();
    }

    pub fn normalize(self: Self) Self {
        return Self{
            .rgb = self.rgb.normalize(),
            .white = @max(@min(self.white, 1.0), 0.0),
        };
    }

    pub fn add(
        self: Self,
        other: Self,
    ) Self {
        const rgb_result = self.rgb.add(other.rgb);
        return Self{
            .rgb = rgb_result,
            .white = self.white + other.white,
        };
    }

    pub fn sub(
        self: Self,
        other: Self,
    ) Self {
        const rgb_result = self.rgb.sub(other.rgb);
        return Self{
            .rgb = rgb_result,
            .white = self.white - other.white,
        };
    }

    pub fn mul(
        self: Self,
        other: Self,
    ) Self {
        const rgb_result = self.rgb.mul(other.rgb);
        return Self{
            .rgb = rgb_result,
            .white = self.white * other.white,
        };
    }

    pub fn div(
        self: Self,
        other: Self,
    ) Self {
        const rgb_result = self.rgb.div(other.rgb);
        return Self{
            .rgb = rgb_result,
            .white = self.white / other.white,
        };
    }

    pub fn addScalar(
        self: Self,
        other: f32,
    ) Self {
        const rgb_result = self.rgb.addScalar(other);
        return Self{
            .rgb = rgb_result,
            .white = self.white + other,
        };
    }

    pub fn mulScalar(
        self: Self,
        other: f32,
    ) Self {
        const rgb_result = self.rgb.mulScalar(other);
        return Self{
            .rgb = rgb_result,
            .white = self.white * other,
        };
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print(
            "RGBW{{" ++
                terminal.red ++ "{d:<.6} " ++
                terminal.green ++ "{d:<.6} " ++
                terminal.blue ++ "{d:<.6} " ++
                terminal.white ++ "{d:<.6}" ++
                terminal.reset ++ "}}",
            .{ self.rgb.red, self.rgb.green, self.rgb.blue, self.white },
        );
    }
};
