const pico = @import("../pico.zig");
const csdk = pico.csdk;

pub const ClockFrequencies = struct {
    pll_sys_khz: u32,
    pll_usb_khz: u32,
    rosc_khz: u32,
    clk_sys_khz: u32,
    clk_peri_khz: u32,
    clk_usb_khz: u32,
    clk_adc_khz: u32,
    // clk_rtc_khz: u32,
};

pub fn getClocks() ClockFrequencies {
    return ClockFrequencies{
        .pll_sys_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_PLL_SYS_CLKSRC_PRIMARY),
        .pll_usb_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_PLL_USB_CLKSRC_PRIMARY),
        .rosc_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_ROSC_CLKSRC),
        .clk_sys_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_CLK_SYS),
        .clk_peri_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_CLK_PERI),
        .clk_usb_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_CLK_USB),
        .clk_adc_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_CLK_ADC),
        // .clk_rtc_khz = csdk.frequency_count_khz(csdk.CLOCKS_FC0_SRC_VALUE_CLK_RTC),
    };
}
