const std = @import("std");

pub const Fd = struct {
    fd: i32,
};

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
    zero: [8]u8 = [_]u8{0} ** 8,
};

pub const SockAddr = extern struct {
    family: u16,
    sa_data: [14]u8,
};

// types.zig
pub fn parseListenAddr(addr_str: []const u8) !SockAddrIn {
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

    return SockAddrIn{
        .port = htons(port),
        .addr = addr,
    };
}

pub const SocketOption = enum(c_int) {
    debug = 1,
    reuse_addr = 2,
    socket_type = 3,
    error_ = 4,
    dont_route = 5,
    broadcast = 6,
    sndbuf = 7,
    rcvbuf = 8,
    keep_alive = 9,
    oob_inline = 10,
    no_check = 11,
    priority = 12,
    linger = 13,
    bsd_compat = 14,
    reuse_port = 15,

    passcred = 16,
    peercred = 17,
    rcvlowat = 18,
    sndlowat = 19,
    rcvtimeo = 20,
    sndtimeo = 21,
    acceptconn = 30,
};

pub const TcpOption = enum(c_int) {
    no_delay = 1,
    max_seg = 2,
    cork = 3,
    keep_idle = 4,
    keep_intvl = 5,
    keep_cnt = 6,
    syncnt = 7,
    linger2 = 8,
    defer_accept = 9,
    window_clamp = 10,
    info = 11,
    quick_ack = 12,
    congestion = 13,
    md5sig = 14,
    thin_linear_timeouts = 16,
    thin_dupack = 17,
    user_timeout = 18,
    repair = 19,
    repair_queue = 20,
    repair_options = 22,
    fastopen = 23,
    notsent_lowat = 25,
    cc_info = 26,
    save_syn = 27,
    saved_syn = 28,
    fastopen_connect = 30,
};

pub const IpOption = enum(c_int) {
    tos = 1,
    ttl = 2,

    hdrincl = 3,

    options = 4,

    multicast_if = 32,
    multicast_ttl = 33,
    multicast_loop = 34,

    add_membership = 35,
    drop_membership = 36,

    freebind = 15,
    transparent = 19,
};
pub const Ipv6Option = enum(c_int) {
    addrform = 1,
    pktinfo = 50,
    hoplimit = 52,
    mtu = 24,
    v6only = 26,

    multicast_if = 17,
    multicast_hops = 18,
    multicast_loop = 19,

    join_group = 20,
    leave_group = 21,

    unicast_hops = 16,
};

pub fn htons(port: u16) u16 {
    return @byteSwap(port);
}

pub fn htonl(addr: u32) u32 {
    return @byteSwap(addr);
}
