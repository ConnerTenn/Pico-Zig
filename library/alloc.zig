const std = @import("std");
const heap = std.heap;

pub const global_allocator = std.heap.c_allocator;
