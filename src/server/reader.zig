const types = @import("../rawz/types.zig");
const syscall = @import("../rawz/syscall.zig");

pub const MAX_KEY_LEN: usize = 16;
pub const MAX_VALUE_LEN: usize = 32;

pub inline fn readExact(fd: types.Fd, buf: []u8) !void {
    var off: usize = 0;

    while (off < buf.len) {
        const n = try syscall.read(fd, buf[off..]);
        if (n == 0) return error.ConnectionClosed;
        off += n;
    }
}

pub fn readHeader(fd: types.Fd) ![5]u8 {
    var header: [5]u8 = undefined;
    try readExact(fd, &header);
    return header;
}

pub fn readKey(fd: types.Fd) ![MAX_KEY_LEN]u8 {
    var key: [MAX_KEY_LEN]u8 = undefined;
    try readExact(fd, &key);
    return key;
}

pub fn readValue(fd: types.Fd) ![MAX_VALUE_LEN]u8 {
    var value: [MAX_VALUE_LEN]u8 = undefined;
    try readExact(fd, &value);
    return value;
}
