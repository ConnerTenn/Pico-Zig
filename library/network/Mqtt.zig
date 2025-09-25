const std = @import("std");

const pico = @import("../../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const network = pico.library.network;
const terminal = pico.library.terminal;
const String = pico.library.String;
const global_allocator = pico.library.alloc.global_allocator;

const Mqtt = @This();

client_id_topic: Topic,
mqtt_client: *csdk.mqtt_client_t,

active_topic: ?Topic,
active_message: ?MessageBuffer,

connected_callback: ?ConnectedCallback,
recv_callback: ?RecvCallback,
topic_callbacks: std.StringHashMap(TopicCallback),

const QOS = enum(u8) {
    AtMostOnce = 0,
    AtLeastOnce = 1,
    ExactlyOnce = 2,
};

const Retain = enum(u8) {
    false = 0,
    true = 1,
};

pub const ConnectedCallback = struct {
    ctx: ?*anyopaque,
    callback: *const fn (ctx: ?*anyopaque) void,
};
pub const RecvCallback = struct {
    ctx: ?*anyopaque,
    callback: *const fn (ctx: ?*anyopaque, topic: Topic, message: []const u8) void,
};
pub const TopicCallback = struct {
    ctx: ?*anyopaque,
    callbacck: *const fn (ctx: ?*anyopaque, message: []const u8) void,
};

pub fn create(client_id_topic: Topic) !Mqtt {
    const mqtt_client = csdk.mqtt_client_new() orelse {
        return error.FailedToCreateClient;
    };

    return Mqtt{
        .client_id_topic = client_id_topic,
        .mqtt_client = mqtt_client,
        .active_topic = null,
        .active_message = null,
        .connected_callback = null,
        .recv_callback = null,
        .topic_callbacks = std.StringHashMap(TopicCallback).init(pico.library.alloc.global_allocator),
    };
}

pub fn destroy(self: *Mqtt) void {
    // self.topic.
    if (self.topic) |topic| {
        global_allocator.free(topic);
    }
}

pub fn setConnectedCallback(self: *Mqtt, connected_callback: ConnectedCallback) void {
    self.connected_callback = connected_callback;
}

pub fn setRecvCallback(self: *Mqtt, recv_callback: ?RecvCallback) void {
    self.recv_callback = recv_callback;
}

pub fn connect(self: *Mqtt, address: network.IpV4Addr, port: u16, disconnect_message: DisconnectMessage) !void {
    network.enterCriticalSection();
    defer network.exitCriticalSection();

    const client_info = csdk.mqtt_connect_client_info_t{
        .client_id = self.client_id_topic.getSentinel(),
        // .client_user
        // .client_pass
        .keep_alive = 10, //[sec]
        .will_topic = disconnect_message.topic.getSentinel(),
        .will_msg = disconnect_message.message,
        .will_msg_len = 0,
        .will_qos = @intFromEnum(QOS.AtLeastOnce),
        .will_retain = @intFromEnum(Retain.true),
    };

    stdio.trace("Connect to MQTT\n", .{});
    if (network.hasError(
        csdk.mqtt_client_connect(
            self.mqtt_client,
            &csdk.ip4_addr{
                .addr = address.combined,
            },
            port,
            mqttConnectionCallback,
            self,
            &client_info,
        ),
        "Failed to connect to MQTT",
    )) {
        return error.FailedToConnect;
    }

    // stdio.print("mqtt_set_inpub_callback\n", .{});
    csdk.mqtt_set_inpub_callback(self.mqtt_client, publishCallback, dataCallback, self);
}

pub fn connected(self: *Mqtt) bool {
    return csdk.mqtt_client_is_connected(self.mqtt_client) == 1;
}

pub fn subscribe(self: *Mqtt, topic: Topic, qos: QOS, prepend_client_id: bool, topic_callback: ?TopicCallback) !void {
    var subscribe_topic = switch (prepend_client_id) {
        false => topic.clone(),
        true => self.client_id_topic.concat(topic),
    };
    defer subscribe_topic.destroy();

    stdio.print(terminal.magenta ++ "Subscribe" ++ terminal.reset ++ " to {s}\n", .{subscribe_topic});

    const err = csdk.mqtt_sub_unsub(self.mqtt_client, subscribe_topic.getSentinel().ptr, @intFromEnum(qos), subRequestCallback, self, 1);

    if (network.hasError(
        err,
        "mqtt_sub_unsub() Failed",
    )) {
        return error.FailedToSubscribe;
    }

    if (topic_callback) |callback| {
        // This will allocate new memory for the StringHashMap key
        // This leaks memory, but since we don't consider unsubscribing from topics this isn't detrimental
        try self.topic_callbacks.put(topic.clone().getSentinel(), callback);
    }
}

pub fn publish(self: *Mqtt, topic: Topic, message: []const u8, qos: QOS, retain: Retain, prepend_client_id: bool) !void {
    var publish_topic = switch (prepend_client_id) {
        false => topic.clone(),
        true => self.client_id_topic.concat(topic),
    };
    defer publish_topic.destroy();

    stdio.print(
        terminal.magenta ++ "Publish" ++ terminal.reset ++ " {} <- \"" ++ terminal.bold ++ "{s}" ++ terminal.reset ++ "\"\n",
        .{ publish_topic, message },
    );

    const err = csdk.mqtt_publish(self.mqtt_client, publish_topic.getSentinel().ptr, message.ptr, @intCast(message.len), @intFromEnum(qos), @intFromEnum(retain), mqttPubRequestCallback, self);

    if (network.hasError(
        err,
        "mqtt_publish() failed",
    )) {
        return error.FailedToPublish;
    }
}

fn mqttConnectionCallback(client: ?*csdk.mqtt_client_t, arg: ?*anyopaque, status: csdk.mqtt_connection_status_t) callconv(.C) void {
    _ = client;
    // stdio.print("mqttConnectionCallback\n", .{});
    const self: *Mqtt = @alignCast(@ptrCast(arg.?));

    if (status != csdk.MQTT_CONNECT_ACCEPTED) {
        stdio.err("Failed to connect to mqtt: {s}\n", .{
            switch (status) {
                csdk.MQTT_CONNECT_REFUSED_PROTOCOL_VERSION => "MQTT_CONNECT_REFUSED_PROTOCOL_VERSION",
                csdk.MQTT_CONNECT_REFUSED_IDENTIFIER => "MQTT_CONNECT_REFUSED_IDENTIFIER",
                csdk.MQTT_CONNECT_REFUSED_SERVER => "MQTT_CONNECT_REFUSED_SERVER",
                csdk.MQTT_CONNECT_REFUSED_USERNAME_PASS => "MQTT_CONNECT_REFUSED_USERNAME_PASS",
                csdk.MQTT_CONNECT_REFUSED_NOT_AUTHORIZED_ => "MQTT_CONNECT_REFUSED_NOT_AUTHORIZED_",
                csdk.MQTT_CONNECT_DISCONNECTED => "MQTT_CONNECT_DISCONNECTED",
                csdk.MQTT_CONNECT_TIMEOUT => "MQTT_CONNECT_TIMEOUT",
                else => "Unexpected Status",
            },
        });
        return;
    }
    stdio.print(terminal.green ++ "Connected to mqtt!\n" ++ terminal.reset, .{});

    // Call connected callback
    if (self.connected_callback) |connected_callback| {
        connected_callback.callback(connected_callback.ctx);
    }
}

fn mqttPubRequestCallback(arg: ?*anyopaque, err: csdk.err_t) callconv(.C) void {
    // stdio.print("mqttPubRequestCallback\n", .{});
    const self: *Mqtt = @alignCast(@ptrCast(arg.?));
    _ = self;

    _ = network.hasError(
        err,
        "mqttPubRequestCallback() Failed",
    );
}

fn subRequestCallback(arg: ?*anyopaque, err: csdk.err_t) callconv(.C) void {
    const self: *Mqtt = @alignCast(@ptrCast(arg.?));
    _ = self;

    _ = network.hasError(err, "Failed to subscribe");
}

fn publishCallback(arg: ?*anyopaque, topic: [*c]const u8, total_len: u32) callconv(.C) void {
    // stdio.print("publishCallback\n", .{});
    // stdio.print("  topic: {s}\n", .{topic});
    // stdio.print("  total_len: {}\n", .{total_len});
    const self: *Mqtt = @alignCast(@ptrCast(arg.?));

    if (self.active_topic != null) {
        stdio.fatal("recieved new active_topic but one already exists", .{});
    }

    if (self.active_message != null) {
        stdio.fatal("recieved new active_message but one already exists", .{});
    }

    self.active_topic = Topic.createFromCStr(topic) catch |err| {
        stdio.fatal("Failed to init active_topic: {?}", .{err});
    };

    self.active_message = MessageBuffer.init(total_len) catch |err| {
        stdio.fatal("Failed to init active_message: {?}", .{err});
    };
}

fn dataCallback(arg: ?*anyopaque, raw_data: [*c]const u8, len: u16, flags: u8) callconv(.C) void {
    // stdio.print("dataCallback\n", .{});
    const self: *Mqtt = @alignCast(@ptrCast(arg.?));

    const message: []const u8 = raw_data[0..len];

    // stdio.print("  recv datamessage: \"{s}\"\n", .{message});
    // stdio.print("  flags: {X:02}\n", .{flags});

    if (self.active_message) |*active_message| {
        active_message.appendSlice(message) catch |err| {
            stdio.print("Failed to append message: {}\n", .{err});
        };

        if (flags == csdk.MQTT_DATA_FLAG_LAST) {
            if (self.active_topic) |*active_topic| {
                stdio.print(
                    terminal.magenta ++ "Recv" ++ terminal.reset ++ " {} <- \"" ++ terminal.bold ++ "{s}" ++ terminal.reset ++ "\"\n",
                    .{ active_topic.*, active_message.getSlice() },
                );

                // Call message callback
                if (self.recv_callback) |recv_callback| {
                    recv_callback.callback(recv_callback.ctx, active_topic.*, active_message.getSlice());
                }

                if (self.topic_callbacks.get(active_topic.getSentinel())) |topic_callback| {
                    topic_callback.callbacck(topic_callback.ctx, active_message.getSlice());
                }

                // reset active_topic
                active_topic.destroy();
                self.active_topic = null;
            } else {
                stdio.print("Error: recieved data without topic\n", .{});
            }

            // reset active_message
            active_message.deinit();
            self.active_message = null;
        }
    } else {
        stdio.print("Error: recieved data before active_message was initalized\n", .{});
    }
}

pub const Topic = struct {
    string: String,

    pub fn create(topic: []const String.Char) Topic {
        return Topic{
            .string = String.create(topic),
        };
    }

    pub fn createFromCStr(topic: [*:0]const String.Char) !Topic {
        // Cannot use this for comptime expressions
        const in_comptime = @inComptime();
        comptime std.debug.assert(in_comptime == false);

        const topic_len = std.mem.len(topic);
        const topic_slice: [:0]const String.Char = topic[0..topic_len :0];

        return Topic.create(topic_slice);
    }

    pub fn clone(self: Topic) Topic {
        return Topic.create(self.string.getSlice());
    }

    pub fn destroy(self: *Topic) void {
        self.string.destroy();
    }

    pub fn length(self: Topic) usize {
        return self.string.length();
    }

    pub fn getSentinel(self: Topic) [:0]const u8 {
        return self.string.getSentinal();
    }

    pub fn concat(self: Topic, other: Topic) Topic {
        return Topic{
            .string = self.string.concat(other.string),
        };
    }

    pub fn equal(self: Topic, other: Topic) bool {
        return self.string.equal(other.string);
    }

    pub fn format(
        self: Topic,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("Topic{{" ++ terminal.green ++ "{s}" ++ terminal.reset ++ "}}", .{self.string});
    }
};

pub const MessageBuffer = struct {
    buffer: std.ArrayList(u8),

    pub fn init(len: usize) !MessageBuffer {
        return MessageBuffer{
            .buffer = try std.ArrayList(u8).initCapacity(global_allocator, len),
        };
    }

    pub fn deinit(self: *MessageBuffer) void {
        self.buffer.deinit();
    }

    pub fn appendSlice(self: *MessageBuffer, items: []const u8) !void {
        try self.buffer.appendSlice(items);
    }

    pub fn getSlice(self: *MessageBuffer) []const u8 {
        return self.buffer.items;
    }
};

/// The message to post when the client disconnects from the server
pub const DisconnectMessage = struct {
    topic: Topic,
    message: [:0]const u8,
};
