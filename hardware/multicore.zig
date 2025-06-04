const pico = @import("../pico.zig");
const csdk = pico.csdk;

pub const EntryFn = *const fn () void;
var core1EntryFn: ?EntryFn = undefined;

export fn core1Entry() void {
    if (core1EntryFn) |entryFn| {
        entryFn();
    }
}

pub fn launchCore1(entryFn: EntryFn) void {
    core1EntryFn = entryFn;
    csdk.multicore_launch_core1(core1Entry);
}
