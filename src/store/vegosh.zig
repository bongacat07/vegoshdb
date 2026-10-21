const std = @import("std");

pub const TABLE_SIZE: usize = 1 << 21;
pub const MASK: u32 = @as(u32, TABLE_SIZE) - 1;

pub const MAX_KEY_SIZE: usize = 16;
pub const MAX_VALUE_SIZE: usize = 32;
pub const MAX_LOAD_FACTOR: f64 = 0.75;
const EMPTY: u8 = 0x00;
const OCCUPIED: u8 = 0x01;

const Slot = struct {
    key: [MAX_KEY_SIZE]u8,
    value: [MAX_VALUE_SIZE]u8,
    hash: u64,
    key_len: u8,
    value_len: u8,
    status: u8,
    probe_dist: u16,
    padding: [3]u8 = @splat(0),

    const empty: Slot = .{
        .key = @splat(0),
        .value = @splat(0),
        .hash = 0,
        .key_len = 0,
        .value_len = 0,
        .status = EMPTY,
        .probe_dist = 0,
    };
};

comptime {
    std.debug.assert(@sizeOf(Slot) == 64);
}
pub const InsertOutcome = enum { inserted, updated };

pub const InsertError = error{TableFull};
pub const LookupError = error{NotFound};

inline fn hashKey(key: []const u8) u64 {
    return std.hash.Wyhash.hash(123, key);
}
pub const Vegosh = struct {
    slots: [TABLE_SIZE]Slot align(64),
    count: u32,
    max_keys: u32,

    pub fn init(table: *Vegosh, max_keys: u32) void {
        std.debug.assert(max_keys <= TABLE_SIZE * 3 / 4);
        table.count = 0;
        table.max_keys = max_keys;
        @memset(&table.slots, Slot.empty);
    }

    pub inline fn insert(table: *Vegosh, key: []const u8, value: []const u8) InsertError!InsertOutcome {
        std.debug.assert(key.len <= MAX_KEY_SIZE);
        std.debug.assert(value.len <= MAX_VALUE_SIZE);

        if (table.count >= table.max_keys) {
            _ = table.get(key) catch return error.TableFull;
        }

        const hash = hashKey(key);
        var index: u32 = @truncate(hash & MASK);

        var incoming = Slot.empty;
        @memcpy(incoming.key[0..key.len], key);
        @memcpy(incoming.value[0..value.len], value);
        incoming.hash = hash;
        incoming.key_len = @intCast(key.len);
        incoming.value_len = @intCast(value.len);
        incoming.status = OCCUPIED;

        while (true) {
            const slot = &table.slots[index];

            if (slot.status == EMPTY) {
                slot.* = incoming;
                table.count += 1;
                return .inserted;
            }

            if (slot.hash == incoming.hash and slot.key_len == incoming.key_len and
                std.mem.eql(u8, &slot.key, &incoming.key))
            {
                slot.value = incoming.value;
                slot.value_len = incoming.value_len;
                return .updated;
            }

            if (incoming.probe_dist > slot.probe_dist) {
                std.mem.swap(Slot, slot, &incoming);
            }

            index = (index + 1) & MASK;
            incoming.probe_dist += 1;
        }
    }

    pub inline fn get(table: *Vegosh, key: []const u8) LookupError!struct { value: [MAX_VALUE_SIZE]u8, len: u8 } {
        std.debug.assert(key.len <= MAX_KEY_SIZE);

        const hash = hashKey(key);
        var index: u32 = @truncate(hash & MASK);
        var probe_dist: u16 = 0;

        while (true) {
            const slot = &table.slots[index];

            if (slot.status == EMPTY) return error.NotFound;

            if (slot.hash == hash and slot.key_len == key.len and
                std.mem.eql(u8, slot.key[0..slot.key_len], key))
            {
                return .{ .value = slot.value, .len = slot.value_len };
            }

            if (probe_dist > slot.probe_dist) return error.NotFound;

            index = (index + 1) & MASK;
            probe_dist += 1;
        }
    }

    pub inline fn delete(table: *Vegosh, key: []const u8) LookupError!void {
        std.debug.assert(key.len <= MAX_KEY_SIZE);

        const hash = hashKey(key);
        var index: u32 = @truncate(hash & MASK);
        var probe_dist: u16 = 0;

        while (true) {
            const slot = &table.slots[index];

            if (slot.status == EMPTY) return error.NotFound;
            if (slot.hash == hash and slot.key_len == key.len and
                std.mem.eql(u8, slot.key[0..slot.key_len], key)) break;
            if (probe_dist > slot.probe_dist) return error.NotFound;

            index = (index + 1) & MASK;
            probe_dist += 1;
        }

        while (true) {
            const next = (index + 1) & MASK;
            const next_slot = &table.slots[next];

            if (next_slot.status == EMPTY or next_slot.probe_dist == 0) {
                table.slots[index] = Slot.empty;
                break;
            }

            table.slots[index] = next_slot.*;
            table.slots[index].probe_dist -= 1;
            index = next;
        }

        table.count -= 1;
    }

    pub inline fn size(table: *Vegosh) u32 {
        return table.count;
    }

    pub inline fn clear(table: *Vegosh) void {
        @memset(&table.slots, Slot.empty);
        table.count = 0;
    }
};
