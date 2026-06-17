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

    const bytes_size: u64 = 100 * 1024 * 1024;
    std.debug.print("bytes_size: {}\n", .{bytes_size});

    const buffer = try allocator.alloc(u8, bytes_size);
    defer allocator.free(buffer);

    // while (true) {
    try repetition_testser.runTest("writeToAllBytes", cpuFreq, benchWrap, .{ buffer, writeToAllBytes });
    try repetition_testser.runTest("MOVAllBytesASM", cpuFreq, benchWrap, .{ buffer, MOVAllBytesASM });
    try repetition_testser.runTest("NOPAllBytesASM", cpuFreq, benchWrap, .{ buffer, NOPAllBytesASM });
    try repetition_testser.runTest("CMPAllBytesASM", cpuFreq, benchWrap, .{ buffer, CMPAllBytesASM });
    try repetition_testser.runTest("DECAllBytesASM", cpuFreq, benchWrap, .{ buffer, DECAllBytesASM });
    // }
}

fn benchWrap(buffer: []u8, func: anytype, bench: *Bench) !void {
    try bench.start();

    const len: u64 = @intCast(buffer.len);
    _ = @call(.auto, func, .{ buffer.ptr, len });

    try bench.end();

    var sum: u64 = 0;
    var i: u64 = 0;
    while (i < buffer.len) : (i += 256) {
        sum +%= buffer[i];
    }
    std.debug.assert(sum == 0);

    bench.bytes = buffer.len;
}

fn writeToAllBytes(buffer: [*]u8, size: u64) void {
    var i: u64 = 0;
    while (i < size) : (i += 1) {
        buffer[i] = @truncate(i);
    }
}

extern fn MOVAllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn NOPAllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn CMPAllBytesASM(buffer: [*]u8, size: u64) u64;
extern fn DECAllBytesASM(buffer: [*]u8, size: u64) void;
