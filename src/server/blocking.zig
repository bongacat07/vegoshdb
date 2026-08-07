const syscall = @import("../rawz/syscall.zig");
const types = @import("../rawz/types.zig");
const std = @import("std");
const client = @import("connection.zig");
const parser = @import("../protocol/parser.zig");
pub fn startServer(addr_in: types.SockAddrIn) !void {
    const listener = try syscall.socket(.inet, .stream, .tcp);
    const addr: types.SockAddr = @bitCast(addr_in);

    try syscall.bind(listener, &addr, @sizeOf(types.SockAddr));
    try syscall.listen(listener, 128);

    std.debug.print("server listening\n", .{});

    while (true) {
        const client_fd = syscall.accept(listener, null, null) catch |err| {
            std.debug.print("accept error: {s}\n", .{@errorName(err)});
            continue;
        };

        std.debug.print("Accepted client fd: {}\n", .{client_fd});

        var conn = client.Connection.init(client_fd);

        while (true) {
            const result = parser.parse(&conn) catch |err| switch (err) {
                error.ConnectionClosed => break,
                else => {
                    std.debug.print("parser error: {s}\n", .{@errorName(err)});
                    break;
                },
            };
            _ = result;
        }

        try syscall.close(client_fd);
    }
}
