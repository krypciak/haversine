const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;

pub fn repetitionTest(allocator: std.mem.Allocator, cpuFreq: u64) !void {
    const buffer = try allocator.alloc(u8, 500 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    var byte_index: u64 = 0;
    while (byte_index < buffer.len) : (byte_index += 1) {
        buffer[byte_index] = @truncate(byte_index);
    }

    const measure_at = [_]u64{ 4, 8, 16, 24, 32, 40, 48, 60, 64, 98, 128, 256, 512, 768, 1024, 1536, 2048, 4096, 8192, 12288, 16384, 32768, 65536, 131072, 262144 };

    var i: u64 = 0;
    while (i < measure_at.len) : (i += 1) {
        const kib = measure_at[i];

        const test_name = try std.fmt.allocPrint(allocator, "CacheSizeMeasure {}KiB", .{kib});
        try repetition_tester.runTest(test_name, cpuFreq, wrapBufferTest, .{ buffer, kib });
    }
}

pub fn wrapBufferTest(buffer: []u8, kib: u64, bench: *Bench) !void {
    const inner_size = kib * 1024;
    const outer_count = buffer.len / inner_size;
    const bytes_count = inner_size * outer_count;
    // std.debug.print("{} KiB, inner_size: {} B, outer_count: {}, bytes_count: {} \n", .{ kib, inner_size, outer_count, bytes_count });

    try bench.start();
    CacheSizeMeasure(buffer.ptr, outer_count, inner_size);
    try bench.end();

    bench.bytes = bytes_count;
}

extern fn CacheSizeMeasure(buffer: [*]u8, outer_count: u64, inner_size: u64) void;
