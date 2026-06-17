const std = @import("std");
const timer = @import("./timer.zig");
const posix = std.posix;

const repetition_testser = @import("./repetition_tester.zig");
const Bench = repetition_testser.Bench;

pub fn repetitionTest(io: std.Io) !void {
    std.debug.print("\x1B[2J\x1B[H", .{});
    const allocator = std.heap.page_allocator;

    const cpuFreq = timer.estimateCpuTimerFreq(io);
    std.debug.print("cpuFreq: {d}\n", .{cpuFreq});

    const buffer = try allocator.alloc(u8, 100 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    // try writeTests(cpuFreq, buffer);
    try condJumpTests(cpuFreq, buffer);
}

fn writeTests(cpuFreq: u64, buffer: []u8) !void {
    try repetition_testser.runTest("writeToAllBytes", cpuFreq, benchWrap, .{ buffer, writeToAllBytes });
    try repetition_testser.runTest("MOVAllBytesASM", cpuFreq, benchWrap, .{ buffer, MOVAllBytesASM });
    try repetition_testser.runTest("CMPAllBytesASM", cpuFreq, benchWrap, .{ buffer, CMPAllBytesASM });
    try repetition_testser.runTest("DECAllBytesASM", cpuFreq, benchWrap, .{ buffer, DECAllBytesASM });
    try repetition_testser.runTest("NOP3x1AllBytesASM", cpuFreq, benchWrap, .{ buffer, NOP3x1AllBytesASM });
    try repetition_testser.runTest("NOP1x3AllBytesASM", cpuFreq, benchWrap, .{ buffer, NOP1x3AllBytesASM });
    try repetition_testser.runTest("NOP3x3AllBytesASM", cpuFreq, benchWrap, .{ buffer, NOP3x3AllBytesASM });
    try repetition_testser.runTest("NOP1x9AllBytesASM", cpuFreq, benchWrap, .{ buffer, NOP1x9AllBytesASM });
}

fn condJumpTests(cpuFreq: u64, buffer: []u8) !void {
    var i: u64 = 0;

    @memset(buffer, 0);
    try repetition_testser.runTest("CondNOPAllBytesASM all 0", cpuFreq, benchWrap, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 1) {
        buffer[i] = 1;
    }
    try repetition_testser.runTest("CondNOPAllBytesASM all 1", cpuFreq, benchWrap, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 2) {
        buffer[i] = 1;
    }
    try repetition_testser.runTest("CondNOPAllBytesASM 1 every 2", cpuFreq, benchWrap, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 3) {
        buffer[i] = 1;
    }
    try repetition_testser.runTest("CondNOPAllBytesASM 1 every 3", cpuFreq, benchWrap, .{ buffer, CondNOPAllBytesASM });

    @memset(buffer, 0);
    i = 0;
    while (i < buffer.len) : (i += 4) {
        buffer[i] = 1;
    }
    try repetition_testser.runTest("CondNOPAllBytesASM 1 every 4", cpuFreq, benchWrap, .{ buffer, CondNOPAllBytesASM });

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    random.bytes(buffer);
    try repetition_testser.runTest("CondNOPAllBytesASM random", cpuFreq, benchWrap, .{ buffer, CondNOPAllBytesASM });
}

fn benchWrap(buffer: []u8, func: anytype, bench: *Bench) !void {
    try bench.start();

    const len: u64 = @intCast(buffer.len);
    _ = @call(.auto, func, .{ buffer.ptr, len });

    try bench.end();

    // var sum: u64 = 0;
    // var i: u64 = 0;
    // while (i < buffer.len) : (i += 256) {
    //     sum +%= buffer[i];
    // }
    // std.debug.assert(sum == 0);

    bench.bytes = buffer.len;
}

fn writeToAllBytes(buffer: [*]u8, size: u64) void {
    var i: u64 = 0;
    while (i < size) : (i += 1) {
        buffer[i] = @truncate(i);
    }
}

extern fn MOVAllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn CMPAllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn DECAllBytesASM(buffer: [*]u8, size: u64) void;
extern fn NOP3x1AllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn NOP1x3AllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn NOP3x3AllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn NOP1x9AllBytesASM(buffer: [*]u8, size: u64) u64;

extern fn CondNOPAllBytesASM(buffer: [*]u8, size: u64) u64;
