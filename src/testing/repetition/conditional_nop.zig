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

    var i: u64 = 0;

    @memset(buffer, 0);
    var b1 = Bench{ .name = "CondNOPAllBytesASM all 0" };
    try b1.runLoop(wrapBuffer, .{ buffer, CondNOPAllBytesASM, .{} });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 1) {
        buffer[i] = 1;
    }
    var b2 = Bench{ .name = "CondNOPAllBytesASM all 1" };
    try b2.runLoop(wrapBuffer, .{ buffer, CondNOPAllBytesASM, .{} });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 2) {
        buffer[i] = 1;
    }
    var b3 = Bench{ .name = "CondNOPAllBytesASM 1 every 2" };
    try b3.runLoop(wrapBuffer, .{ buffer, CondNOPAllBytesASM, .{} });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 3) {
        buffer[i] = 1;
    }
    var b4 = Bench{ .name = "CondNOPAllBytesASM 1 every 3" };
    try b4.runLoop(wrapBuffer, .{ buffer, CondNOPAllBytesASM, .{} });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 4) {
        buffer[i] = 1;
    }
    var b5 = Bench{ .name = "CondNOPAllBytesASM 1 every 4" };
    try b5.runLoop(wrapBuffer, .{ buffer, CondNOPAllBytesASM, .{} });

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    random.bytes(buffer);
    var b6 = Bench{ .name = "CondNOPAllBytesASM random" };
    try b6.runLoop(wrapBuffer, .{ buffer, CondNOPAllBytesASM, .{} });
}

extern fn CondNOPAllBytesASM(buffer: [*]u8, size: u64) u64;
