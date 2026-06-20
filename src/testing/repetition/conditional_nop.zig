const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBufferTest = repetition_tester.wrapBufferTest;

pub fn repetitionTest(allocator: std.mem.Allocator, cpuFreq: u64) !void {
    const buffer = try allocator.alloc(u8, 100 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    var i: u64 = 0;

    @memset(buffer, 0);
    try repetition_tester.runTest("CondNOPAllBytesASM all 0", cpuFreq, wrapBufferTest, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 1) {
        buffer[i] = 1;
    }
    try repetition_tester.runTest("CondNOPAllBytesASM all 1", cpuFreq, wrapBufferTest, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 2) {
        buffer[i] = 1;
    }
    try repetition_tester.runTest("CondNOPAllBytesASM 1 every 2", cpuFreq, wrapBufferTest, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 3) {
        buffer[i] = 1;
    }
    try repetition_tester.runTest("CondNOPAllBytesASM 1 every 3", cpuFreq, wrapBufferTest, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 4) {
        buffer[i] = 1;
    }
    try repetition_tester.runTest("CondNOPAllBytesASM 1 every 4", cpuFreq, wrapBufferTest, .{ buffer, CondNOPAllBytesASM });

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    random.bytes(buffer);
    try repetition_tester.runTest("CondNOPAllBytesASM random", cpuFreq, wrapBufferTest, .{ buffer, CondNOPAllBytesASM });
}

extern fn CondNOPAllBytesASM(buffer: [*]u8, size: u64) u64;
