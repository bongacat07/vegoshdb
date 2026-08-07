const std = @import("std");
const Io = std.Io;
const syscall = @import("rawz/syscall.zig");
const types = @import("rawz/types.zig");
const blocking_server = @import("server/blocking.zig");
const vegosh = @import("store/vegosh.zig");
const clap = @import("clap");

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
    const addr_in = try types.parseListenAddr(listen_str);
    try blocking_server.startServer(addr_in, max_occupancy);
}
