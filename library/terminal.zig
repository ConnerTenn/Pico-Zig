const std = @import("std");
const assert = std.debug.assert;

const Char = u8;
const String = []const Char;

pub const Csi = union(enum) {
    const csi: String = "\x1b[";

    cursor_position: struct {
        /// vertical
        ///
        /// Indexed starting from 1
        row: comptime_int = 1,

        /// horizontal
        ///
        /// Indexed starting from 1
        column: comptime_int = 1,

        fn string(comptime self: @This()) String {
            assert(self.row >= 1);
            assert(self.column >= 1);

            return std.fmt.comptimePrint("{};{}H", .{ self.row, self.column });
        }
    },

    graphic: Graphic,

    pub const Colour = struct {
        where: enum {
            foreground,
            background,
        } = .foreground,
        bright: bool = false,
        colour: enum {
            black,
            red,
            green,
            yellow,
            blue,
            magenta,
            cyan,
            white,

            fn string(comptime self: @This()) String {
                return switch (self) {
                    .black => "0",
                    .red => "1",
                    .green => "2",
                    .yellow => "3",
                    .blue => "4",
                    .magenta => "5",
                    .cyan => "6",
                    .white => "7",
                };
            }
        },

        fn string(comptime self: @This()) String {
            return switch (self.where) {
                .foreground => switch (self.bright) {
                    false => "3" ++ self.colour.string(),
                    true => "9" ++ self.colour.string(),
                },
                .background => switch (self.bright) {
                    false => "4" ++ self.colour.string(),
                    true => "10" ++ self.colour.string(),
                },
            };
        }
    };

    pub const Graphic = union(enum) {
        reset,
        bold,
        colour: Colour,

        pub fn string(comptime self: Graphic) String {
            return switch (self) {
                .reset => "0",
                .bold => "1",
                .colour => |colour_cfg| colour_cfg.string(),
            } ++ "m";
        }
    };

    pub fn string(comptime self: Csi) String {
        return csi ++ switch (self) {
            .cursor_position => |cursor_position| cursor_position.string(),
            .graphic => |graphic| graphic.string(),
        };
    }
};

pub fn colour(config: Csi.Colour) String {
    return config.string();
}

comptime {
    _ = (Csi{ .graphic = .{ .colour = .{ .where = .background, .bright = true, .colour = .cyan } } }).string();
    _ = (Csi{ .cursor_position = .{ .row = 1, .column = 1 } }).string();
    _ = colour(.{ .colour = .blue });
}

test "CSI" {
    assert(std.mem.eql(
        u8,
        (Csi{ .graphic = .{ .foreground = .{ .colour = .cyan } } }).string(),
        "\x1b[36m",
    ));
}
