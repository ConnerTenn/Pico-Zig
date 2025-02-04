const pico = @import("../pico.zig");
const csdk = pico.csdk;

const hardware = pico.hardware;

pub const Pio = struct {
    const Self = @This();

    const DefaultConfigFn = fn (initial_pc: c_uint) callconv(.C) csdk.pio_sm_config;

    pub const Error = error{
        FailedToClaimStateMachine,
        FoundUnknownPIO,
    };

    program: *const csdk.pio_program_t,
    default_config_fn: *const DefaultConfigFn,

    pio_obj: csdk.PIO,
    state_machine: c_uint,

    initial_pc: c_uint,
    gpio_base: hardware.gpio.Pin,
    gpio_count: hardware.gpio.Pin.Count,

    pub fn create(program: *const csdk.pio_program_t, default_config_fn: *const DefaultConfigFn, gpio_base: hardware.gpio.Pin, gpio_count: hardware.gpio.Pin.Count) Error!Self {
        var state_machine: c_uint = undefined;
        var pio_obj: csdk.PIO = undefined;
        var initial_pc: c_uint = undefined;

        const success = csdk.pio_claim_free_sm_and_add_program_for_gpio_range(program, &pio_obj, &state_machine, &initial_pc, gpio_base.toSdkPin(), gpio_count, false);

        if (!success) {
            return error.FailedToClaimStateMachine;
        }

        pico.stdio.print("Found free PIO: {*}  SM: {}  PC: {}\n", .{ pio_obj, state_machine, initial_pc });

        //Configure the GPIO function of the pins
        for (gpio_base.toSdkPin()..gpio_base.toSdkPin() + gpio_count) |gpio_pin| {
            csdk.pio_gpio_init(pio_obj, gpio_pin);
        }

        const self = Self{
            .program = program,
            .default_config_fn = default_config_fn,
            .pio_obj = pio_obj,
            .state_machine = state_machine,
            .initial_pc = initial_pc,
            .gpio_base = gpio_base,
            .gpio_count = gpio_count,
        };

        return self;
    }

    pub fn setConsecutivePinDirs(self: *Self, gpio_base: hardware.gpio.Pin, gpio_count: hardware.gpio.Pin.Count, is_out: bool) void {
        _ = csdk.pio_sm_set_consecutive_pindirs(self.pio_obj, self.state_machine, gpio_base.toSdkPin(), gpio_count, is_out);
    }

    pub fn getDefaultConfig(self: *Self) PioConfig {
        return PioConfig{
            .pio_config = self.default_config_fn(self.initial_pc),
        };
    }

    pub fn init(self: *Self, config: PioConfig) void {
        _ = csdk.pio_sm_init(self.pio_obj, self.state_machine, self.initial_pc, &config.pio_config);
    }

    pub fn enable(self: *Self) void {
        csdk.pio_sm_set_enabled(self.pio_obj, self.state_machine, true);
    }

    pub fn putBlocking(self: *Self, data: u32) void {
        csdk.pio_sm_put_blocking(self.pio_obj, self.state_machine, data);
    }

    pub fn putNonBlocking(self: *Self, data: u32) void {
        csdk.pio_sm_put(self.pio_obj, self.state_machine, data);
    }

    pub fn getBlocking(self: *Self) u32 {
        return csdk.pio_sm_get_blocking(self.pio_obj, self.state_machine);
    }

    pub fn getNonBlocking(self: *Self) u32 {
        return csdk.pio_sm_get(self.pio_obj, self.state_machine);
    }

    pub fn getPC(self: *Self) u32 {
        return csdk.pio_sm_get_pc(self.pio_obj, self.state_machine) - self.initial_pc;
    }

    const FifoTyoe = enum {
        rx,
        tx,
    };

    pub fn getDataRequestId(self: *Self, fifo_type: FifoTyoe) u32 {
        return csdk.pio_get_dreq(
            self.pio_obj,
            self.state_machine,
            switch (fifo_type) {
                .rx => false,
                .tx => true,
            },
        );
    }
};

pub const PioConfig = struct {
    const Self = @This();

    pio_config: csdk.pio_sm_config,

    pub fn create() Self {
        return Self{
            .pio_config = csdk.pio_get_default_sm_config(),
        };
    }

    pub fn setOutPins(self: *Self, gpio_base: hardware.gpio.Pin, gpio_count: hardware.gpio.Pin.Count) void {
        csdk.sm_config_set_out_pins(&self.pio_config, gpio_base.toSdkPin(), gpio_count);
    }

    pub fn setInPins(self: *Self, gpio_base: hardware.gpio.Pin, gpio_count: hardware.gpio.Pin.Count) void {
        csdk.sm_config_set_in_pin_base(&self.pio_config, gpio_base.toSdkPin());
        csdk.sm_config_set_in_pin_count(&self.pio_config, gpio_count);
    }

    pub fn setSetPins(self: *Self, gpio_base: hardware.gpio.Pin, gpio_count: hardware.gpio.Pin.Count) void {
        csdk.sm_config_set_set_pins(&self.pio_config, gpio_base.toSdkPin(), gpio_count);
    }

    pub fn setSidesetPins(self: *Self, gpio_base: hardware.gpio.Pin) void {
        csdk.sm_config_set_sideset_pins(&self.pio_config, gpio_base.toSdkPin());
    }

    pub fn setJmpPin(self: *Self, gpio_num: hardware.gpio.Pin) void {
        csdk.sm_config_set_jmp_pin(&self.pio_config, gpio_num.toSdkPin());
    }

    pub fn setOutShift(self: *Self, shift_right: bool, autopull: bool, pull_threshold: u32) void {
        csdk.sm_config_set_out_shift(&self.pio_config, shift_right, autopull, pull_threshold);
    }

    pub fn setClockDiv(self: *Self, div: f32) void {
        csdk.sm_config_set_clkdiv(&self.pio_config, div);
    }

    const FifoConfig = enum(c_uint) {
        none = csdk.PIO_FIFO_JOIN_NONE,
        join_tx = csdk.PIO_FIFO_JOIN_TX,
        join_rx = csdk.PIO_FIFO_JOIN_RX,
    };

    pub fn setFifoJoin(self: *Self, config: FifoConfig) void {
        csdk.sm_config_set_fifo_join(&self.pio_config, @intFromEnum(config));
    }
};
