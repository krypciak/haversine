const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_testser = @import("./repetition_tester.zig");
const Bench = repetition_testser.Bench;
const wrapBufferTest = repetition_testser.wrapBufferTest;

pub fn repetitionTest(allocator: std.mem.Allocator, cpuFreq: u64) !void {
    const buffer = try allocator.alloc(u8, 100 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    try repetition_testser.runTest("writeToAllBytes", cpuFreq, wrapBufferTest, .{ buffer, writeToAllBytes });
    try repetition_testser.runTest("MOVAllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, MOVAllBytesASM });
    try repetition_testser.runTest("CMPAllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, CMPAllBytesASM });
    try repetition_testser.runTest("DECAllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, DECAllBytesASM });
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
