const std = @import("std");
const math = std.math;

const pico = @import("../pico.zig");
const csdk = pico.csdk;
const hardware = pico.hardware;
const spi = hardware.spi;
const gpio = hardware.gpio;

pub const GU128x32 = struct {
    const Self = @This();

    spi: spi.SPI,
    cmd_data_pin: gpio.Pin,
    frame_pulse_pin: gpio.Pin,
    display_buffer: DisplayBuffer,

    pub fn create(
        sck_pin: gpio.Pin,
        tx_pin: gpio.Pin,
        rx_pin: gpio.Pin,
        cs_pin: gpio.Pin,
        cmd_data_pin: gpio.Pin,
        frame_pulse_pin: gpio.Pin,
        spi_hw: spi.SPI.SpiHw,
    ) Self {
        const min_cycle_time_ns = 80 * 2; //80 * 2;
        const baudrate_hz = math.pow(u32, 10, 9) / min_cycle_time_ns;
        return Self{
            .spi = spi.SPI.create(
                sck_pin,
                tx_pin,
                rx_pin,
                cs_pin,
                spi_hw,
                baudrate_hz,
                .idle_high,
                .second_edge,
            ),
            .cmd_data_pin = cmd_data_pin,
            .frame_pulse_pin = frame_pulse_pin,
            .display_buffer = DisplayBuffer.create(),
        };
    }

    pub fn init(self: *Self) void {
        self.display_buffer.clearDisplayBuffer();

        // == Initialize SPI ==
        self.spi.init();
        self.cmd_data_pin.init(.{
            .direction = .out,
        });

        // == Display initialization sequence ==
        // Clear the display
        self.writeCommand(DisplayClear{
            .byte1 = .{
                .reset_addresses = 1,
                .gram_area0_clear = 1,
                .gram_area1_clear = 1,
            },
        });
        csdk.sleep_ms(2);

        // Set all regions to GRAM
        for (0..8) |idx| {
            self.writeCommand(DisplayAreaSet{
                .byte1 = .{},
                .byte2 = .{
                    .area = @intCast(idx),
                },
                .byte3 = .{},
            });
        }

        // Set up the initial X and Y addresses
        self.writeCommand(pico.library.gu128x32.GU128x32.DataWriteXAddress{
            .byte1 = .{},
            .byte2 = .{
                .gram_x_addr = 0,
            },
        });
        self.writeCommand(pico.library.gu128x32.GU128x32.DataWriteYAddress{
            .byte1 = .{},
            .byte2 = .{
                .gram_y_addr = 0,
            },
        });
    }

    const WriteType = enum(u1) {
        command = 1,
        data = 0,
    };

    pub fn write(self: *Self, write_type: WriteType, data: u8) void {
        self.cmd_data_pin.put(write_type == .command);
        // pico.stdio.print("transmit: {X:0>2}\n", .{data});
        self.spi.write(1, [_]u8{data}, true);
    }

    pub const DisplayOnOff = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u2 = 0,
            layer_0: enum(u1) {
                inactive = 0,
                active = 1,
            },
            layer_1: enum(u1) {
                inactive = 0,
                active = 1,
            },
            reserved_1: u4 = 0b0010,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u2 = 0,
            xor_op: u1,
            and_op: u1,
            gram_invert: enum(u1) {
                normal = 0,
                invert = 1,
            },
            reserved_1: u1 = 0,
            gram_enable: enum(u1) {
                off = 0,
                on = 1,
            },
            reserved_2: u1 = 0,
        },
    };

    pub const BrightnessSet = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            brightness: u4,
            reserved_0: u4 = 0b0100,
        },
    };

    pub const DisplayClear = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reset_addresses: u1,
            reserved_0: u1 = 1,
            gram_area0_clear: u1,
            gram_area1_clear: u1,
            reserved_1: u4 = 0b0101,
        },
    };

    pub const DisplayAreaSet = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b01100010,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            area: u3,
            reserved_0: u5 = 0b00000,
        },

        byte3: packed struct {
            const write_type: WriteType = .data;

            reserved_0: u8 = 0b11111111,
        },
    };

    pub const DataWriteXAddress = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b01100100,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            gram_x_addr: u7,
            reserved_0: u1 = 0,
        },
    };

    pub const DataWriteYAddress = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b01100000,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            gram_y_addr: u4,
            reserved_0: u4 = 0b0000,
        },
    };

    pub const DataStartXAddress = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b01110000,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            x_addr: u8,
        },
    };

    pub const DataStartYAddress = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u1 = 0,
            shift: enum(u2) {
                shift_none = 0b00,
                shift_8_dots = 0b01,
                shift_1_dots = 0b10,
                shift_2_dots = 0b11,
            },
            ud: enum(u1) {
                scrolled_up = 1,
                scrolled_down = 0,
            },
            reserved_1: u4 = 0b1011,
        },
    };

    pub const AddressModeSet = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u1 = 0,
            increment_y: enum(u1) {
                fixed = 0b0,
                increment = 0b1,
            },
            increment_x: enum(u1) {
                fixed = 0b0,
                increment = 0b1,
            },
            reserved_1: u5 = 0b10000,
        },
    };

    pub const AddressRead = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b11010100,
        } = .{},
        byte2: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b00000000,
        } = .{},
        byte3: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b00000000,
        } = .{},
    };

    pub const DataWrite = struct {
        byte1: packed struct {
            const write_type: WriteType = .data;

            data: u8,
        },
    };

    pub fn writeCommand(self: *Self, cmd: anytype) void {
        const info = @typeInfo(@TypeOf(cmd));

        //Loop through each byte field in the command
        const fields = info.Struct.fields;
        inline for (fields) |field| {
            //Get the command byte
            const cmd_byte = @field(cmd, field.name);
            //Extract the data from the command byte
            const write_type = @TypeOf(cmd_byte).write_type;
            const data: u8 = @bitCast(cmd_byte);
            //Write over SPI
            self.write(write_type, data);
        }
    }

    pub fn render(self: *Self) void {
        // Set the write address back to 0
        self.writeCommand(pico.library.gu128x32.GU128x32.DataWriteXAddress{
            .byte1 = .{},
            .byte2 = .{
                .gram_x_addr = 0,
            },
        });

        // Go through the display buffer
        for (self.display_buffer.display_buffer, 0..) |line, line_idx| {

            // Advance to the next line
            self.writeCommand(pico.library.gu128x32.GU128x32.DataWriteYAddress{
                .byte1 = .{},
                .byte2 = .{
                    .gram_y_addr = @intCast(line_idx),
                },
            });

            for (line) |segment| {
                self.writeCommand(DataWrite{ .byte1 = .{
                    .data = segment,
                } });
            }
        }
    }
};

