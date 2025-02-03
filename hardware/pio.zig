const pico = @import("../pico.zig");
const csdk = pico.csdk;

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
    gpio_base: pico.gpio.Pin,
    gpio_count: pico.gpio.Pin.Count,

    pub fn create(program: *const csdk.pio_program_t, default_config_fn: *const DefaultConfigFn, gpio_base: pico.gpio.Pin, gpio_count: pico.gpio.Pin.Count) Error!Self {
        var state_machine: c_uint = undefined;
        var pio_obj: csdk.PIO = undefined;
        var initial_pc: c_uint = undefined;

        const success = csdk.pio_claim_free_sm_and_add_program_for_gpio_range(program, &pio_obj, &state_machine, &initial_pc, gpio_base.toSdkPin(), gpio_count, false);

        //Configure the GPIO function of the pins
        for (gpio_base.toSdkPin()..gpio_base.toSdkPin() + gpio_count) |gpio_pin| {
            switch (pio_obj) {
                csdk.pio0_hw => {
                    csdk.gpio_set_function(gpio_pin, csdk.GPIO_FUNC_PIO0);
                },
                csdk.pio1_hw => {
                    csdk.gpio_set_function(gpio_pin, csdk.GPIO_FUNC_PIO1);
                },
                csdk.pio2_hw => {
                    csdk.gpio_set_function(gpio_pin, csdk.GPIO_FUNC_PIO2);
                },
                else => {
                    pico.stdio.print("Error: Unknown PIO {*}\n", .{pio_obj});
                    return error.FoundUnknownPIO;
                },
            }
        }

        if (!success) {
            return error.FailedToClaimStateMachine;
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

    pub fn setConsecutivePinDirs(self: *Self, gpio_base: pico.gpio.Pin, gpio_count: pico.gpio.Pin.Count, is_out: bool) void {
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
};

pub const PioConfig = struct {
    const Self = @This();

    pio_config: csdk.pio_sm_config,

    pub fn create() Self {
        return Self{
            .pio_config = csdk.pio_get_default_sm_config(),
        };
    }

    pub fn setOutPins(self: *Self, gpio_base: pico.gpio.Pin, gpio_count: pico.gpio.Pin.Count) void {
        csdk.sm_config_set_out_pins(&self.pio_config, gpio_base.toSdkPin(), gpio_count);
    }

    pub fn setInPins(self: *Self, gpio_base: pico.gpio.Pin, gpio_count: pico.gpio.Pin.Count) void {
        csdk.sm_config_set_in_pin_base(&self.pio_config, gpio_base.toSdkPin());
        csdk.sm_config_set_in_pin_count(&self.pio_config, gpio_count);
    }

    pub fn setSetPins(self: *Self, gpio_base: pico.gpio.Pin, gpio_count: pico.gpio.Pin.Count) void {
        csdk.sm_config_set_set_pins(&self.pio_config, gpio_base.toSdkPin(), gpio_count);
    }

    pub fn setSidesetPins(self: *Self, gpio_base: pico.gpio.Pin) void {
        csdk.sm_config_set_sideset_pins(&self.pio_config, gpio_base.toSdkPin());
    }

    pub fn setJmpPin(self: *Self, gpio_num: pico.gpio.Pin) void {
        csdk.sm_config_set_jmp_pin(&self.pio_config, gpio_num.toSdkPin());
    }
};
