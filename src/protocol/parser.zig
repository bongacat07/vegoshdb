const types = @import("../rawz/types.zig");
const syscall = @import("../rawz/syscall.zig");
const client = @import("../server/connnection.zig");
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

//Response codes
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

pub fn parse(conn: *client.Connection) !void {
    const header = try conn.readHeader();

    if (!std.mem.eql(u8, header[0..4], &MAGIC_BYTES)) {
        std.debug.print("Invalid magic\n", .{});
        return;
    }

    switch (header[4]) {
        PING => {
            std.debug.print("PING\n", .{});
        },

        GET_KEY => {
            const key = try conn.readKey();
            std.debug.print("GET key: '{s}'\n", .{&key});
        },

        SET_KEY => {
            const key = try conn.readKey();
            const value = try conn.readValue();

            std.debug.print(
                "SET key: '{s}' value: '{s}'\n",
                .{ &key, &value },
            );
        },

        DELETE_KEY => {
            const key = try conn.readKey();
            std.debug.print("DELETE key: '{s}'\n", .{&key});
        },

        FLUSH => {
            std.debug.print("FLUSH\n", .{});
        },

        SIZE => {
            std.debug.print("SIZE\n", .{});
        },

        else => {
            std.debug.print(
                "Invalid opcode: 0x{x}\n",
                .{header[4]},
            );
        },
    }
}
