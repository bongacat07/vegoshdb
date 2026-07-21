pub const MAX_KEY_LEN: usize = 16;
pub const MAX_VALUE_LEN: usize = 32;

pub const MAX_CONNECTIONS: usize = 10_000;
pub const MAX_ENTRIES: usize = 1_000_000;

pub const MAGIC_BYTES: [2]u8 = .{ 'v', 'k' };

pub const SET_KEY: [1]u8 = .{0x01};
pub const GET_KEY: [1]u8 = .{0x02};
pub const DELETE_KEY: [1]u8 = .{0x03};
pub const SIZE: [1]u8 = .{0x04};
pub const PING: [1]u8 = .{0x05};
pub const FLUSH: [1]u8 = .{0x06};

pub const OK: [1]u8 = .{0x69};
pub const KEY_NOT_FOUND: [1]u8 = .{0x67};
pub const MAX_LIMIT_REACHED: [1]u8 = .{0x68};
pub const OK_KEY_UPDATED: [1]u8 = .{0x65};
pub const INVALID_OPCODE: [1]u8 = .{0x64};
