const std = @import("std");
const Io = std.Io;
const syscall = @import("rawz/syscall.zig");
const types = @import("rawz/types.zig");
const store = @import("store/vegosh.zig");
const vegosh = @import("vegosh");

var vegosh_table: store.Vegosh align(64) = std.mem.zeroes(store.Vegosh);

pub fn main() !void {}
