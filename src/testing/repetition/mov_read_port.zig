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

    var b1 = Bench{ .name = "MOV1x1AllBytesASM" };
    try b1.runLoop(wrapBuffer, .{ buffer, MOV1x1AllBytesASM, .{} });

    var b2 = Bench{ .name = "MOV1x2AllBytesASM" };
    try b2.runLoop(wrapBuffer, .{ buffer, MOV1x2AllBytesASM, .{} });

    var b3 = Bench{ .name = "MOV1x3AllBytesASM" };
    try b3.runLoop(wrapBuffer, .{ buffer, MOV1x3AllBytesASM, .{} });

    var b4 = Bench{ .name = "MOV1x4AllBytesASM" };
    try b4.runLoop(wrapBuffer, .{ buffer, MOV1x4AllBytesASM, .{} });

    var b5 = Bench{ .name = "MOV1x5AllBytesASM" };
    try b5.runLoop(wrapBuffer, .{ buffer, MOV1x5AllBytesASM, .{} });
}

extern fn MOV1x1AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x2AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x3AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x4AllBytesASM(buffer: [*]u8, size: u64) void;
extern fn MOV1x5AllBytesASM(buffer: [*]u8, size: u64) void;
