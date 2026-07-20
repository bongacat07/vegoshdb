const types = @import("types.zig");
const linux_syscall = @import("x86_64_syscalln.zig");
const errno = @import("errno.zig");

pub const SYS = struct {
    pub const read = 0;
    pub const write = 1;
    pub const close = 3;
    pub const socket = 41;
    pub const accept = 43;
    pub const bind = 49;
    pub const listen = 50;
};

pub fn socket(
    domain: types.AddressFamily,
    type_: types.SocketType,
    protocol: ?types.Protocol,
) !types.Fd {
    const ret = linux_syscall.syscall3(
        SYS.socket,
        @as(usize, @intCast(@intFromEnum(domain))),
        @as(usize, @intCast(@intFromEnum(type_))),
        @as(usize, @intCast(if (protocol) |p| @intFromEnum(p) else 0)),
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .PERM, .ACCES => error.AccessDenied,
            .AFNOSUPPORT => error.AddressFamilyNotSupported,
            .PROTONOSUPPORT => error.ProtocolNotSupported,
            .NFILE, .MFILE => error.SystemResources,
            else => error.Unexpected,
        };
    }

    return .{ .fd = @intCast(ret) };
}

pub fn close(fd: types.Fd) !void {
    const ret = linux_syscall.syscall1(SYS.close, @as(usize, @intCast(fd.fd)));

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .INTR => error.Interrupted,
            .IO => error.IOError,
            else => error.Unexpected,
        };
    }
}

pub fn listen(fd: types.Fd, backlog: i32) !void {
    if (backlog < 0) return error.InvalidArgument;

    const ret = linux_syscall.syscall2(
        SYS.listen,
        @as(usize, @intCast(fd.fd)),
        @as(usize, @intCast(backlog)),
    );
    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .ADDRINUSE => error.AddressInUse,
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,
            else => error.Unexpected,
        };
    }
}

pub fn bind(fd: types.Fd, addr: *const types.SockAddr, addrlen: u32) !void {
    const ret = linux_syscall.syscall3(
        SYS.bind,
        @as(usize, @intCast(fd.fd)),
        @intFromPtr(addr),
        @as(usize, @intCast(addrlen)),
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,
            .ADDRINUSE => error.AddressInUse,
            .ADDRNOTAVAIL => error.AddressNotAvailable,
            .ACCES => error.AccessDenied,
            .INVAL => error.InvalidArgument,
            else => error.Unexpected,
        };
    }
}

pub fn accept(fd: types.Fd, addr: ?*types.SockAddr, addrlen: ?*u32) !types.Fd {
    const ret = linux_syscall.syscall3(
        SYS.accept,
        @as(usize, @intCast(fd.fd)),
        if (addr) |a| @intFromPtr(a) else 0,
        if (addrlen) |l| @intFromPtr(l) else 0,
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,
            .OPNOTSUPP => error.OperationNotSupported,
            .AGAIN => error.WouldBlock,
            .CONNABORTED => error.ConnectionAborted,
            .MFILE, .NFILE => error.SystemResources,
            .PERM => error.AccessDenied,
            else => error.Unexpected,
        };
    }

    return .{ .fd = @intCast(ret) };
}

pub fn read(fd: types.Fd, buf: []u8) !usize {
    const ret = linux_syscall.syscall3(
        SYS.read,
        @as(usize, @intCast(fd.fd)),
        @intFromPtr(buf.ptr),
        buf.len,
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .FAULT => error.BadBuffer,
            .INTR => error.Interrupted,
            .INVAL => error.InvalidArgument,
            .IO => error.IOError,
            .AGAIN => error.WouldBlock,
            .CONNRESET => error.ConnectionReset,
            else => error.Unexpected,
        };
    }

    return @intCast(ret);
}

pub fn write(fd: types.Fd, buf: []const u8) !usize {
    const ret = linux_syscall.syscall3(
        SYS.write,
        @as(usize, @intCast(fd.fd)),
        @intFromPtr(buf.ptr),
        buf.len,
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .FAULT => error.BadBuffer,
            .INTR => error.Interrupted,
            .INVAL => error.InvalidArgument,
            .IO => error.IOError,
            .AGAIN => error.WouldBlock,
            .PIPE => error.BrokenPipe,
            .CONNRESET => error.ConnectionReset,
            else => error.Unexpected,
        };
    }

    return @intCast(ret);
}
