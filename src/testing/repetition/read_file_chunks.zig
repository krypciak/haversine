const std = @import("std");
const timer = @import("timer");
const Csv = @import("./csv.zig").Csv;
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;

pub fn repetitionTest(allocator: std.mem.Allocator, io: std.Io) !void {
    const file_path = "./data/data_10000000_flex.json";

    const file_buffer = try std.Io.Dir.cwd().readFileAlloc(io, file_path, allocator, std.Io.Limit.unlimited);
    defer allocator.free(file_buffer);

    std.debug.print("file_buffer size: {} MiB\n", .{file_buffer.len / 1024 / 1024});

    var csv = Csv(f64).init(allocator);
    defer csv.deinit();

    const from = comptime std.math.log2_int(u64, 256 * 1024);
    const to = comptime std.math.log2_int(u64, 2 * 1024 * 1024 * 1024) + 1;
    inline for (from..to) |i| {
        const dest_buffer_size = 1 << i;
        {
            var b = Bench{ .name = std.fmt.comptimePrint("allocateAndTouch {} KiB", .{dest_buffer_size / 1024}) };
            try b.runLoop(allocateAndTouch, .{ allocator, dest_buffer_size });
            try csv.append("touch", b.throughput());
        }
        {
            var b = Bench{ .name = std.fmt.comptimePrint("allocateAndCopy {} KiB", .{dest_buffer_size / 1024}) };
            try b.runLoop(allocateAndCopy, .{ allocator, dest_buffer_size, file_buffer });
            try csv.append("copy", b.throughput());
        }
        {
            var b = Bench{ .name = std.fmt.comptimePrint("allocateAndReadFile {} KiB", .{dest_buffer_size / 1024}) };
            try b.runLoop(allocateAndReadFile, .{ allocator, io, dest_buffer_size, file_path });
            try csv.append("readFile", b.throughput());
        }
    }

    csv.print();
}

const memory_page_size = 4096;

fn allocateAndTouch(bench: *Bench, allocator: std.mem.Allocator, buffer_size: u64) !void {
    const rounded_buffer_size = std.mem.alignForward(usize, buffer_size, 2 * 1024 * 1024);
    const buffer = try allocator.alloc(u8, rounded_buffer_size);
    defer allocator.free(buffer);

    const touch_count = (buffer_size + memory_page_size - 1) / memory_page_size;

    try bench.start();

    for (0..touch_count) |touch_index| {
        buffer[memory_page_size * touch_index] = 0;
    }

    bench.bytes = buffer_size;
    try bench.end();
}

fn allocateAndCopy(bench: *Bench, allocator: std.mem.Allocator, buffer_size: u64, file_buffer: []const u8) !void {
    const rounded_buffer_size = std.mem.alignForward(usize, buffer_size, 2 * 1024 * 1024);
    const buffer = try allocator.alloc(u8, rounded_buffer_size);
    defer allocator.free(buffer);

    try bench.start();

    var file_index: u64 = 0;
    while (file_index < file_buffer.len) {
        const read_size = @min(buffer_size, file_buffer.len - file_index);
        @memcpy(buffer[0..read_size], file_buffer[file_index .. file_index + read_size]);
        file_index += read_size;
    }

    bench.bytes = file_buffer.len;
    try bench.end();
}

fn allocateAndReadFile(bench: *Bench, allocator: std.mem.Allocator, io: std.Io, buffer_size: u64, file_path: []const u8) !void {
    const rounded_buffer_size = std.mem.alignForward(usize, buffer_size, 2 * 1024 * 1024);
    const buffer = try allocator.alloc(u8, rounded_buffer_size);
    defer allocator.free(buffer);

    try bench.start();

    const file = try std.Io.Dir.cwd().openFile(io, file_path, .{});

    var file_index: u64 = 0;
    while (true) {
        const amt = try file.readPositional(io, &.{buffer}, file_index);
        if (amt == 0) break;

        file_index += amt;
    }
    file.close(io);

    bench.bytes = file_index;
    try bench.end();
}
