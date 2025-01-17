const pico = @import("pico.zig");
const csdk = pico.csdk;

pub const Pio = struct {
    const Self = @This();

    const DefaultConfigFn = fn (initial_pc: c_uint) callconv(.C) csdk.pio_sm_config;

    program: *const csdk.pio_program_t,
    default_config_fn: DefaultConfigFn,

    pio_obj: csdk.PIO,
    state_machine: c_uint,

    initial_pc: c_uint,
    gpio_base: c_uint,
    gpio_count: c_uint,

    pub fn create(program: *const csdk.pio_program_t, default_config_fn: DefaultConfigFn, gpio_base: c_uint, gpio_count: c_uint) Self {
        var state_machine: c_uint = undefined;
        var pio_obj: csdk.PIO = undefined;
        var initial_pc: c_uint = undefined;
        _ = csdk.pio_claim_free_sm_and_add_program_for_gpio_range(program, &pio_obj, &state_machine, &initial_pc, gpio_base, gpio_count, true);

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

    pub fn setConsecutivePinDirs(self: *Self, gpio_base: pico.GpioNum, gpio_count: u8, is_out: bool) void {
        csdk.pio_sm_set_consecutive_pindirs(self.pio_obj, self.state_machine, gpio_base, gpio_count, is_out);
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

    pub fn setOutPins(self: *Self, gpio_base: pico.GpioNum, gpio_count: u8) void {
        csdk.sm_config_set_out_pins(&self.pio_config, gpio_base, gpio_count);
    }

    pub fn setInPins(self: *Self, gpio_base: pico.GpioNum, gpio_count: u8) void {
        csdk.sm_config_set_in_pin_base(&self.pio_config, gpio_base);
        csdk.sm_config_set_in_pin_count(&self.pio_config, gpio_count);
    }

    pub fn setSetPins(self: *Self, gpio_base: pico.GpioNum, gpio_count: u8) void {
        csdk.sm_config_set_set_pins(&self.pio_config, gpio_base, gpio_count);
    }

    pub fn setSidesetPins(self: *Self, gpio_base: pico.GpioNum) void {
        csdk.sm_config_set_sideset_pins(&self.pio_config, gpio_base);
    }

    pub fn setJmpPin(self: *Self, gpio_num: pico.GpioNum) void {
        csdk.sm_config_set_jmp_pin(&self.pio_config, gpio_num);
    }
};
