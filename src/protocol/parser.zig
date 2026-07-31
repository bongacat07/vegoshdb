const types = @import("../rawz/types.zig");
const syscall = @import("../rawz/syscall.zig");
const std = @import("std");

pub const MAX_KEY_LEN: usize = 16;
pub const MAX_VALUE_LEN: usize = 32;

pub const MAX_CONNECTIONS: usize = 10_000;
pub const MAX_ENTRIES: usize = 1_000_000;

pub const MAGIC_BYTES: [4]u8 = .{ 'v', 'k', 'd', 'b' };

pub const SET_KEY: u8 = 0x01;
pub const GET_KEY: u8 = 0x02;
pub const DELETE_KEY: u8 = 0x03;
pub const SIZE: u8 = 0x04;
pub const PING: u8 = 0x05;
pub const FLUSH: u8 = 0x06;

pub const OK: u8 = 0x69;
pub const KEY_NOT_FOUND: u8 = 0x67;
pub const MAX_LIMIT_REACHED: u8 = 0x68;
pub const OK_KEY_UPDATED: u8 = 0x65;
pub const INVALID_OPCODE: u8 = 0x64;

pub const Command = union(enum) {
    set: struct {
        key: [MAX_KEY_LEN]u8,
        value: [MAX_VALUE_LEN]u8,
    },

    get: struct {
        key: [MAX_KEY_LEN]u8,
    },

    delete: struct {
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

pub fn parser(fd: types.Fd) !ParseResult {
    var header: [5]u8 = undefined;

    const n = try syscall.read(fd, &header);

    if (n < 5) {
        // temporary handling for now
        return error.IncompleteRequest;
    }

    if (!std.mem.eql(u8, header[0..4], &MAGIC_BYTES)) {
        return .invalid_magic;
    }

    const opcode = header[4];

    switch (opcode) {
        PING => {
            return .{
                .command = .ping,
            };
        },

        GET_KEY => {
            var key: [MAX_KEY_LEN]u8 = undefined;

            const key_read = try syscall.read(fd, &key);

            if (key_read != MAX_KEY_LEN) {
                return error.IncompleteRequest;
            }

            return .{
                .command = .{
                    .get = .{
                        .key = key,
                    },
                },
            };
        },

        SET_KEY => {
            var key: [MAX_KEY_LEN]u8 = undefined;
            var value: [MAX_VALUE_LEN]u8 = undefined;

            const key_read = try syscall.read(fd, &key);
            if (key_read != MAX_KEY_LEN) {
                return error.IncompleteRequest;
            }

            const value_read = try syscall.read(fd, &value);
            if (value_read != MAX_VALUE_LEN) {
                return error.IncompleteRequest;
            }

            return .{
                .command = .{
                    .set = .{
                        .key = key,
                        .value = value,
                    },
                },
            };
        },
        DELETE_KEY => {
            var key: [MAX_KEY_LEN]u8 = undefined;

            const key_read = try syscall.read(fd, &key);

            if (key_read != MAX_KEY_LEN) {
                return error.IncompleteRequest;
            }

            return .{
                .command = .{
                    .delete = .{
                        .key = key,
                    },
                },
            };
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
                .invalid_opcode = opcode,
            };
        },
    }
}
