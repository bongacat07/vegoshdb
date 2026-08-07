const parser = @import("parser.zig");
const store = @import("../store/vegosh.zig");
const client = @import("../server/connection.zig");
const std = @import("std");

pub fn handleParseResult(
    table: *store.Vegosh,
    result: parser.ParseResult,
) !void {
    switch (result) {
        .invalid_magic => {
            std.debug.print("[protocol] invalid magic\n", .{});
        },

        .invalid_opcode => |opcode| {
            std.debug.print(
                "[protocol] invalid opcode: {d}\n",
                .{opcode},
            );
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
                            std.debug.print(
                                "[set] table full\n",
                                .{},
                            );
                            return;
                        },
                    };

                    switch (outcome) {
                        .inserted => {
                            std.debug.print(
                                "[set] inserted key={s} len={d} size={d}\n",
                                .{
                                    &cmd.key,
                                    cmd.value_len,
                                    store.Vegosh.size(table),
                                },
                            );
                        },

                        .updated => {
                            std.debug.print(
                                "[set] updated key={s} len={d} size={d}\n",
                                .{
                                    &cmd.key,
                                    cmd.value_len,
                                    store.Vegosh.size(table),
                                },
                            );
                        },
                    }
                },

                .get => |cmd| {
                    const result_value = table.get(
                        &cmd.key,
                    ) catch |err| switch (err) {
                        error.NotFound => {
                            std.debug.print(
                                "[get] not found key={s}\n",
                                .{&cmd.key},
                            );
                            return;
                        },
                    };

                    std.debug.print(
                        "[get] key={s} len={d} value={s}\n",
                        .{
                            &cmd.key,
                            result_value.len,
                            result_value.value[0..result_value.len],
                        },
                    );
                },

                .delete => |cmd| {
                    table.delete(
                        &cmd.key,
                    ) catch |err| switch (err) {
                        error.NotFound => {
                            std.debug.print(
                                "[delete] not found key={s}\n",
                                .{&cmd.key},
                            );
                            return;
                        },
                    };

                    std.debug.print(
                        "[delete] deleted key={s} size={d}\n",
                        .{
                            &cmd.key,
                            store.Vegosh.size(table),
                        },
                    );
                },

                .flush => {
                    table.clear();

                    std.debug.print(
                        "[flush] table cleared size={d}\n",
                        .{store.Vegosh.size(table)},
                    );
                },

                .size => {
                    std.debug.print(
                        "[size] {d}\n",
                        .{table.size()},
                    );
                },

                .ping => {
                    std.debug.print("[ping] pong\n", .{});
                },
            }
        },
    }
}
