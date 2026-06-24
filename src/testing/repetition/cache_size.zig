const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBuffer = repetition_tester.wrapBuffer;

pub fn repetitionTest(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 500 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    for (0..buffer.len) |byte_index| {
        buffer[byte_index] = @truncate(byte_index);
    }

    const measure_at = [_]comptime_int{ 4, 8, 16, 24, 32, 40, 48, 60, 64, 98, 128, 256, 512, 768, 1024, 1536, 2048, 4096, 8192, 12288, 16384, 32768, 65536, 131072, 262144 };

    inline for (measure_at) |kib| {
        const inner_size = kib * 1024;
        const outer_count = buffer.len / inner_size;
        const bytes_count = inner_size * outer_count;
        const buffer_slice = buffer[0..bytes_count];

        var b1 = Bench{ .name = std.fmt.comptimePrint("CacheSizeMeasure {}KiB", .{kib}) };
        try b1.runLoop(wrapBuffer, .{ buffer_slice, CacheSizeMeasure, .{ outer_count, inner_size } });
    }
}

pub extern fn CacheSizeMeasure(buffer: [*]u8, size: u64, outer_count: u64, inner_size: u64) void;
