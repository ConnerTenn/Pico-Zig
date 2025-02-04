const config = @import("config");

const pico = @import("../pico.zig");
const csdk = pico.csdk;

pub const Irq = switch (config.target) {
    .rp2040 => enum(u8) {
        timer_0 = csdk.TIMER_IRQ_0,
        timer_1 = csdk.TIMER_IRQ_1,
        timer_2 = csdk.TIMER_IRQ_2,
        timer_3 = csdk.TIMER_IRQ_3,
        pwm_wrap = csdk.PWM_IRQ_WRAP,
        usb_ctrl = csdk.USBCTRL_IRQ,
        xip = csdk.XIP_IRQ,
        pio0_0 = csdk.PIO0_IRQ_0,
        pio0_1 = csdk.PIO0_IRQ_1,
        pio1_0 = csdk.PIO1_IRQ_0,
        pio1_1 = csdk.PIO1_IRQ_1,
        dma_0 = csdk.DMA_IRQ_0,
        dma_1 = csdk.DMA_IRQ_1,
        io_bank0 = csdk.IO_IRQ_BANK0,
        io_qspi = csdk.IO_IRQ_QSPI,
        sio_proc0 = csdk.SIO_IRQ_PROC0,
        sio_proc1 = csdk.SIO_IRQ_PROC1,
        clocks = csdk.CLOCKS_IRQ,
        spi0 = csdk.SPI0_IRQ,
        spi1 = csdk.SPI1_IRQ,
        uart0 = csdk.UART0_IRQ,
        uart1 = csdk.UART1_IRQ,
        adc_fifo = csdk.ADC_IRQ_FIFO,
        i2c0 = csdk.I2C0_IRQ,
        i2c1 = csdk.I2C1_IRQ,
        rtc = csdk.RTC_IRQ,
    },
    .rp2040 => enum(u8) {
        timer0_0 = csdk.TIMER0_IRQ_0,
        timer0_1 = csdk.TIMER0_IRQ_1,
        timer0_2 = csdk.TIMER0_IRQ_2,
        timer0_3 = csdk.TIMER0_IRQ_3,
        timer1_0 = csdk.TIMER1_IRQ_0,
        timer1_1 = csdk.TIMER1_IRQ_1,
        timer1_2 = csdk.TIMER1_IRQ_2,
        timer1_3 = csdk.TIMER1_IRQ_3,
        pwm_wrap_0 = csdk.PWM_IRQ_WRAP_0,
        pwm_wrap_1 = csdk.PWM_IRQ_WRAP_1,
        dma_0 = csdk.DMA_IRQ_0,
        dma_1 = csdk.DMA_IRQ_1,
        dma_2 = csdk.DMA_IRQ_2,
        dma_3 = csdk.DMA_IRQ_3,
        usb_ctrl = csdk.USBCTRL_IRQ,
        pio0_0 = csdk.PIO0_IRQ_0,
        pio0_1 = csdk.PIO0_IRQ_1,
        pio1_0 = csdk.PIO1_IRQ_0,
        pio1_1 = csdk.PIO1_IRQ_1,
        pio2_0 = csdk.PIO2_IRQ_0,
        pio2_1 = csdk.PIO2_IRQ_1,
        io_bank0 = csdk.IO_IRQ_BANK0,
        io_bank0_ns = csdk.IO_IRQ_BANK0_NS,
        io_qspi = csdk.IO_IRQ_QSPI,
        io_qspi_ns = csdk.IO_IRQ_QSPI_NS,
        sio_fifo = csdk.SIO_IRQ_FIFO,
        sio_bell = csdk.SIO_IRQ_BELL,
        sio_fifo_ns = csdk.SIO_IRQ_FIFO_NS,
        sio_bell_ns = csdk.SIO_IRQ_BELL_NS,
        sio_mtime_cmp = csdk.SIO_IRQ_MTIMECMP,
        clocks = csdk.CLOCKS_IRQ,
        spi0 = csdk.SPI0_IRQ,
        spi1 = csdk.SPI1_IRQ,
        uart0 = csdk.UART0_IRQ,
        uart1 = csdk.UART1_IRQ,
        adc_fifo = csdk.ADC_IRQ_FIFO,
        i2c0 = csdk.I2C0_IRQ,
        i2c1 = csdk.I2C1_IRQ,
        otp = csdk.OTP_IRQ,
        trng = csdk.TRNG_IRQ,
        proc0_cti = csdk.PROC0_IRQ_CTI,
        proc1_cti = csdk.PROC1_IRQ_CTI,
        pll_sys = csdk.PLL_SYS_IRQ,
        pll_usb = csdk.PLL_USB_IRQ,
        powman_pow = csdk.POWMAN_IRQ_POW,
        powman_timer = csdk.POWMAN_IRQ_TIMER,
        spare_0 = csdk.SPARE_IRQ_0,
        spare_1 = csdk.SPARE_IRQ_1,
        spare_2 = csdk.SPARE_IRQ_2,
        spare_3 = csdk.SPARE_IRQ_3,
        spare_4 = csdk.SPARE_IRQ_4,
        spare_5 = csdk.SPARE_IRQ_5,
    },
};

pub const HandlerFn = *const fn () callconv(.C) void;

pub fn setHandler(irq: Irq, handler_fn: HandlerFn) void {
    csdk.irq_set_exclusive_handler(@intFromEnum(irq), handler_fn);
}

pub fn setEnabled(irq: Irq, enabled: bool) void {
    csdk.irq_set_enabled(@intFromEnum(irq), enabled);
}
