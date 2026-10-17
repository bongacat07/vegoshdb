const std = @import("std");
const blocking_server = @import("server/blocking.zig");
const vegosh = @import("store/vegosh.zig");
const clap = @import("clap");
const rawz = @import("rawz");
const types = rawz.types;

const default_load_factor: f64 = 0.75;
const default_listen = "0.0.0.0:9000";

const help_param =
    "-h, --help                Print this help and exit.\n";

const load_factor_param = std.fmt.comptimePrint(
    "-l, --load-factor <f64>   Fraction of the table that may be occupied before " ++
        "the store refuses inserts. Must satisfy 0 < value < 1 (default: {d}).\n",
    .{default_load_factor},
);

const listen_param = std.fmt.comptimePrint(
    "-p, --listen <str>        IPv4 address and port as IP:PORT, e.g. 127.0.0.1:9000. " ++
        "Hostnames and IPv6 are not supported (default: {s}).\n",
    .{default_listen},
);

const params = clap.parseParamsComptime(help_param ++ load_factor_param ++ listen_param);

const usage_text = std.fmt.comptimePrint(
    \\Usage: vegosh [-l <f64>] [-p <str>]
    \\
    \\Defaults: listen {s}, load factor {d}
    \\
,
    .{ default_listen, default_load_factor },
);

pub fn parseListenAddr(addr_str: []const u8) !types.SockAddrIn {
    const colon_idx = std.mem.lastIndexOfScalar(u8, addr_str, ':') orelse
        return error.InvalidAddr;
    const ip_str = addr_str[0..colon_idx];
    const port_str = addr_str[colon_idx + 1 ..];

    const port = try std.fmt.parseInt(u16, port_str, 10);

    var octets: [4]u8 = undefined;
    var it = std.mem.splitScalar(u8, ip_str, '.');
    var i: usize = 0;
    while (it.next()) |part| : (i += 1) {
        if (i >= 4) return error.InvalidAddr;
        octets[i] = try std.fmt.parseInt(u8, part, 10);
    }
    if (i != 4) return error.InvalidAddr;

    const addr: u32 = @as(u32, octets[0]) |
        (@as(u32, octets[1]) << 8) |
        (@as(u32, octets[2]) << 16) |
        (@as(u32, octets[3]) << 24);

    return .{
        .port = types.htons(port),
        .addr = addr,
    };
}

pub fn main(init: std.process.Init) !void {
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        std.debug.print("{s}", .{usage_text});
        return;
    }

    const load_factor = res.args.@"load-factor" orelse default_load_factor;
    const max_occupancy: u32 = @intFromFloat(
        load_factor * @as(f64, @floatFromInt(vegosh.TABLE_SIZE)),
    );
    std.debug.print("max_occupancy = {d}\n", .{max_occupancy});

    const listen_str: []const u8 = res.args.listen orelse default_listen;
    const addr_in = try parseListenAddr(listen_str);
    try blocking_server.startServer(addr_in, max_occupancy);
}
