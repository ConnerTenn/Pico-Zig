const std = @import("std");
const math = std.math;
const testing = std.testing;

const pico = @import("../pico.zig");
const terminal = pico.library.terminal;

pub const Vector3 = pico.library.math.Vector3(f32);
pub const Vector4 = pico.library.math.Vector4(f32);

// Reference: https://en.wikipedia.org/wiki/HSL_and_HSV

pub const RGB = struct {
    /// Range: [0,1]
    red: f32,
    /// Range: [0,1]
    green: f32,
    /// Range: [0,1]
    blue: f32,

    pub fn create(red: f32, green: f32, blue: f32) RGB {
        return (RGB{
            .red = red,
            .green = green,
            .blue = blue,
        }).normalize();
    }

    pub fn normalize(self: RGB) RGB {
        return RGB{
            .red = @max(@min(self.red, 1.0), 0.0),
            .green = @max(@min(self.green, 1.0), 0.0),
            .blue = @max(@min(self.blue, 1.0), 0.0),
        };
    }

    inline fn getVec(self: RGB) Vector3 {
        return Vector3.create(self.red, self.green, self.blue);
    }

    inline fn fromVec(vec: Vector3) RGB {
        return RGB{
            .red = vec.w(),
            .green = vec.x(),
            .blue = vec.y(),
        };
    }

    pub fn add(self: RGB, other: RGB) RGB {
        return RGB.fromVec(self.getVec().add(other.getVec()));
    }

    pub fn sub(self: RGB, other: RGB) RGB {
        return RGB.fromVec(self.getVec().sub(other.getVec()));
    }

    pub fn mulScalar(self: RGB, scalar: f32) RGB {
        return RGB.fromVec(self.getVec().mul(Vector3.createScalar(scalar)));
    }

    pub fn fromHSV(hsv: HSV) RGB {
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

    pub fn fromHSL(hsl: HSL) RGB {
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

    pub fn format(
        self: RGB,
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

test "rgb create" {
    const rgb = RGB.create(2.0, 0.5, 0.1);

    try testing.expectApproxEqAbs(1.0, rgb.red, 0.01);
    try testing.expectApproxEqAbs(0.5, rgb.green, 0.01);
    try testing.expectApproxEqAbs(0.1, rgb.blue, 0.01);
}

test "rgb from hsv" {
    const hsv = HSV.create(0.0, 1.0, 1.0);
    const rgb = RGB.fromHSV(hsv);

    try testing.expectApproxEqAbs(1.0, rgb.red, 0.01);
    try testing.expectApproxEqAbs(0.0, rgb.green, 0.01);
    try testing.expectApproxEqAbs(0.0, rgb.blue, 0.01);
}

test "rgb from hsl" {
    const hsl = HSL.create(0.0, 1.0, 0.5);
    const rgb = RGB.fromHSL(hsl);

    try testing.expectApproxEqAbs(1.0, rgb.red, 0.01);
    try testing.expectApproxEqAbs(0.0, rgb.green, 0.01);
    try testing.expectApproxEqAbs(0.0, rgb.blue, 0.01);
}

pub const HSV = struct {
    /// Range: [0,1]
    hue: f32,
    /// Range: [0,1]
    saturation: f32,
    /// Range: [0,1]
    value: f32,

    pub fn create(hue: f32, saturation: f32, value: f32) HSV {
        return (HSV{
            .hue = hue,
            .saturation = saturation,
            .value = value,
        }).normalize();
    }

    pub fn normalize(self: HSV) HSV {
        return HSV{
            .hue = pico.math.mod(f32, self.hue, 1.0, .euclidean),
            .saturation = @max(@min(self.saturation, 1.0), 0.0),
            .value = @max(@min(self.value, 1.0), 0.0),
        };
    }

    inline fn getVec(self: HSV) Vector3 {
        return Vector3.create(self.hue, self.saturation, self.value);
    }

    inline fn fromVec(vec: Vector3) HSV {
        return HSV{
            .hue = vec.w(),
            .saturation = vec.x(),
            .value = vec.y(),
        };
    }

    pub fn add(self: HSV, other: HSV) HSV {
        return HSV.fromVec(self.getVec().add(other.getVec()));
    }

    pub fn sub(self: HSV, other: HSV) HSV {
        return HSV.fromVec(self.getVec().sub(other.getVec()));
    }

    pub fn mulScalar(self: HSV, scalar: f32) HSV {
        return HSV.fromVec(self.getVec().mul(Vector3.createScalar(scalar)));
    }

    pub fn fromRGB(rgb: RGB) HSV {
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

    pub fn fromHSL(hsl: HSL) HSV {
        const value = hsl.lightness + hsl.saturation * @min(hsl.lightness, 1 - hsl.lightness);

        var saturation: f32 = 0.0;
        if (value != 0.0) {
            saturation = 2.0 * (1.0 - hsl.lightness / value);
        }

        return create(hsl.hue, saturation, value);
    }
};

test "hsv create" {
    const hsv = HSV.create(2.0, 0.5, 0.3);

    try testing.expectApproxEqAbs(0.0, hsv.hue, 0.01);
    try testing.expectApproxEqAbs(0.5, hsv.saturation, 0.01);
    try testing.expectApproxEqAbs(0.3, hsv.value, 0.01);
}

test "hsv from rgb" {
    const rgb = RGB.create(1.0, 0.0, 0.0);
    const hsv = HSV.fromRGB(rgb);

    try testing.expectApproxEqAbs(0.0, hsv.hue, 0.01);
    try testing.expectApproxEqAbs(1.0, hsv.saturation, 0.01);
    try testing.expectApproxEqAbs(1.0, hsv.value, 0.01);
}

test "hsv from hsl" {
    const hsl = HSL.create(1.0, 1.0, 0.5);
    const hsv = HSV.fromHSL(hsl);

    try testing.expectApproxEqAbs(0.0, hsv.hue, 0.01);
    try testing.expectApproxEqAbs(1.0, hsv.saturation, 0.01);
    try testing.expectApproxEqAbs(1.0, hsv.value, 0.01);
}

pub const HSL = struct {
    /// Range: [0,1]
    hue: f32,
    /// Range: [0,1]
    saturation: f32,
    /// Range: [0,1]
    lightness: f32,

    pub fn create(hue: f32, saturation: f32, lightness: f32) HSL {
        return (HSL{
            .hue = hue,
            .saturation = saturation,
            .lightness = lightness,
        }).normalize();
    }

    pub fn normalize(self: HSL) HSL {
        return HSL{
            .hue = pico.math.mod(f32, self.hue, 1.0, .euclidean),
            .saturation = @max(@min(self.saturation, 1.0), 0.0),
            .lightness = @max(@min(self.lightness, 1.0), 0.0),
        };
    }

    inline fn getVec(self: HSL) Vector3 {
        return Vector3.create(self.hue, self.saturation, self.lightness);
    }

    inline fn fromVec(vec: Vector3) HSL {
        return HSL{
            .hue = vec.w(),
            .saturation = vec.x(),
            .lightness = vec.y(),
        };
    }

    pub fn add(self: HSL, other: HSL) HSL {
        return HSL.fromVec(self.getVec().add(other.getVec()));
    }

    pub fn sub(self: HSL, other: HSL) HSL {
        return HSL.fromVec(self.getVec().sub(other.getVec()));
    }

    pub fn mulScalar(self: HSL, scalar: f32) HSL {
        return HSL.fromVec(self.getVec().mul(Vector3.createScalar(scalar)));
    }

    pub fn fromRGB(rgb: RGB) HSL {
        const rgb_max = @max(@max(rgb.red, rgb.green), rgb.blue);
        const rgb_min = @min(@min(rgb.red, rgb.green), rgb.blue);

        const value = rgb_max;
        const chroma = rgb_max - rgb_min;
        const lightness = (rgb_max + rgb_min) / 2.0;

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
        if (lightness != 0.0 and lightness != 1.0) {
            saturation = (value - lightness) / @min(lightness, 1 - lightness);
        }

        return create(hue, saturation, lightness);
    }

    pub fn fromHSV(hsv: HSV) HSL {
        const lightness = hsv.value * (1.0 - hsv.saturation / 2.0);

        var saturation: f32 = 0.0;
        if (lightness != 0.0 and lightness != 1.0) {
            saturation = (hsv.value - lightness) / @min(lightness, 1 - lightness);
        }

        return create(hsv.hue, saturation, lightness);
    }
};

test "hsl create" {
    const hsl = HSL.create(2.0, 0.5, 0.3);

    try testing.expectApproxEqAbs(0.0, hsl.hue, 0.01);
    try testing.expectApproxEqAbs(0.5, hsl.saturation, 0.01);
    try testing.expectApproxEqAbs(0.3, hsl.lightness, 0.01);
}

test "hsl from rgb" {
    const rgb = RGB.create(1.0, 0.0, 0.0);
    const hsl = HSL.fromRGB(rgb);

    try testing.expectApproxEqAbs(0.0, hsl.hue, 0.01);
    try testing.expectApproxEqAbs(1.0, hsl.saturation, 0.01);
    try testing.expectApproxEqAbs(0.5, hsl.lightness, 0.01);
}

test "hsl from hsv" {
    const hsv = HSV.create(1.0, 1.0, 1.0);
    const hsl = HSL.fromHSV(hsv);

    try testing.expectApproxEqAbs(0.0, hsl.hue, 0.01);
    try testing.expectApproxEqAbs(1.0, hsl.saturation, 0.01);
    try testing.expectApproxEqAbs(0.5, hsl.lightness, 0.01);
}

pub const RGBW = struct {
    rgb: RGB,
    white: f32,

    pub fn create(red: f32, green: f32, blue: f32, white: f32) RGBW {
        return (RGBW{
            .rgb = RGB{
                .red = red,
                .green = green,
                .blue = blue,
            },
            .white = white,
        }).normalize();
    }

    pub fn normalize(self: RGBW) RGBW {
        return RGBW{
            .rgb = self.rgb.normalize(),
            .white = @max(@min(self.white, 1.0), 0.0),
        };
    }

    inline fn getVec(self: RGBW) Vector4 {
        return Vector4.create(self.rgb.red, self.rgb.green, self.rgb.blue, self.white);
    }

    inline fn fromVec(vec: Vector4) RGBW {
        return RGBW{
            .rgb = RGB{
                .red = vec.w(),
                .green = vec.x(),
                .blue = vec.y(),
            },
            .white = vec.z(),
        };
    }

    pub fn add(self: RGBW, other: RGBW) RGBW {
        return RGBW.fromVec(self.getVec().add(other.getVec()));
    }

    pub fn sub(self: RGBW, other: RGBW) RGBW {
        return RGBW.fromVec(self.getVec().sub(other.getVec()));
    }

    pub fn mulScalar(self: RGBW, scalar: f32) RGBW {
        return RGBW.fromVec(self.getVec().mul(Vector4.createScalar(scalar)));
    }

    pub fn format(
        self: RGBW,
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

pub const HSVW = struct {
    hsv: HSV,
    white: f32,

    pub fn create(hue: f32, saturation: f32, value: f32, white: f32) HSVW {
        return (HSVW{
            .hsv = HSV{
                .hue = hue,
                .saturation = saturation,
                .value = value,
            },
            .white = white,
        }).normalize();
    }

    pub fn normalize(self: HSVW) HSVW {
        return HSVW{
            .hsv = self.hsv.normalize(),
            .white = @max(@min(self.white, 1.0), 0.0),
        };
    }

    inline fn getVec(self: HSVW) Vector4 {
        return Vector4.create(self.hsv.hue, self.hsv.saturation, self.hsv.value, self.white);
    }

    inline fn fromVec(vec: Vector4) HSVW {
        return HSVW{
            .hsv = HSV{
                .hue = vec.w(),
                .saturation = vec.x(),
                .value = vec.y(),
            },
            .white = vec.z(),
        };
    }

    pub fn add(self: HSVW, other: HSVW) HSVW {
        return HSVW.fromVec(self.getVec().add(other.getVec()));
    }

    pub fn sub(self: HSVW, other: HSVW) HSVW {
        return HSVW.fromVec(self.getVec().sub(other.getVec()));
    }

    pub fn mulScalar(self: HSVW, scalar: f32) HSVW {
        return HSVW.fromVec(self.getVec().mul(Vector4.createScalar(scalar)));
    }
};

pub const HSLW = struct {
    hsl: HSL,
    white: f32,

    pub fn create(hue: f32, saturation: f32, lightness: f32, white: f32) HSLW {
        return (HSLW{
            .hsl = HSL{
                .hue = hue,
                .saturation = saturation,
                .lightness = lightness,
            },
            .white = white,
        }).normalize();
    }

    pub fn normalize(self: HSLW) HSLW {
        return HSLW{
            .hsl = self.hsl.normalize(),
            .white = @max(@min(self.white, 1.0), 0.0),
        };
    }

    inline fn getVec(self: HSLW) Vector4 {
        return Vector4.create(self.hsl.hue, self.hsl.saturation, self.hsl.lightness, self.white);
    }

    inline fn fromVec(vec: Vector4) HSLW {
        return HSLW{
            .hsl = HSL{
                .hue = vec.w(),
                .saturation = vec.x(),
                .lightness = vec.y(),
            },
            .white = vec.z(),
        };
    }

    pub fn add(self: HSLW, other: HSLW) HSLW {
        return HSLW.fromVec(self.getVec().add(other.getVec()));
    }

    pub fn sub(self: HSLW, other: HSLW) HSLW {
        return HSLW.fromVec(self.getVec().sub(other.getVec()));
    }

    pub fn mulScalar(self: HSLW, scalar: f32) HSLW {
        return HSLW.fromVec(self.getVec().mul(Vector4.createScalar(scalar)));
    }
};
