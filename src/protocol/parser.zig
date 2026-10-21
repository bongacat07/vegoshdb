const client = @import("../server/connection.zig");
const std = @import("std");
const store = @import("../store/vegosh.zig");
pub const MAX_KEY_LEN: usize = store.MAX_KEY_SIZE;
pub const MAX_VALUE_LEN: usize = store.MAX_VALUE_SIZE;

pub const MAX_CONNECTIONS: usize = 10_000;

pub const MAGIC_BYTES: [4]u8 = .{ 'v', 'k', 'd', 'b' };

pub const SET_KEY: u8 = 0x01;
pub const GET_KEY: u8 = 0x02;
pub const DELETE_KEY: u8 = 0x03;
pub const SIZE: u8 = 0x04;
pub const PING: u8 = 0x05;
pub const FLUSH: u8 = 0x06;

pub const Command = union(enum) {
    set: struct {
        key: [MAX_KEY_LEN]u8,
        value: [MAX_VALUE_LEN]u8,
        key_len: u8,
        value_len: u8,
    },

    get: struct {
        key_len: u8,
        key: [MAX_KEY_LEN]u8,
    },

    delete: struct {
        key_len: u8,
        key: [MAX_KEY_LEN]u8,
    },

    size,
    ping,
    flush,
};

pub const ParseResult = union(enum) {
    command: Command,
    invalid_magic,
    invalid_opcode: u8,
};

pub fn parse(conn: *client.Connection) !ParseResult {
    const header = try conn.readHeader();

    if (!std.mem.eql(u8, header[0..4], &MAGIC_BYTES)) {
        return .invalid_magic;
    }

    switch (header[4]) {
        PING => {
            return .{
                .command = .ping,
            };
        },

        GET_KEY => {
            const key_len = try conn.readKeyLen();
            const key = try conn.readKey(key_len);

            return .{ .command = .{ .get = .{ .key_len = key_len, .key = key } } };
        },

        SET_KEY => {
            const key_len = try conn.readKeyLen();
            const key = try conn.readKey(key_len);
            const value_len = try conn.readValueLen();
            const value = try conn.readValue(value_len);

            return .{ .command = .{ .set = .{
                .key_len = key_len,
                .key = key,
                .value = value,
                .value_len = value_len,
            } } };
        },

        DELETE_KEY => {
            const key_len = try conn.readKeyLen();
            const key = try conn.readKey(key_len);

            return .{ .command = .{ .delete = .{ .key_len = key_len, .key = key } } };
        },

        FLUSH => {
            return .{
                .command = .flush,
            };
        },

        SIZE => {
            return .{
                .command = .size,
            };
        },

        else => {
            return .{
                .invalid_opcode = header[4],
            };
        },
    }
}