pub const DisplayBuffer = struct {
    const Self = @This();

    display_buffer: [4][128]u8 = undefined,

    pub fn create() Self {
        var self = Self{};

        self.clearDisplayBuffer();

        return self;
    }

    pub fn clearDisplayBuffer(self: *Self) void {
        // Clear the display buffer
        for (&self.display_buffer) |*line| {
            for (line) |*segment| {
                segment.* = 0;
            }
        }
    }

    /// Sets a pixel in the display buffer
    ///
    /// x: [0, 127]
    ///
    /// y: [0, 32]
    pub inline fn setPixel(self: *Self, x: u7, y: u5, pixel: bool) void {
        const line_idx: u2 = @intCast(y >> 3);
        const bit_pos: u3 = @truncate(y);

        const mask: u8 = ~(@as(u8, 1) << bit_pos);

        self.display_buffer[line_idx][x] = (self.display_buffer[line_idx][x] & mask) | (@as(u8, @intFromBool(pixel)) << bit_pos);
    }

    // The Bresenham Line Drawing Algorithm
    pub fn drawLine(self: *Self, x1: u7, y1: u5, x2: u7, y2: u5, pixel: bool) void {
        const x_min = @min(x1, x2);
        const x_max = @max(x1, x2);

        const y_min = @min(y1, y2);
        const y_max = @max(y1, y2);

        const dx: i16 = x_max - x_min;
        const dy: i16 = y_max - y_min;

        if (dy <= dx) {
            // Horizontal line

            var px = 2 * dy - dx;
            var y: i16 = y1;
            for (x_min..x_max + 1) |x| {
                setPixel(self, @intCast(x), @intCast(y), pixel);

                if (px < 0) {
                    px = px + 2 * dy;
                } else {
                    y += if (dy >= 0) 1 else -1;
                    px = px + 2 * (dy - dx);
                }
            }
        } else {
            //vertical line

            var py = 2 * dx - dy;
            var x: i16 = x1;
            for (y_min..y_max + 1) |y| {
                setPixel(self, @intCast(x), @intCast(y), pixel);

                if (py <= 0) {
                    py = py + 2 * dx;
                } else {
                    x += if (dx >= 0) 1 else -1;
                    py = py + 2 * (dx - dy);
                }
            }
        }
    }
};

const BitmapFont = [128]BitmapCharacter;
const BitmapCharacter = struct {
    data: [5]u8,
};
