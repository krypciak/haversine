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

    var b1 = Bench{ .name = "writeToAllBytes" };
    try b1.runLoop(wrapBuffer, .{ buffer, writeToAllBytes, .{} });

    var b2 = Bench{ .name = "MOVAllBytesASM" };
    try b2.runLoop(wrapBuffer, .{ buffer, MOVAllBytesASM, .{} });

    var b3 = Bench{ .name = "CMPAllBytesASM" };
    try b3.runLoop(wrapBuffer, .{ buffer, CMPAllBytesASM, .{} });

    var b4 = Bench{ .name = "DECAllBytesASM" };
    try b4.runLoop(wrapBuffer, .{ buffer, DECAllBytesASM, .{} });
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
