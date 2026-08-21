const builtin = @import("builtin");

pub const impl = switch (builtin.cpu.arch) {
    .aarch64 => @import("aarch64/syscalln.zig"),
    .x86_64 => @import("x86_64/syscalln.zig"),
    else => @compileError("Unsupported arch"),
};

pub const num = switch (builtin.cpu.arch) {
    .aarch64 => @import("aarch64/num.zig"),
    .x86_64 => @import("x86_64/num.zig"),
    else => @compileError("Unsupported arch"),
};
