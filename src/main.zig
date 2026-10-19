const std = @import("std");
const blocking_server = @import("server/blocking.zig");
const vegosh = @import("store/vegosh.zig");
const clap = @import("clap");
const rawz = @import("rawz");
const types = rawz.types;

const default_load_factor: f64 = vegosh.MAX_LOAD_FACTOR;
const default_listen = "0.0.0.0:9000";

const LoadFactorError = error{
    NotFinite,
    TooLarge,
    NotPositive,
    OccupancyTooSmall,
};

/// Validates a load factor and returns the maximum number of occupied slots.
fn validateLoadFactor(load_factor: f64) LoadFactorError!u32 {
    if (!std.math.isFinite(load_factor)) return LoadFactorError.NotFinite;
    if (load_factor <= 0) return LoadFactorError.NotPositive;
    if (load_factor > vegosh.MAX_LOAD_FACTOR) return LoadFactorError.TooLarge;

    // Safe: 0 < load_factor <= MAX_LOAD_FACTOR, so the result fits in a u32.
    const max_occupancy: u32 = @intFromFloat(
        load_factor * @as(f64, @floatFromInt(vegosh.TABLE_SIZE)),
    );

    if (max_occupancy == 0) return LoadFactorError.OccupancyTooSmall;

    return max_occupancy;
}

const help_param =
    "-h, --help                Print this help and exit.\n";

const load_factor_param = std.fmt.comptimePrint(
    "-l, --load-factor <f64>   Fraction of the table that may be occupied before " ++
        "the store refuses inserts. Must satisfy 0 < value <= {d} (default: {d}).\n",
    .{ vegosh.MAX_LOAD_FACTOR, default_load_factor },
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

const ListenAddrError = error{
    InvalidFormat,
    InvalidIP,
    InvalidPort,
};

pub fn parseListenAddr(addr_str: []const u8) ListenAddrError!types.SockAddrIn {
    const colon_idx = std.mem.lastIndexOfScalar(u8, addr_str, ':') orelse
        return ListenAddrError.InvalidFormat;
    const ip_str = addr_str[0..colon_idx];
    const port_str = addr_str[colon_idx + 1 ..];

    var octets: [4]u8 = undefined;
    var it = std.mem.splitScalar(u8, ip_str, '.');
    var i: usize = 0;
    while (it.next()) |part| : (i += 1) {
        if (i >= 4) return ListenAddrError.InvalidIP;
        octets[i] = std.fmt.parseInt(u8, part, 10) catch
            return ListenAddrError.InvalidIP;
    }
    if (i != 4) return ListenAddrError.InvalidIP;

    const port = std.fmt.parseInt(u16, port_str, 10) catch
        return ListenAddrError.InvalidPort;

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
    const max_occupancy: u32 = validateLoadFactor(load_factor) catch |err| {
        switch (err) {
            LoadFactorError.NotFinite => std.debug.print("--load-factor must be a finite number\n", .{}),
            LoadFactorError.NotPositive => std.debug.print("--load-factor must be greater than 0\n", .{}),
            LoadFactorError.TooLarge => std.debug.print("--load-factor must be at most {d}\n", .{vegosh.MAX_LOAD_FACTOR}),
            LoadFactorError.OccupancyTooSmall => std.debug.print("--load-factor {d} is too small: it allows zero occupied slots\n", .{load_factor}),
        }
        return err;
    };
    std.debug.print("max_occupancy = {d}\n", .{max_occupancy});

    const listen_str: []const u8 = res.args.listen orelse default_listen;
    const addr_in = parseListenAddr(listen_str) catch |err| {
        switch (err) {
            ListenAddrError.InvalidFormat => std.debug.print("--listen \"{s}\": expected IP:PORT, e.g. 127.0.0.1:9000\n", .{listen_str}),
            ListenAddrError.InvalidIP => std.debug.print("--listen \"{s}\": not a valid IPv4 address\n", .{listen_str}),
            ListenAddrError.InvalidPort => std.debug.print("--listen \"{s}\": port must be a number from 0 to 65535\n", .{listen_str}),
        }
        return err;
    };
    try blocking_server.startServer(addr_in, max_occupancy);
}
