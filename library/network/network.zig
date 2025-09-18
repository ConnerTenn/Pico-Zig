const std = @import("std");

const pico = @import("../../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const terminal = pico.library.terminal;

pub const TcpServer = @import("TcpServer.zig");
pub const mqtt = @import("mqtt.zig");

var initialized = false;
pub fn init() !void {
    if (!initialized) {
        if (csdk.cyw43_arch_init() != 0) {
            return error.FailedToInitialize;
        }
        initialized = true;
    }
}

pub fn enterCriticalSection() void {
    csdk.cyw43_arch_lwip_begin();
}

pub fn exitCriticalSection() void {
    csdk.cyw43_arch_lwip_end();
}

pub fn poll() void {
    csdk.cyw43_arch_poll();
}

pub fn waitForWork(delay_ms: u32) void {
    csdk.cyw43_arch_wait_for_work_until(csdk.make_timeout_time_ms(delay_ms));
}

pub fn hasError(err: csdk.err_t, comptime message: []const u8) bool {
    if (err != csdk.ERR_OK) {
        stdio.err(message ++ ": {s} ({})\n", .{
            switch (err) {
                csdk.ERR_MEM => "ERR_MEM",
                csdk.ERR_BUF => "ERR_BUF",
                csdk.ERR_TIMEOUT => "ERR_TIMEOUT",
                csdk.ERR_RTE => "ERR_RTE",
                csdk.ERR_INPROGRESS => "ERR_INPROGRESS",
                csdk.ERR_VAL => "ERR_VAL",
                csdk.ERR_WOULDBLOCK => "ERR_WOULDBLOCK",
                csdk.ERR_USE => "ERR_USE",
                csdk.ERR_ALREADY => "ERR_ALREADY",
                csdk.ERR_ISCONN => "ERR_ISCONN",
                csdk.ERR_CONN => "ERR_CONN",
                csdk.ERR_IF => "ERR_IF",
                csdk.ERR_ABRT => "ERR_ABRT",
                csdk.ERR_RST => "ERR_RST",
                csdk.ERR_CLSD => "ERR_CLSD",
                csdk.ERR_ARG => "ERR_ARG",
                else => "Unkown error value",
            },
            err,
        });
        return true;
    }
    return false;
}

pub fn connectToWifi(
    wifi_ssid: []const u8,
    wifi_password: []const u8,
    timeout: ?u32,
) !void {
    csdk.cyw43_arch_enable_sta_mode();

    stdio.print("Connecting to Wi-Fi...\n", .{});
    if (csdk.cyw43_arch_wifi_connect_timeout_ms(
        @ptrCast(wifi_ssid),
        @ptrCast(wifi_password),
        csdk.CYW43_AUTH_WPA2_AES_PSK,
        timeout orelse 30000,
    ) != csdk.PICO_OK) {
        return error.FailedToConnect;
    } else {
        stdio.print(terminal.green ++ "Connected!\n" ++ terminal.reset, .{});
    }
}

pub const IpV4Addr = packed union {
    parts: packed struct {
        part_3: u8,
        part_2: u8,
        part_1: u8,
        part_0: u8,
    },
    combined: u32,

    pub fn new(part_3: u8, part_2: u8, part_1: u8, part_0: u8) IpV4Addr {
        return IpV4Addr{
            .parts = .{
                .part_3 = part_3,
                .part_2 = part_2,
                .part_1 = part_1,
                .part_0 = part_0,
            },
        };
    }
};
