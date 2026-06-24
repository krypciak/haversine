const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBuffer = repetition_tester.wrapBuffer;

fn testSizes(allocator: std.mem.Allocator, comptime read_buffer_size: u64, comptime dest_buffer_size_multiplier: u64) !void {
    const read_buffer = try allocator.alloc(u8, read_buffer_size);
    defer allocator.free(read_buffer);

    for (0..read_buffer.len) |byte_index| {
        read_buffer[byte_index] = @truncate(byte_index);
    }

    const dest_buffer_size = read_buffer_size * dest_buffer_size_multiplier;
    const dest_buffer = try allocator.alloc(u8, dest_buffer_size);
    defer allocator.free(dest_buffer);
    std.debug.print("dest_buffer_size: {}\n", .{dest_buffer.len});

    var b1 = Bench{ .name = std.fmt.comptimePrint("CacheNonTemporal {}KiB -> {}MiB regular", .{ read_buffer_size / 1024, dest_buffer_size / 1024 / 1024 }) };
    try b1.runLoop(wrapBuffer, .{ dest_buffer, CacheNonTemporalRegular, .{ read_buffer.ptr, read_buffer.len } });

    var b2 = Bench{ .name = std.fmt.comptimePrint("CacheNonTemporal {}KiB -> {}MiB non temporal", .{ read_buffer_size / 1024, dest_buffer_size / 1024 / 1024 }) };
    try b2.runLoop(wrapBuffer, .{ dest_buffer, CacheNonTemporalNonTemporal, .{ read_buffer.ptr, read_buffer.len } });
}

pub fn repetitionTest(allocator: std.mem.Allocator) !void {
    const read_bytes_size = 8 * 1024;
    std.debug.print("read_bytes_size: {}\n", .{read_bytes_size});

    try testSizes(allocator, read_bytes_size, (1 * 1024 * 1024) / read_bytes_size);
    try testSizes(allocator, read_bytes_size, (8 * 1024 * 1024) / read_bytes_size);
    try testSizes(allocator, read_bytes_size, (64 * 1024 * 1024) / read_bytes_size);
    try testSizes(allocator, read_bytes_size, (512 * 1024 * 1024) / read_bytes_size);
}

extern fn CacheNonTemporalRegular(dest_buffer: [*]u8, dest_buffer_size: u64, read_buffer: [*]u8, read_buffer_size: u64) void;
extern fn CacheNonTemporalNonTemporal(dest_buffer: [*]u8, dest_buffer_size: u64, read_buffer: [*]u8, read_buffer_size: u64) void;
