const std = @import("std");
const Io = std.Io;
const syscall = @import("rawz/syscall.zig");
const types = @import("rawz/types.zig");
const store = @import("store/vegosh.zig");
const vegosh = @import("vegosh");

var vegosh_table: store.Vegosh align(64) = std.mem.zeroes(store.Vegosh);

pub fn main() !void {
    const listener = try syscall.socket(.inet, .stream, .tcp);
    const addr_in = types.SockAddrIn{
        .port = types.htons(9000),
        .addr = 0,
    };
    const addr: types.SockAddr = @bitCast(addr_in);

    try syscall.bind(listener, &addr, @sizeOf(types.SockAddr));
    try syscall.listen(listener, 128);

    std.debug.print("echo server listening on :9000\n", .{});
    while (true) {
        const client = syscall.accept(listener, null, null) catch |err| {
            std.debug.print("accept error: {s}\n", .{@errorName(err)});
            continue;
        };
        std.debug.print("Accepted client fd: {}\n", .{client});
    }
}
