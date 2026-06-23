const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBuffer = repetition_tester.wrapBuffer;

pub fn repetitionTest(allocator: std.mem.Allocator) !void {
    const outer_count = 64;
    const inner_count = 256;
    const cache_lane_size = 64;
    const stride_count = 128;

    const buffer = try allocator.alloc(u8, stride_count * inner_count * cache_lane_size);
    defer allocator.free(buffer);
    std.debug.print("bytes_size: {}\n", .{buffer.len});

    var byte_index: u64 = 0;
    while (byte_index < buffer.len) : (byte_index += 1) {
        buffer[byte_index] = @truncate(byte_index);
    }

    inline for (0..stride_count) |stride_i| {
        const stride: u64 = cache_lane_size * stride_i;
        @setEvalBranchQuota(50000);
        var b1 = Bench{ .name = std.fmt.comptimePrint("CacheIndexing stride {}", .{stride}) };
        try b1.runLoop(wrapBuffer, .{ buffer, ReadStrided, .{ outer_count, inner_count, stride } });
    }
}

extern fn ReadStrided(buffer: [*]u8, size: u64, outer_count: u64, inner_count: u64, stride: u64) void;
