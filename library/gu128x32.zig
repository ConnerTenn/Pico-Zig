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

    pub fn create(sck_pin: gpio.Pin, tx_pin: gpio.Pin, rx_pin: gpio.Pin, cs_pin: gpio.Pin, cmd_data_pin: gpio.Pin, frame_pulse_pin: gpio.Pin, spi_hw: spi.SPI.SpiHw) Self {
        const min_cycle_time_ns = 80 * 2;
        const baudrate_hz = (10 ** 9) / min_cycle_time_ns;
        return Self{
            .spi = spi.SPI.create(sck_pin, tx_pin, rx_pin, cs_pin, spi_hw, baudrate_hz),
            .cmd_data_pin = cmd_data_pin,
            .frame_pulse_pin = frame_pulse_pin,
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

    const DisplayOnOff = struct {
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

    const BrightnessSet = packed struct {
        const write_type: WriteType = .command;

        brightness: u4,
        reserved_0: u4 = 0b0100,
    };

    const DisplayClear = packed struct {
        const write_type: WriteType = .command;

        hm: u1,
        reserved_0: u1 = 1,
        g0c: u1,
        g1c: u1,
        reserved_1: u4 = 0b0101,
    };

    const DisplayAreaSet = struct {
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

    const DataWriteXAddress = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b01100100,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            gram_x_addr: u8,
        },
    };

    const DataWriteYAddress = struct {
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

    const DataStartXAddress = struct {
        byte1: packed struct {
            const write_type: WriteType = .command;

            reserved_0: u8 = 0b01110000,
        },

        byte2: packed struct {
            const write_type: WriteType = .command;

            x_addr: u8,
        },
    };

    const DataStartYAddress = packed struct {
        const write_type: WriteType = .command;

        reserved_0: u1 = 0,
        s0: u1,
        s1: u1,
        ud: u1,
        reserved_1: u4 = 0b1011,
    };

    const AddressModeSet = packed struct {
        const write_type: WriteType = .command;

        reserved_0: u1 = 0,
        igy: u1,
        igx: u1,
        reserved_1: u5 = 0b10000,
    };

    const DataWrite = packed struct {
        const write_type: WriteType = .data;

        data: u8,
    };
};
