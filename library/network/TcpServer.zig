const std = @import("std");

const pico = @import("../../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;

const IpV4Addr = pico.library.network.IpV4Addr;

const TcpServer = @This();

server_protocol_control_block: ?*csdk.struct_tcp_pcb,

pub fn new(address: IpV4Addr, port: u16) !TcpServer {
    // const self = try std.heap.c_allocator.create(TcpServer);

    const server_protocol_control_block = csdk.tcp_new_ip_type(csdk.IPADDR_TYPE_ANY) orelse {
        return error.FailedToCreateProtocolControlBlock;
    };

    const err = csdk.tcp_bind(
        server_protocol_control_block,
        &csdk.ip4_addr{
            .addr = address.combined,
        },
        port,
    );
    if (err != csdk.ERR_OK) {
        stdio.print("tcp_bind failed: {}\n", .{err});
        return error.FailedToBindToPort;
    }

    return TcpServer{
        .server_protocol_control_block = server_protocol_control_block,
    };
}

fn listener_callback(context: ?*anyopaque, new_protocol_control_block: [*c]csdk.struct_tcp_pcb, err: csdk.err_t) callconv(.C) csdk.err_t {
    _ = context;
    _ = err;

    stdio.print("Recieved connection from: {?}\n", .{IpV4Addr{ .combined = new_protocol_control_block.*.remote_ip.addr }});

    return csdk.ERR_OK;
}

pub fn set_listener(self: *TcpServer) !void {
    if (csdk.tcp_listen(self.server_protocol_control_block)) |new_protocol_control_block| {
        self.server_protocol_control_block = new_protocol_control_block;
    } else {
        _ = csdk.tcp_close(self.server_protocol_control_block);
        return error.FailedToListen;
    }

    csdk.tcp_arg(self.server_protocol_control_block, self);
    csdk.tcp_accept(self.server_protocol_control_block, listener_callback);
}

// pub fn open(self: TcpServer) !void {
//     if (!csdk.tcp_server_open(self.server_ptr)) {
//         csdk.tcp_server_result(self.server_ptr, -1);
//         return error.FailedToOpen;
//     }
// }
