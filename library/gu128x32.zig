const pico = @import("../pico.zig");
const csdk = pico.csdk;
const hardware = pico.hardware;
const spi = hardware.spi;
const gpio = hardware.gpio;

pub const GU128x32 = struct {
    const Self = @This();

    spi: spi.SPI,
    cmd_data_pin: gpio.Gpio,
    frame_pulse_pin: gpio.Gpio,

    pub fn create(sck_pin: gpio.Pin, tx_pin: gpio.Pin, rx_pin: gpio.Pin, cs_pin: gpio.Pin, cmd_data_pin: gpio.Pin, frame_pulse_pin: gpio.Pin, spi_hw: spi.SPI.SpiHw) Self {
        const min_cycle_time_ns = 80 * 2;
        const baudrate_hz = (10 ** 9) / min_cycle_time_ns;
        return Self{
            .spi = spi.SPI.create(sck_pin, tx_pin, rx_pin, cs_pin, spi_hw, baudrate_hz),
            .cmd_data_pin = gpio.Gpio.create(cmd_data_pin),
            .frame_pulse_pin = gpio.Gpio.create(frame_pulse_pin),
        };
    }

    pub fn init(self: *Self) void {
        self.spi.init();
        self.cmd_data_pin.init(.{
            .direction = .out,
        });
    }

    const WriteType = enum(u1) {
        command = 1,
        data = 0,
    };

    pub fn write(self: *Self, write_type: WriteType, data: u8) void {
        self.cmd_data_pin.put(@intFromEnum(write_type));
        self.spi.writeReg(u8, data);
    }
};
