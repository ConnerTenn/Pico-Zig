const pico = @import("../pico.zig");
const hardware = pico.hardware;
const library = pico.library;
const WS2812 = library.WS2812;

pub fn LedStrip(num_leds: comptime_int) type {
    return struct {
        const Self = @This();

        dma: hardware.dma.Dma,
        ws2812: WS2812.WS2812,

        swap_buffer_A: [num_leds]WS2812.Pixel,
        swap_buffer_B: [num_leds]WS2812.Pixel,

        active_buffer: enum {
            buffer_A,
            buffer_B,
        } = .buffer_A,

        pub fn create(transmit_pin: hardware.gpio.Pin) !Self {
            return Self{
                .dma = try hardware.dma.Dma.create(),
                .ws2812 = try WS2812.WS2812.create(transmit_pin),
                .swap_buffer_A = .{WS2812.Pixel.create(0, 0, 0, 0)} ** num_leds,
                .swap_buffer_B = .{WS2812.Pixel.create(0, 0, 0, 0)} ** num_leds,
            };
        }

        pub fn init(self: *Self) void {
            self.ws2812.init();

            self.dma.config.setReadIncrement(true);
            self.dma.config.setWriteIncrement(false);
            self.dma.config.setTransferDataSize(.size_32);
            self.dma.config.setDataRequest(self.ws2812.transmit_pio.getDataRequestId(.tx));
            self.dma.setWriteAddr(&(self.ws2812.transmit_pio.pio_obj.*.txf[self.ws2812.transmit_pio.state_machine]), false);
        }

        pub fn swapBuffers(self: *Self) void {
            self.active_buffer = switch (self.active_buffer) {
                .buffer_A => .buffer_B,
                .buffer_B => .buffer_A,
            };
        }

        pub fn getFrontBuffer(self: *Self) []WS2812.Pixel {
            return switch (self.active_buffer) {
                .buffer_A => &self.swap_buffer_A,
                .buffer_B => &self.swap_buffer_B,
            };
        }

        pub fn getBackBuffer(self: *Self) []WS2812.Pixel {
            return switch (self.active_buffer) {
                .buffer_A => &self.swap_buffer_B,
                .buffer_B => &self.swap_buffer_A,
            };
        }

        pub fn render(self: *Self) void {
            const front_buffer = self.getFrontBuffer();
            self.dma.transferFromBufferNow(front_buffer.ptr, num_leds);
        }
    };
}
