const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBuffer = repetition_tester.wrapBuffer;

pub fn repetitionTest(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 100 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    const widths = [_]comptime_int{ 32, 64, 128, 256 };
    inline for (widths, 0..) |w, wi| {
        inline for (1..6) |n| {
            const func = asm_functions[wi][n - 1];
            var b1 = Bench{ .name = std.fmt.comptimePrint("Read{}x{}AllBytesAsm", .{ w, n }) };
            try b1.runLoop(wrapBuffer, .{ buffer, func, .{} });
        }
    }
}

const asm_functions = [_][5]*const fn ([*]u8, u64) callconv(.c) void{
    .{
        Read32x1AllBytesASM,
        Read32x2AllBytesASM,
        Read32x3AllBytesASM,
        Read32x4AllBytesASM,
        Read32x5AllBytesASM,
    },
    .{
        Read64x1AllBytesASM,
        Read64x2AllBytesASM,
        Read64x3AllBytesASM,
        Read64x4AllBytesASM,
        Read64x5AllBytesASM,
    },
    .{
        Read128x1AllBytesASM,
        Read128x2AllBytesASM,
        Read128x3AllBytesASM,
        Read128x4AllBytesASM,
        Read128x5AllBytesASM,
    },
    .{
        Read256x1AllBytesASM,
        Read256x2AllBytesASM,
        Read256x3AllBytesASM,
        Read256x4AllBytesASM,
        Read256x5AllBytesASM,
    },
};

extern fn Read32x1AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read32x2AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read32x3AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read32x4AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read32x5AllBytesASM(buffer: [*]u8, size: u64) void;

extern fn Read64x1AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read64x2AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read64x3AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read64x4AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read64x5AllBytesASM(buffer: [*]u8, size: u64) void;

extern fn Read128x1AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read128x2AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read128x3AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read128x4AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read128x5AllBytesASM(buffer: [*]u8, size: u64) void;

extern fn Read256x1AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read256x2AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read256x3AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read256x4AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn Read256x5AllBytesASM(buffer: [*]u8, size: u64) void;
