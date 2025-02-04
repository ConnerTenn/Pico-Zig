const pico = @import("../pico.zig");
const csdk = pico.csdk;

pub const Dma = struct {
    const Self = @This();

    channel: c_int,
    config: DmaConfig,

    pub fn create() Self {
        const dma_channel = csdk.dma_claim_unused_channel(true);

        return Self{
            .channel = dma_channel,
            .config = csdk.dma_channel_get_default_config(dma_channel),
        };
    }

    pub fn init(self: *Self, trigger: bool) void {
        csdk.dma_channel_set_config(self.channel, &self.config, trigger);
    }

    pub fn setReadAddr(self: *Self, read_addr: *const volatile anyopaque, trigger: bool) void {
        csdk.dma_channel_set_read_addr(self.channel, read_addr, trigger);
    }

    pub fn setWriteAddr(self: *Self, write_addr: *const volatile anyopaque, trigger: bool) void {
        csdk.dma_channel_set_write_addr(self.channel, write_addr, trigger);
    }

    const Irq = enum {
        irq0,
        irq1,
    };

    pub fn setIrqEnabled(self: *Self, enabled: bool, irq: Irq) void {
        switch (irq) {
            .irq0 => csdk.dma_channel_set_irq0_enabled(self.channel, enabled),
            .irq1 => csdk.dma_channel_set_irq1_enabled(self.channel, enabled),
        }
    }

    const DmaConfig = struct {
        config: csdk.dma_channel_config,

        pub fn setReadIncrement(self: *DmaConfig, increment: bool) void {
            csdk.channel_config_set_read_increment(&self.config, increment); //Increment enabled
        }

        pub fn setWriteIncrement(self: *DmaConfig, increment: bool) void {
            csdk.channel_config_set_write_increment(&self.config, increment); //Increment disabled
        }

        const DmaSize = enum(u8) {
            size_8 = csdk.DMA_SIZE_8,
            size_16 = csdk.DMA_SIZE_16,
            size_32 = csdk.DMA_SIZE_32,
        };

        pub fn setTransferDataSize(self: *DmaConfig, size: DmaSize) void {
            csdk.channel_config_set_transfer_data_size(&self.config, @intFromEnum(size));
        }

        pub fn setDataRequest(self: *DmaConfig, data_request: u32) void {
            csdk.channel_config_set_dreq(&self.config, data_request); //Data request register for PIO TX
        }

        pub fn setRing(self: *DmaConfig, write: bool, size_bits: u32) void {
            csdk.channel_config_set_ring(&self.config, write, size_bits);
        }

        pub fn setByteSwap(self: *DmaConfig, enable: bool) void {
            csdk.channel_config_set_bswap(&self.config, enable);
        }

        pub fn setEnable(self: *DmaConfig, enable: bool) void {
            csdk.channel_config_set_enable(&self.config, enable);
        }

        pub fn setSniffEnable(self: *DmaConfig, enable: bool) void {
            csdk.channel_config_set_sniff_enable(&self.config, enable);
        }

        pub fn setHighPriority(self: *DmaConfig, high_priority: bool) void {
            csdk.setHighPriority(&self.config, high_priority);
        }
    };
};
