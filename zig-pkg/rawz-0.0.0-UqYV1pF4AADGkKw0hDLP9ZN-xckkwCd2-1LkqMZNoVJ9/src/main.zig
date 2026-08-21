const std = @import("std");

const rawz = @import("root.zig");
const types = rawz.types;
const io = rawz.io;
const syscall = rawz.socket;
fn readn(fd: types.Fd, buf: []u8) !usize {
    var total: usize = 0;
    while (total < buf.len) {
        const n = io.read(fd, buf[total..]) catch |err| switch (err) {
            error.Interrupted => continue,
            else => return err,
        };
        if (n == 0) break;
        total += n;
    }
    return total;
}

fn writen(fd: types.Fd, buf: []const u8) !void {
    var total: usize = 0;
    while (total < buf.len) {
        const n = io.write(fd, buf[total..]) catch |err| switch (err) {
            error.Interrupted => continue,
            else => return err,
        };
        total += n;
    }
}

fn handleClient(client: types.Fd) void {
    defer io.close(client) catch {};
    var buf: [4096]u8 = undefined;

    while (true) {
        const n = io.read(client, &buf) catch |err| switch (err) {
            error.Interrupted => continue,
            else => {
                std.debug.print("read error: {s}\n", .{@errorName(err)});
                return;
            },
        };
        if (n == 0) return;
        writen(client, buf[0..n]) catch |err| {
            std.debug.print("write error: {s}\n", .{@errorName(err)});
            return;
        };
    }
}

pub fn main() !void {
    const listener = try syscall.socket(.inet, .stream, .tcp);
    defer io.close(listener) catch {};

    const addr_in = types.SockAddrIn{
        .port = types.htons(9000),
        .addr = 0,
    };
    var addr: types.SockAddr = @bitCast(addr_in);

    try syscall.bind(listener, &addr, @sizeOf(types.SockAddr));
    try syscall.listen(listener, 128);

    std.debug.print("echo server listening on :9000\n", .{});

    while (true) {
        const client = syscall.accept(listener, null, null) catch |err| {
            std.debug.print("accept error: {s}\n", .{@errorName(err)});
            continue;
        };
        std.debug.print("Accepted client fd: {}\n", .{client});
        handleClient(client);
    }
}
