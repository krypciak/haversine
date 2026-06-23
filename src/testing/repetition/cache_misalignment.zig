const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBuffer = repetition_tester.wrapBuffer;
const CacheSizeMeasure = @import("./cache_size.zig").CacheSizeMeasure;

pub fn repetitionTest(allocator: std.mem.Allocator) !void {
    const bytes_size = 500 * 1024 * 1024;
    const buffer = try allocator.alloc(u8, bytes_size);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    var byte_index: u64 = 0;
    while (byte_index < buffer.len) : (byte_index += 1) {
        buffer[byte_index] = @truncate(byte_index);
    }

    const alignments = [_]comptime_int{ 0, 1, 2, 3, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 257 };
    const sizes_kib = [_]comptime_int{ 8, 256, 8 * 1024, bytes_size / 1024 - 512 };

    inline for (sizes_kib) |kib| {
        inline for (alignments) |alignment| {
            const inner_size = kib * 1024;
            const outer_count = buffer.len / inner_size;
            const bytes_count = inner_size * outer_count;
            var buffer_slice = buffer[0..bytes_count];
            buffer_slice.ptr += alignment;

            @setEvalBranchQuota(50000);
            var b1 = Bench{ .name = std.fmt.comptimePrint("CacheMisalignment {}KiB +{}", .{ kib, alignment }) };
            try b1.runLoop(wrapBuffer, .{ buffer_slice, CacheSizeMeasure, .{ outer_count, inner_size } });
        }
    }
}
