const std = @import("std");

pub const TABLE_SIZE: usize = 1 << 21;
pub const MASK: u32 = @as(u32, TABLE_SIZE) - 1;

pub const KEY_SIZE: usize = 16;
pub const VALUE_SIZE: usize = 32;

const EMPTY: u8 = 0x00;
const OCCUPIED: u8 = 0x01;

const Slot = extern struct {
    key: [KEY_SIZE]u8,
    value: [VALUE_SIZE]u8,
    hash: u64,
    value_len: u8,
    status: u8,
    probe_dist: u16,
    padding: [4]u8 = [_]u8{0} ** 4,

    const empty: Slot = .{
        .key = [_]u8{0} ** KEY_SIZE,
        .value = [_]u8{0} ** VALUE_SIZE,
        .hash = 0,
        .value_len = 0,
        .status = EMPTY,
        .probe_dist = 0,
    };
};

comptime {
    std.debug.assert(@sizeOf(Slot) == 64);
}

pub const Vegosh = extern struct {
    slots: [TABLE_SIZE]Slot align(64),
    count: u32,
    max_keys: u32,
};

pub const InsertOutcome = enum { inserted, updated };

pub const Error = error{
    TableFull,
    NotFound,
};

inline fn hashKey(key: *const [KEY_SIZE]u8) u64 {
    return std.hash.Wyhash.hash(123, key);
}

pub fn init(table: *Vegosh, max_keys: u32) void {
    table.count = 0;
    table.max_keys = max_keys;
    @memset(&table.slots, Slot.empty);
}

pub inline fn insert(table: *Vegosh, key: *const [KEY_SIZE]u8, value: *const [VALUE_SIZE]u8, value_len: u8) Error!InsertOutcome {
    std.debug.assert(value_len <= VALUE_SIZE);

    if (table.count >= table.max_keys) return error.TableFull;

    const hash = hashKey(key);
    var index: u32 = @truncate(hash & MASK);

    var incoming = Slot{
        .key = key.*,
        .value = value.*,
        .hash = hash,
        .value_len = value_len,
        .status = OCCUPIED,
        .probe_dist = 0,
    };

    while (true) {
        const slot = &table.slots[index];

        if (slot.status == EMPTY) {
            slot.* = incoming;
            table.count += 1;
            return .inserted;
        }

        if (slot.hash == incoming.hash and std.mem.eql(u8, &slot.key, &incoming.key)) {
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

pub inline fn get(table: *const Vegosh, key: *const [KEY_SIZE]u8) Error!struct { value: [VALUE_SIZE]u8, len: u8 } {
    const hash = hashKey(key);
    var index: u32 = @truncate(hash & MASK);
    var probe_dist: u16 = 0;

    while (true) {
        const slot = &table.slots[index];

        if (slot.status == EMPTY) return error.NotFound;

        if (slot.hash == hash and std.mem.eql(u8, &slot.key, key)) {
            return .{ .value = slot.value, .len = slot.value_len };
        }

        if (probe_dist > slot.probe_dist) return error.NotFound;

        index = (index + 1) & MASK;
        probe_dist += 1;
    }
}

pub inline fn delete(table: *Vegosh, key: *const [KEY_SIZE]u8) Error!void {
    const hash = hashKey(key);
    var index: u32 = @truncate(hash & MASK);
    var probe_dist: u16 = 0;

    while (true) {
        const slot = &table.slots[index];

        if (slot.status == EMPTY) return error.NotFound;
        if (slot.hash == hash and std.mem.eql(u8, &slot.key, key)) break;
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

pub inline fn size(table: *const Vegosh) u32 {
    return table.count;
}

pub inline fn clear(table: *Vegosh) void {
    @memset(&table.slots, Slot.empty);
    table.count = 0;
}
