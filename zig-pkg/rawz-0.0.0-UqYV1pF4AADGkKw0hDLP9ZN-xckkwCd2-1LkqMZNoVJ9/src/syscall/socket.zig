const types = @import("../types.zig");
const arch = @import("../arch/arch.zig");
const errno = @import("../errno.zig");

pub fn socket(
    domain: types.AddressFamily,
    type_: types.SocketType,
    protocol: ?types.Protocol,
) !types.Fd {
    const ret = arch.impl.syscall3(
        arch.num.socket,
        @intCast(@intFromEnum(domain)),
        @intCast(@intFromEnum(type_)),
        @intCast(if (protocol) |p| @intFromEnum(p) else 0),
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

    return @intCast(ret);
}

pub fn listen(fd: types.Fd, backlog: i32) !void {
    if (backlog < 0) return error.InvalidArgument;

    const ret = arch.impl.syscall2(
        arch.num.listen,
        @intCast(fd),
        @intCast(backlog),
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

pub fn bind(fd: types.Fd, addr: *types.SockAddr, addrlen: u32) !void {
    const ret = arch.impl.syscall3(
        arch.num.bind,
        @intCast(fd),
        @intFromPtr(addr),
        @intCast(addrlen),
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
    const ret = arch.impl.syscall3(
        arch.num.accept,
        @intCast(fd),
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

    return @intCast(ret);
}

pub fn accept4(fd: types.Fd, addr: ?*types.SockAddr, addrlen: ?*u32, flags: types.Accept4Flags) !types.Fd {
    const ret = arch.impl.syscall4(arch.num.accept4, @intCast(fd), if (addr) |a| @intFromPtr(a) else 0, if (addrlen) |l| @intFromPtr(l) else 0, flags);

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocket,
            .OPNOTSUPP => error.OperationNotSupported,
            .INVAL => error.InvalidArgument,
            .AGAIN, .WOULDBLOCK => error.WouldBlock,
            .INTR => error.Interrupted,
            .FAULT => error.BadAddress,
            .CONNABORTED => error.ConnectionAborted,
            .PROTO, .EPROTO => error.ProtocolError,
            .MFILE,
            .NFILE,
            .NOBUFS,
            .NOMEM,
            => error.SystemResources,
            .PERM => error.AccessDenied,
            .NETDOWN => error.NetworkDown,
            .NETUNREACH => error.NetworkUnreachable,
            .HOSTDOWN => error.HostDown,
            .HOSTUNREACH => error.HostUnreachable,
            .NONET => error.NoNetwork,
            .NETRESET => error.NetworkReset,
            .TIMEDOUT => error.TimedOut,

            .PROTOOPT => error.ProtocolOption,
            .PROTONOSUPPORT => error.ProtocolNotSupported,
            .SOCKTNOSUPPORT => error.SocketTypeNotSupported,
            .NOSR => error.NoStreamResources,

            else => error.Unexpected,
        };
    }
    return @intCast(ret);
}

pub fn connect(
    fd: types.Fd,
    addr: types.SockAddr,
    addrlen: u32,
) !void {
    const ret = arch.impl.syscall3(
        arch.num.connect,
        @intCast(fd),
        @intFromPtr(&addr),
        @as(usize, addrlen),
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,

            .ACCES, .PERM => error.AccessDenied,

            .AFNOSUPPORT => error.AddressFamilyNotSupported,
            .ADDRINUSE => error.AddressInUse,
            .ADDRNOTAVAIL => error.AddressNotAvailable,

            .ALREADY => error.ConnectionAlreadyInProgress,
            .INPROGRESS => error.ConnectionInProgress,

            .CONNREFUSED => error.ConnectionRefused,
            .ISCONN => error.AlreadyConnected,

            .FAULT => error.BadAddress,
            .INTR => error.Interrupted,

            .NETUNREACH => error.NetworkUnreachable,
            .HOSTUNREACH => error.HostUnreachable,

            .NETDOWN => error.NetworkDown,

            .TIMEDOUT => error.TimedOut,

            .OPNOTSUPP => error.OperationNotSupported,

            .AGAIN => error.WouldBlock,

            else => error.Unexpected,
        };
    }
}

pub fn shutdown(fd: types.Fd, how: types.ShutdownHow) !void {
    const ret = arch.impl.syscall2(
        arch.num.shutdown,
        @intCast(fd),
        @intFromEnum(how),
    );
    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,
            .INVAL => error.InvalidArgument,
            .NOTCONN => error.NotConnected,
            else => error.Unexpected,
        };
    }
}

pub fn getsockname(
    fd: types.Fd,
    addr: *types.SockAddr,
    addrlen: *u32,
) !void {
    const ret = arch.impl.syscall3(
        arch.num.getsockname,
        @intCast(fd),
        @intFromPtr(addr),
        @intFromPtr(addrlen),
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,
            .FAULT => error.BadAddress,
            .INVAL => error.InvalidArgument,
            else => error.Unexpected,
        };
    }
}

pub fn getpeername(
    fd: types.Fd,
    addr: *types.SockAddr,
    addrlen: *u32,
) !void {
    const ret = arch.impl.syscall3(
        arch.num.getpeername,
        @intCast(fd),
        @intFromPtr(addr),
        @intFromPtr(addrlen),
    );

    if (ret < 0) {
        return switch (errno.fromRet(ret)) {
            .BADF => error.InvalidFD,
            .NOTSOCK => error.NotASocketFD,
            .FAULT => error.BadAddress,
            .INVAL => error.InvalidArgument,
            .NOTCONN => error.NotConnected,
            else => error.Unexpected,
        };
    }
}
