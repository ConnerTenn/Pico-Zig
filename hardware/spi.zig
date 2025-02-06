const std = @import("std");

const pico = @import("../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const hardware = pico.hardware;
const gpio = hardware.gpio;

pub const SPI = struct {
    const Self = @This();

    sck_pin: gpio.Pin,
    tx_pin: gpio.Pin,
    rx_pin: gpio.Pin,
    cs_pin: gpio.Gpio,
    hardware_spi: *csdk.spi_inst_t,
    baudrate_hz: u32,

    pub const SpiHw = enum {
        spi0,
        spi1,
    };

    pub fn create(sck_pin: gpio.Pin, tx_pin: gpio.Pin, rx_pin: gpio.Pin, cs_pin: gpio.Pin, spi_hw: SpiHw, baudrate_hz: u32) Self {
        const hardware_spi = switch (spi_hw) {
            .spi0 => csdk.spi0_hw,
            .spi1 => csdk.spi1_hw,
        };

        return Self{
            .sck_pin = sck_pin,
            .tx_pin = tx_pin,
            .rx_pin = rx_pin,
            .cs_pin = gpio.Gpio.create(cs_pin),
            .hardware_spi = @ptrCast(hardware_spi),
            .baudrate_hz = baudrate_hz,
        };
    }

    pub fn init(self: *Self) void {
        self.cs_pin.init(gpio.Gpio.Config{
            .direction = .out,
        });
        self.cs_pin.put(false);

        self.baudrate_hz = csdk.spi_init(self.hardware_spi, self.baudrate_hz);
        stdio.print("SPI baudrate:{}\n", .{self.baudrate_hz});
        csdk.gpio_set_function(self.sck_pin.toSdkPin(), csdk.GPIO_FUNC_SPI);
        csdk.gpio_set_function(self.tx_pin.toSdkPin(), csdk.GPIO_FUNC_SPI);
        csdk.gpio_set_function(self.rx_pin.toSdkPin(), csdk.GPIO_FUNC_SPI);
    }

    pub inline fn csSelect(self: Self) void {
        self.cs_pin.put(false);
    }

    pub inline fn csDeselect(self: Self) void {
        self.cs_pin.put(true);
    }

    pub fn readReg(self: Self, T: type) T {
        self.csSelect();

        const read_cmd = 0x80;
        const write_data = [_]u8{
            read_cmd | T.address,
            0,
        };
        var read_data: [2]u8 = .{0} ** 2;
        _ = csdk.spi_write_read_blocking(self.hardware_spi, &write_data, &read_data, 2);

        self.csDeselect();
        csdk.sleep_us(10);

        return @bitCast(read_data[1]);
    }

    pub fn writeReg(self: Self, T: type, data: T) void {
        self.csSelect();

        const write_cmd = 0x00;
        const write_data = [_]u8{
            write_cmd | T.address,
            @as(u8, @bitCast(data)),
        };
        _ = csdk.spi_write_blocking(self.hardware_spi, &write_data, 2);

        self.csDeselect();
        csdk.sleep_us(10);
    }
};
