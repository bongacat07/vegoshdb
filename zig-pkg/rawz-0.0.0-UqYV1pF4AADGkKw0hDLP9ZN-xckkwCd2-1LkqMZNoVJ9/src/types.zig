const std = @import("std");

pub const Fd = i32;

pub const SocketType = enum(c_int) {
    stream = 1,
    dgram = 2,
    raw = 3,
};

pub const AddressFamily = enum(c_int) {
    unix = 1,
    inet = 2,
    inet6 = 10,
};

pub const Protocol = enum(c_int) {
    tcp = 6,
    udp = 17,
};

pub const SockAddrIn = extern struct {
    family: u16 = @intFromEnum(AddressFamily.inet),
    port: u16,
    addr: u32,
    zero: [8]u8 = @splat(0),
};

pub const SockAddr = extern struct {
    family: u16,
    sa_data: [14]u8,
};

pub fn htons(port: u16) u16 {
    return @byteSwap(port);
}

pub fn htonl(addr: u32) u32 {
    return @byteSwap(addr);
}

pub const Acccept4Flags = packed struct(u32) {
    _pad1: u11 = 0,
    nonblock: bool,
    _pad2: u7 = 0,
    cloexec: bool,
    _pad3: u12 = 0,
};

pub const ShutdownHow = enum(u32) {
    read = 0,
    write = 1,
    read_write = 2,
};

pub const PollEvents = packed struct(u16) {
    POLLIN: bool = false,
    POLLPRI: bool = false,
    POLLOUT: bool = false,
    _pad1: u3 = 0,
    POLLRDNORM: bool = false,
    POLLRDBAND: bool = false,
    POLLWRNORM: bool = false,
    POLLWRBAND: bool = false,
    POLLMSG: bool = false,
    _pad2: u2 = 0,
    POLLRDHUP: bool = false,
    _pad3: u2 = 0,
};

pub const PollRevents = packed struct(u16) {
    POLLIN: bool = false,
    POLLPRI: bool = false,
    POLLOUT: bool = false,
    POLLERR: bool = false,
    POLLHUP: bool = false,
    POLLNVAL: bool = false,
    POLLRDNORM: bool = false,
    POLLRDBAND: bool = false,
    POLLWRNORM: bool = false,
    POLLWRBAND: bool = false,
    POLLMSG: bool = false,
    _pad4: u2 = 0,
    POLLRDHUP: bool = false,
    _pad5: u2 = 0,
};

pub const Pollfd = extern struct {
    fd: Fd,
    poll_events: PollEvents,
    poll_revents: PollRevents,
};

pub const Timespec = extern struct {
    sec: i64,
    nsec: i64,

    pub const zero: Timespec = .{ .sec = 0, .nsec = 0 };

    pub fn init(sec: i64, nsec: i64) error{InvalidNanoseconds}!Timespec {
        if (nsec < 0 or nsec > 999_999_999) return error.InvalidNanoseconds;
        return .{ .sec = sec, .nsec = nsec };
    }

    pub fn fromMillis(ms: i64) Timespec {
        return .{
            .sec = @divTrunc(ms, 1000),
            .nsec = @rem(ms, 1000) * 1_000_000,
        };
    }
};
pub const SendFlags = packed struct(u32) {
    oob: bool = false,
    _pad1: u2 = 0,
    dontroute: bool = false,
    _pad2: u5 = 0,
    dontwait: bool = false,
    _pad3: u1 = 0,
    eor: bool = false,
    _pad4: u3 = 0,
    nosignal: bool = false,
    more: bool = false,
    _pad5: u8 = 0,
    confirm: bool = false,
    _pad6: u1 = 0,
    fastopen: bool = false,
    _pad7: u2 = 0,
};
