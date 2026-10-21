const rawz = @import("rawz");
const types = rawz.types;
const io = rawz.io;
const std = @import("std");
const store = @import("../store/vegosh.zig");
pub const MAX_KEY_LEN: usize = store.MAX_KEY_SIZE;
pub const MAX_VALUE_LEN: usize = store.MAX_VALUE_SIZE;

pub const Connection = struct {
    fd: types.Fd,

    pub fn init(fd: types.Fd) Connection {
        return .{
            .fd = fd,
        };
    }

    pub fn readExact(self: *Connection, buf: []u8) !void {
        var off: usize = 0;
        while (off < buf.len) {
            const n = try io.read(self.fd, buf[off..]);
            if (n == 0)
                return error.ConnectionClosed;
            off += n;
        }
    }

    pub fn readHeader(self: *Connection) ![5]u8 {
        var header: [5]u8 = undefined;
        try self.readExact(&header);
        return header;
    }

    pub fn readKeyLen(self: *Connection) !u8 {
        var key_len: u8 = undefined;
        try self.readExact(std.mem.asBytes(&key_len));
        return key_len;
    }

    pub fn readKey(self: *Connection, key_len: u8) ![MAX_KEY_LEN]u8 {
        if (key_len > MAX_KEY_LEN) return error.KeyTooLong;
        var key: [MAX_KEY_LEN]u8 = @splat(0);
        try self.readExact(key[0..key_len]);
        return key;
    }

    pub fn readValueLen(self: *Connection) !u8 {
        var value_len: u8 = undefined;
        try self.readExact(std.mem.asBytes(&value_len));
        return value_len;
    }

    pub fn readValue(self: *Connection, value_len: u8) ![MAX_VALUE_LEN]u8 {
        if (value_len > MAX_VALUE_LEN) return error.ValueTooLong;
        var value: [MAX_VALUE_LEN]u8 = @splat(0);
        try self.readExact(value[0..value_len]);
        return value;
    }

    pub fn writeExact(self: *Connection, buf: []const u8) !void {
        var off: usize = 0;
        while (off < buf.len) {
            const n = try io.write(self.fd, buf[off..]);
            if (n == 0)
                return error.ConnectionClosed;
            off += n;
        }
    }

    pub fn writeResponse(self: *Connection, code: u8) !void {
        try self.writeExact(&[_]u8{code});
    }

    pub fn writeValue(self: *Connection, value: []const u8, value_len: u8) !void {
        try self.writeExact(value[0..value_len]);
    }

    pub fn writeSize(self: *Connection, value: u32) !void {
        var buf: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf, value, .little);
        try self.writeExact(&buf);
    }
    pub fn writeValueLen(self: *Connection, code: u8) !void {
        try self.writeExact(&[_]u8{code});
    }
};
