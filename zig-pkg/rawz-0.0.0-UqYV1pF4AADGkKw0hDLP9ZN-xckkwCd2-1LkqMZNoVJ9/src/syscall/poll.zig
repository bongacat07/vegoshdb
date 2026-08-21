const arch = @import("../arch/arch.zig");
const errno = @import("../errno.zig");
const types = @import("../types.zig");

pub fn poll(fds: []types.Pollfd, timeout: i32) !usize {
    var ts: types.Timespec = undefined;
    const ts_ptr: usize = if (timeout >= 0) blk: {
        ts = types.Timespec.fromMillis(timeout);
        break :blk @intFromPtr(&ts);
    } else 0;

    const ret = arch.impl.syscall5(
        arch.num.ppoll,
        @intFromPtr(fds.ptr),
        fds.len,
        ts_ptr,
        0,
        0,
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .FAULT => error.BadBuffer,
            .INTR => error.Interrupted,
            .INVAL => error.InvalidArgument,
            .NOMEM => error.SystemResources,
            else => error.Unexpected,
        };
    }

    return @intCast(ret);
}
