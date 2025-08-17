const std = @import("std");

const pico = @import("../../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;

pub const TcpServer = @import("TcpServer.zig");

pub fn init() !void {
    if (csdk.cyw43_arch_init() != 0) {
        return error.FailedToInitialize;
    }
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
    ) != csdk.ERR_OK) {
        stdio.print("failed to connect.\n", .{});
        return error.FailedToConnect;
    } else {
        stdio.print("Connected.\n", .{});
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
