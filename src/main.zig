const std = @import("std");
const Io = std.Io;
const syscall = @import("rawz/syscall.zig");
const types = @import("rawz/types.zig");

pub fn main() !void {
    var read_buf: [1024]u8 = undefined;
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

        while (true) {
            const n = syscall.read(client, &read_buf) catch |err| {
                std.debug.print("read error: {s}\n", .{@errorName(err)});
                break;
            };
            if (n == 0) break;

            _ = syscall.write(client, read_buf[0..n]) catch |err| {
                std.debug.print("write error: {s}\n", .{@errorName(err)});
                break;
            };
        }
    }
}
