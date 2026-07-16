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

pub fn htons(port: u16) u16 {
    return @byteSwap(port);
}

pub fn htonl(addr: u32) u32 {
    return @byteSwap(addr);
}
