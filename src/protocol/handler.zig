const parser = @import("parser.zig");
const store = @import("../store/vegosh.zig");
const client = @import("../server/connection.zig");
const std = @import("std");

pub const OK: u8 = 0x69;
pub const KEY_NOT_FOUND: u8 = 0x67;
pub const MAX_LIMIT_REACHED: u8 = 0x68;
pub const OK_KEY_UPDATED: u8 = 0x65;
pub const INVALID_OPCODE: u8 = 0x64;
pub const PONG: u8 = 0x63;
pub fn handleParseResult(
    table: *store.Vegosh,
    result: parser.ParseResult,
    conn: *client.Connection,
) !void {
    switch (result) {
        .invalid_magic => {
            std.debug.print("[protocol] invalid magic\n", .{});
        },

        .invalid_opcode => {
            try conn.writeResponse(INVALID_OPCODE);
        },

        .command => |command| {
            switch (command) {
                .set => |cmd| {
                    const outcome = table.insert(
                        &cmd.key,
                        &cmd.value,
                        cmd.value_len,
                    ) catch |err| switch (err) {
                        error.TableFull => {
                            try conn.writeResponse(MAX_LIMIT_REACHED);
                            return;
                        },
                    };

                    switch (outcome) {
                        .inserted => {
                            try conn.writeResponse(OK);
                        },

                        .updated => {
                            try conn.writeResponse(OK_KEY_UPDATED);
                        },
                    }
                },

                .get => |cmd| {
                    const result_value = table.get(
                        &cmd.key,
                    ) catch |err| switch (err) {
                        error.NotFound => {
                            try conn.writeResponse(KEY_NOT_FOUND);
                            return;
                        },
                    };

                    try conn.writeResponse(OK);
                    try conn.writeValueLen(result_value.len);
                    try conn.writeValue(&result_value.value, result_value.len);
                },

                .delete => |cmd| {
                    table.delete(
                        &cmd.key,
                    ) catch |err| switch (err) {
                        error.NotFound => {
                            try conn.writeResponse(KEY_NOT_FOUND);
                            return;
                        },
                    };

                    try conn.writeResponse(OK);
                },

                .flush => {
                    table.clear();
                    try conn.writeResponse(OK);
                },

                .size => {
                    try conn.writeResponse(OK);
                    try conn.writeSize(table.size());
                },

                .ping => {
                    try conn.writeResponse(PONG);
                },
            }
        },
    }
}
