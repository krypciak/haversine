const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;

const wrapBufferTest = @import("./cache_size.zig").wrapBufferTest;

pub fn repetitionTest(allocator: std.mem.Allocator, cpuFreq: u64) !void {
    const buffer = try allocator.alloc(u8, 500 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    var byte_index: u64 = 0;
    while (byte_index < buffer.len) : (byte_index += 1) {
        buffer[byte_index] = @truncate(byte_index);
    }

    const alignments = [_]u64{ 0, 1, 2, 3, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 257 };
    const sizes_kib = [_]u64{ 8, 256, 8 * 1024, buffer.len / 1024 - 512 };

    for (sizes_kib) |kib| {
        for (alignments) |alignment| {
            const test_name = try std.fmt.allocPrint(allocator, "CacheMisalignment {}KiB +{}", .{ kib, alignment });
            _ = try repetition_tester.runTest(test_name, cpuFreq, wrapBufferTest, .{ buffer, kib, alignment });
        }
    }
}
