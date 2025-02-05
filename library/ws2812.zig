const pico = @import("../pico.zig");
const csdk = pico.csdk;
const hardware = pico.hardware;
const pio = hardware.pio;

const ws2812_pio = @cImport({
    @cInclude("ws2812.pio.h");
});

pub const WS2812 = struct {
    const Self = @This();

    transmit_pio: pio.Pio,

    pub fn create(transmit_pin: hardware.gpio.Pin) !Self {
        return Self{
            .transmit_pio = try pio.Pio.create(
                @ptrCast(&ws2812_pio.ws2812_program),
                @ptrCast(&ws2812_pio.ws2812_program_get_default_config),
                transmit_pin,
                @as(hardware.gpio.Pin.Count, 1),
            ),
        };
    }

    pub fn init(self: *Self) void {
        //Configure the pin direction
        self.transmit_pio.setConsecutivePinDirs(self.transmit_pio.gpio_base, self.transmit_pio.gpio_count, true);

        //Configure the state machine
        self.transmit_pio.config.setOutShift(false, true, 32);
        self.transmit_pio.config.setOutPins(self.transmit_pio.gpio_base, self.transmit_pio.gpio_count);
        self.transmit_pio.config.setSetPins(self.transmit_pio.gpio_base, self.transmit_pio.gpio_count);
        self.transmit_pio.config.setFifoJoin(.join_tx);

        const cyclesPerBit = 10.0; //10 cycles to complete the program (see source)
        const transmit_rate = 800000.0; //Bits per second
        const div = @as(f32, @floatFromInt(csdk.clock_get_hz(csdk.clk_sys))) / (transmit_rate * cyclesPerBit);
        self.transmit_pio.config.setClockDiv(div);

        //Start the state machine
        self.transmit_pio.init();
        self.transmit_pio.enable();
    }

    pub fn putPixel(self: *Self, pixel: Pixel) void {
        self.transmit_pio.putBlocking(pixel.raw);
    }
};

pub const Pixel = packed union {
    const Self = @This();

    raw: u32,

    rgbw: packed struct {
        //The MSB gets shifted out first
        //Order is Green, Red, Blue, White
        white: u8, //LSB
        blue: u8,
        red: u8,
        green: u8, //MSB
    },

    pub fn create(red: u8, blue: u8, green: u8, white: u8) Self {
        return Self{
            .rgbw = .{
                .white = white,
                .blue = blue,
                .red = red,
                .green = green,
            },
        };
    }

    pub fn fromRGB(rgb: pico.library.colour.RGB, white: f32) Self {
        return create(
            @intFromFloat(rgb.red * 255.0),
            @intFromFloat(rgb.green * 255.0),
            @intFromFloat(rgb.blue * 255.0),
            @intFromFloat(white * 255.0),
        );
    }
};
