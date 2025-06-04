const pico = @import("../pico.zig");
const csdk = pico.csdk;

pub fn getTime_us() u64 {
    const curr_time_us = csdk.time_us_64();
    return curr_time_us;
}

pub fn getTime_s() f32 {
    const time_us = getTime_us();
    const time_s: f32 = @as(f32, @floatFromInt(time_us)) / 1_000_000.0;
    return time_s;
}

pub fn sleep_us(delay_us: u64) void {
    csdk.sleep_us(delay_us);
}

pub fn sleep_ms(delay_ms: u64) void {
    sleep_us(delay_ms * 1000);
}
