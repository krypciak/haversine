const std = @import("std");
const timer = @import("./timer.zig");
const posix = std.posix;

const repetition_testser = @import("./repetition_tester.zig");
const Bench = repetition_testser.Bench;

pub fn repetitionTest(io: std.Io) !void {
    std.debug.print("\x1B[2J\x1B[H", .{});
    const allocator = std.heap.page_allocator;

    const cpuFreq = timer.estimateCpuTimerFreq(io);
    std.debug.print("cpuFreq: {d}\n", .{cpuFreq});

    const readArgs = ReadArgs{ .bytes_size = 100 * 1024 * 1024 };

    // while (true) {
    try repetition_testser.runTest(allocator, io, cpuFreq, "writeToAllBytes", readArgs, writeToAllBytes);
    // }
}

const ReadArgs = struct { bytes_size: u64 };

fn writeToAllBytes(allocator: std.mem.Allocator, io: std.Io, comptime args: ReadArgs, bench: *Bench) !void {
    _ = io;
    const bytes_size = args.bytes_size;

    const buffer = try allocator.alloc(u8, bytes_size);
    defer allocator.free(buffer);

    try bench.start();

    var i: u64 = 0;
    while (i < bytes_size) : (i += 1) {
        buffer[i] = @truncate(i);
    }

    try bench.end();

    var sum: u64 = 0;
    i = 0;
    while (i < bytes_size) : (i += 256) {
        sum +%= buffer[i];
    }
    std.debug.assert(sum == 0);

    bench.bytes = buffer.len;
}
