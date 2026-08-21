const std = @import("std");
const Io = std.Io;
const blocking_server = @import("server/blocking.zig");
const vegosh = @import("store/vegosh.zig");
const clap = @import("clap");
const rawz = @import("rawz");
const types = rawz.types;

pub fn parseListenAddr(addr_str: []const u8) !types.SockAddrIn {
    const colon_idx = std.mem.lastIndexOfScalar(u8, addr_str, ':') orelse return error.InvalidAddr;
    const ip_str = addr_str[0..colon_idx];
    const port_str = addr_str[colon_idx + 1 ..];

    const port = try std.fmt.parseInt(u16, port_str, 10);

    var octets: [4]u8 = undefined;
    var it = std.mem.splitScalar(u8, ip_str, '.');
    var i: usize = 0;
    while (it.next()) |part| {
        if (i >= 4) return error.InvalidAddr;
        octets[i] = try std.fmt.parseInt(u8, part, 10);
        i += 1;
    }
    if (i != 4) return error.InvalidAddr;

    // Pack octets into a u32 so that, in memory, byte 0 == octets[0].
    // This matches network-byte-order layout on little-endian hosts (x86_64).
    const addr: u32 = @as(u32, octets[0]) |
        (@as(u32, octets[1]) << 8) |
        (@as(u32, octets[2]) << 16) |
        (@as(u32, octets[3]) << 24);

    return types.SockAddrIn{
        .port = types.htons(port),
        .addr = addr,
    };
}

pub fn main(init: std.process.Init) !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                Display this help and exit.
        \\-l, --load-factor <f64>   An option parameter, which takes a value.
        \\-p, --listen <str>        An option parameter, which takes a string.
        \\
    );
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});

    const load_factor: f64 = res.args.@"load-factor" orelse 0.75;
    const max_occupancy: u32 = @intFromFloat(load_factor * @as(f64, @floatFromInt(vegosh.TABLE_SIZE)));
    std.debug.print("max_occupancy = {d}\n", .{max_occupancy});

    const listen_str: []const u8 = res.args.listen orelse "0.0.0.0:9000";
    const addr_in = try parseListenAddr(listen_str);
    try blocking_server.startServer(addr_in, max_occupancy);
}
