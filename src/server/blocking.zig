const syscall = rawz.socket;
const types = rawz.types;
const syscall_io = rawz.io;
const std = @import("std");
const client = @import("connection.zig");
const parser = @import("../protocol/parser.zig");
const handler = @import("../protocol/handler.zig");
const store = @import("../store/vegosh.zig");

const rawz = @import("rawz");
var table: store.Vegosh align(64) = undefined;

pub fn startServer(
    addr_in: types.SockAddrIn,
    max_occupancy: u32,
) !void {
    store.Vegosh.init(&table, max_occupancy);

    const listener = try syscall.socket(.inet, .stream, .tcp);

    var addr: types.SockAddr = @bitCast(addr_in);

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
                    std.debug.print(
                        "parser error: {s}\n",
                        .{@errorName(err)},
                    );
                    break;
                },
            };

            handler.handleParseResult(&table, result, &conn) catch |err| {
                switch (err) {
                    error.InvalidMagic => {
                        syscall_io.close(client_fd) catch |errr| {
                            std.debug.print(
                                "close error: {s}\n",
                                .{@errorName(errr)},
                            );
                        };
                    },
                    else => {},
                }
                break;
            };
        }

        syscall_io.close(client_fd) catch |err| {
            std.debug.print(
                "close error: {s}\n",
                .{@errorName(err)},
            );
        };
    }
}
