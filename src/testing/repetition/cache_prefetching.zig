const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;
const wrapBuffer = repetition_tester.wrapBuffer;

pub fn repetitionTest(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u256, 8 * 1024 * 1024);
    defer allocator.free(buffer);
    std.debug.print("buffer_size: {}\n", .{buffer.len});

    for (0..buffer.len - 1) |i| {
        buffer[i] = (@as(u256, i) << 128) + @intFromPtr(&buffer[i + 1]);
    }
    buffer[buffer.len - 1] = @intFromPtr(&buffer[0]);

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    std.Random.shuffle(random, u256, buffer);

    const inner_counts = [_]comptime_int{ 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 128, 192, 256, 320, 384, 448, 512, 576, 640, 704, 768, 832, 896, 960, 1024, 1088 };
    inline for (inner_counts) |inner_count| {
        var b1 = Bench{ .name = std.fmt.comptimePrint("CachePrefetch normal {}", .{inner_count}) };
        try b1.runLoop(wrapBuffer, .{ buffer, CachePrefetchNormal, .{inner_count} });

        var b2 = Bench{ .name = std.fmt.comptimePrint("CachePrefetch prefetch {}", .{inner_count}) };
        try b2.runLoop(wrapBuffer, .{ buffer, CachePrefetchPrefetch, .{inner_count} });
    }
}

extern fn CachePrefetchNormal(buffer: [*]u256, size: u64, inner_count: u64) void;
extern fn CachePrefetchPrefetch(buffer: [*]u256, size: u64, inner_count: u64) void;
