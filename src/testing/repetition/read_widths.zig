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

    // try repetition_tester.runTest("Read32x1AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read32x1AllBytesASM });
    // try repetition_tester.runTest("Read32x2AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read32x2AllBytesASM });
    // try repetition_tester.runTest("Read32x3AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read32x3AllBytesASM });
    // try repetition_tester.runTest("Read32x4AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read32x4AllBytesASM });
    // try repetition_tester.runTest("Read32x5AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read32x5AllBytesASM });
    //
    // try repetition_tester.runTest("Read64x1AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read64x1AllBytesASM });
    // try repetition_tester.runTest("Read64x2AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read64x2AllBytesASM });
    // try repetition_tester.runTest("Read64x3AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read64x3AllBytesASM });
    // try repetition_tester.runTest("Read64x4AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read64x4AllBytesASM });
    // try repetition_tester.runTest("Read64x5AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read64x5AllBytesASM });

    try repetition_tester.runTest("Read128x1AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read128x1AllBytesASM });
    try repetition_tester.runTest("Read128x2AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read128x2AllBytesASM });
    try repetition_tester.runTest("Read128x3AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read128x3AllBytesASM });
    try repetition_tester.runTest("Read128x4AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read128x4AllBytesASM });
    // try repetition_tester.runTest("Read128x5AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read128x5AllBytesASM });

    try repetition_tester.runTest("Read256x1AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read256x1AllBytesASM });
    try repetition_tester.runTest("Read256x2AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read256x2AllBytesASM });
    try repetition_tester.runTest("Read256x3AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read256x3AllBytesASM });
    try repetition_tester.runTest("Read256x4AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read256x4AllBytesASM });
    // try repetition_tester.runTest("Read256x5AllBytesASM", cpuFreq, wrapBufferTest, .{ buffer, Read256x5AllBytesASM });
}

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
