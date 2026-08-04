const std = @import("std");
const Io = std.Io;
const syscall = @import("rawz/syscall.zig");
const types = @import("rawz/types.zig");
const server = @import("server/blocking.zig");
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
    if (res.args.@"load-factor") |lf| {
        const max_occupancy: usize = @intFromFloat(lf * @as(f64, 1 << 21));
        std.debug.print("max_occupancy = {d}\n", .{max_occupancy});
    }
    if (res.args.listen) |addr|
        std.debug.print("--listen = {s}\n", .{addr});

    try server.startServer();
}
