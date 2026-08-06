const types = @import("../rawz/types.zig");
const syscall = @import("../rawz/syscall.zig");

pub const MAX_KEY_LEN: usize = 16;
pub const MAX_VALUE_LEN: usize = 32;

pub const Connection = struct {
    fd: types.Fd,
    pub fn init(fd: types.Fd) Connection {
        return .{
            .fd = fd,
        };
    }

    pub fn readExact(self: Connection, buf: []u8) !void {
        var off: usize = 0;

        while (off < buf.len) {
            const n = try syscall.read(self.fd, buf[off..]);
            if (n == 0) return error.ConnectionClosed;
            off += n;
        }
    }

    pub fn readHeader(self: Connection) ![5]u8 {
        var header: [5]u8 = undefined;
        try self.readExact(&header);
        return header;
    }

    pub fn readKey(self: Connection) ![MAX_KEY_LEN]u8 {
        var key: [MAX_KEY_LEN]u8 = undefined;
        try self.readExact(&key);
        return key;
    }

    pub fn readValue(self: Connection) ![MAX_VALUE_LEN]u8 {
        var value: [MAX_VALUE_LEN]u8 = undefined;
        try self.readExact(&value);
        return value;
    }
};
