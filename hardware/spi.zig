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
    cs_pin: gpio.Pin,
    hardware_spi: *csdk.spi_inst_t,
    baudrate_hz: u32,
    clock_polarity: ClockPolarity,
    clock_phase: ClockPhase,

    pub const SpiHw = enum {
        spi0,
        spi1,
    };

    pub const ClockPolarity = enum {
        idle_low,
        idle_high,
    };
    pub const ClockPhase = enum {
        first_edge,
        second_edge,
    };

    pub fn create(
        sck_pin: gpio.Pin,
        tx_pin: gpio.Pin,
        rx_pin: gpio.Pin,
        cs_pin: gpio.Pin,
        spi_hw: SpiHw,
        baudrate_hz: u32,
        clock_polarity: ClockPolarity,
        clock_phase: ClockPhase,
    ) Self {
        const hardware_spi = switch (spi_hw) {
            .spi0 => csdk.spi0_hw,
            .spi1 => csdk.spi1_hw,
        };

        return Self{
            .sck_pin = sck_pin,
            .tx_pin = tx_pin,
            .rx_pin = rx_pin,
            .cs_pin = cs_pin,
            .hardware_spi = @ptrCast(hardware_spi),
            .baudrate_hz = baudrate_hz,
            .clock_polarity = clock_polarity,
            .clock_phase = clock_phase,
        };
    }

    pub fn init(self: *Self) void {
        self.csDeselect();
        self.cs_pin.init(gpio.Pin.Config{
            .direction = .out,
        });

        self.baudrate_hz = csdk.spi_init(self.hardware_spi, self.baudrate_hz);

        csdk.spi_set_format(
            self.hardware_spi,
            8,
            switch (self.clock_polarity) {
                .idle_low => csdk.SPI_CPOL_0,
                .idle_high => csdk.SPI_CPOL_1,
            },
            switch (self.clock_phase) {
                .first_edge => csdk.SPI_CPHA_0,
                .second_edge => csdk.SPI_CPHA_1,
            },
            csdk.SPI_MSB_FIRST,
        );

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

    pub fn writeRead(self: Self, len: comptime_int, write_data: [len]u8, comptime drive_chip_select: bool) [len]u8 {
        if (drive_chip_select) {
            self.csSelect();
        }

        var read_data: [len]u8 = .{0} ** len;
        _ = csdk.spi_write_read_blocking(self.hardware_spi, &write_data, &read_data, len);

        if (drive_chip_select) {
            self.csDeselect();
        }
        // csdk.sleep_us(10);

        return read_data;
    }

    pub fn write(self: Self, len: comptime_int, write_data: [len]u8, comptime drive_chip_select: bool) void {
        if (drive_chip_select) {
            self.csSelect();
        }

        _ = csdk.spi_write_blocking(self.hardware_spi, &write_data, len);

        if (drive_chip_select) {
            self.csDeselect();
        }
        // csdk.sleep_us(10);
    }
};
