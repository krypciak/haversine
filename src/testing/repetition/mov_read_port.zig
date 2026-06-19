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

    try repetition_testser.runTest("MOV1x1AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, MOV1x1AllBytesASM });
    try repetition_testser.runTest("MOV1x2AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, MOV1x2AllBytesASM });
    try repetition_testser.runTest("MOV1x3AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, MOV1x3AllBytesASM });
    try repetition_testser.runTest("MOV1x4AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, MOV1x4AllBytesASM });
    try repetition_testser.runTest("MOV1x5AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, MOV1x5AllBytesASM });
}

extern fn MOV1x1AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x2AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x3AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x4AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x5AllBytesASM(buffer: [*]u8, size: u64) void;
