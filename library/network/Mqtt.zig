const std = @import("std");

const pico = @import("../../pico.zig");
const csdk = pico.csdk;
const stdio = pico.stdio;
const network = pico.library.network;
const global_allocator = pico.library.alloc.global_allocator;

const Mqtt = @This();

mqtt_client: *csdk.mqtt_client_t,

client_id_topic: Topic,

active_topic: ?Topic,
active_message: ?MessageBuffer,

callbacks: ?Callbacks,

const QOS = enum(u8) {
    AtMostOnce = 0,
    AtLeastOnce = 1,
    ExactlyOnce = 2,
};

const Retain = enum(u8) {
    false = 0,
    true = 1,
};

pub const Callbacks = struct {
    ctx: ?*anyopaque,
    connected_callback: *const fn (ctx: ?*anyopaque) void,
    message_recv_callback: *const fn (ctx: ?*anyopaque, topic: Topic, message: []const u8) void,
};

pub const Topic = struct {
    topic: [:0]const u8,

    pub fn new(topic: [:0]const u8) Topic {
        return Topic{
            .topic = topic,
        };
    }

    pub fn initAlloc(topic: [*:0]const u8) !Topic {
        const topic_len = std.mem.len(topic);
        const topic_buffer = try global_allocator.alloc(u8, topic_len + 1);

        @memcpy(topic_buffer, topic);
        topic_buffer[topic_len] = 0; //Ensure sentinal termination

        return Topic.new(topic_buffer[0..topic_len :0]);
    }

    pub fn deinit(self: *Topic) void {
        global_allocator.free(self.topic);
    }

    pub fn length(self: *const Topic) usize {
        return self.topic.len;
    }

    pub fn getSlice(self: *const Topic) [:0]const u8 {
        return self.topic;
    }

    /// Creates a new allocated Topic.
    /// Remember to free this with .deinit()
    pub fn concat(self: *const Topic, other: *const Topic) !Topic {
        const self_length = self.length();
        const combined_len = self_length + other.length();
        const topic_buffer = try global_allocator.alloc(u8, combined_len + 1);

        @memcpy(topic_buffer[0..self_length], self.topic[0..]);
        @memcpy(topic_buffer[self_length..combined_len], other.topic[0..]);
        topic_buffer[combined_len] = 0; //Ensure sentinal termination

        return Topic.new(topic_buffer[0..combined_len :0]);
    }

    pub fn equal(self: *const Topic, other: *const Topic) bool {
        return std.mem.eql(u8, self.topic, other.topic);
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

pub fn new(client_id_topic: Topic) !Mqtt {
    const mqtt_client = csdk.mqtt_client_new() orelse {
        return error.FailedToCreateClient;
    };

    return Mqtt{
        .mqtt_client = mqtt_client,
        .client_id_topic = client_id_topic,
        .active_topic = null,
        .active_message = null,
        .callbacks = null,
    };
}

pub fn destroy(self: *Mqtt) void {
    // self.topic.
    if (self.topic) |topic| {
        global_allocator.free(topic);
    }
}

pub fn setCallbacks(self: *Mqtt, callbacks: Callbacks) void {
    self.callbacks = callbacks;
}

pub fn connect(self: *Mqtt, address: network.IpV4Addr, port: u16, disconnect_message: DisconnectMessage) !void {
    network.enterCriticalSection();
    defer network.exitCriticalSection();

    const client_info = csdk.mqtt_connect_client_info_t{
        .client_id = self.client_id_topic.getSlice(),
        // .client_user
        // .client_pass
        .keep_alive = 10, //[sec]
        .will_topic = disconnect_message.topic.getSlice(),
        .will_msg = disconnect_message.message,
        .will_msg_len = 0,
        .will_qos = @intFromEnum(QOS.AtLeastOnce),
        .will_retain = @intFromEnum(Retain.true),
    };

    stdio.print("mqtt_client_connect\n", .{});
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
        "Failed to connect",
    )) {
        return error.FailedToConnect;
    }

    stdio.print("mqtt_set_inpub_callback\n", .{});
    csdk.mqtt_set_inpub_callback(self.mqtt_client, publishCallback, dataCallback, self);
}

pub fn connected(self: *Mqtt) bool {
    return csdk.mqtt_client_is_connected(self.mqtt_client) == 1;
}

pub fn subscribe(self: *Mqtt, topic: Topic, qos: QOS, prepend_client_id: bool) !void {
    var subscribe_topic = switch (prepend_client_id) {
        false => topic,
        true => try self.client_id_topic.concat(&topic),
    };
    defer if (prepend_client_id) {
        subscribe_topic.deinit();
    };

    stdio.print("subscribe to {s}\n", .{subscribe_topic.getSlice()});

    const err = csdk.mqtt_sub_unsub(self.mqtt_client, subscribe_topic.getSlice().ptr, @intFromEnum(qos), subRequestCallback, self, 1);

    if (network.hasError(
        err,
        "mqtt_sub_unsub() Failed",
    )) {
        return error.FailedToSubscribe;
    }
}

pub fn publish(self: *Mqtt, topic: Topic, message: []const u8, qos: QOS, retain: Retain, prepend_client_id: bool) !void {
    var publish_topic = switch (prepend_client_id) {
        false => topic,
        true => try self.client_id_topic.concat(&topic),
    };
    defer if (prepend_client_id) {
        publish_topic.deinit();
    };

    stdio.print("publish {s}<-\"{s}\"\n", .{ publish_topic.getSlice(), message });

    const err = csdk.mqtt_publish(self.mqtt_client, publish_topic.getSlice().ptr, message.ptr, @intCast(message.len), @intFromEnum(qos), @intFromEnum(retain), mqttPubRequestCallback, self);

    if (network.hasError(
        err,
        "mqtt_publish() failed",
    )) {
        return error.FailedToPublish;
    }
}

fn mqttConnectionCallback(client: ?*csdk.mqtt_client_t, arg: ?*anyopaque, status: csdk.mqtt_connection_status_t) callconv(.C) void {
    stdio.print("mqttConnectionCallback\n", .{});
    const self: *Mqtt = @alignCast(@ptrCast(arg.?));

    if (status != csdk.MQTT_CONNECT_ACCEPTED) {
        stdio.print("Failed to connect to mqtt: {s}\n", .{
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
    stdio.print("Connected to mqtt: {?}\n", .{client});

    // Call connected callback
    if (self.callbacks) |callbacks| {
        callbacks.connected_callback(callbacks.ctx);
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
        stdio.print("Error: active_topic must be initalized but it already exists", .{});
        unreachable;
    }

    if (self.active_message != null) {
        stdio.print("Error: active_message must be initalized but it already exists", .{});
        unreachable;
    }

    self.active_topic = Topic.initAlloc(topic) catch |err| {
        stdio.print("Failed to init active_topic: {?}", .{err});
        unreachable;
    };

    self.active_message = MessageBuffer.init(total_len) catch |err| {
        stdio.print("Failed to init active_message: {?}", .{err});
        unreachable;
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
                // Call message callback
                if (self.callbacks) |callbacks| {
                    callbacks.message_recv_callback(callbacks.ctx, active_topic.*, active_message.getSlice());
                }

                // reset active_topic
                active_topic.deinit();
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
