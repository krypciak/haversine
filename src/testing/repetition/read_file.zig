const std = @import("std");
const timer = @import("timer");

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;

pub fn repetitionTest(allocator: std.mem.Allocator, io: std.Io) !void {
    const filePath = "./data/data_10000000_flex.json";

    // while (true) {
    var b1 = Bench{ .name = "readFileBuffer" };
    const b1sum: u64 = try b1.runLoop(readFileBuffer, .{ allocator, io, filePath });
    std.debug.print("sum: {}\n", .{b1sum});

    var b2 = Bench{ .name = "readFileBuffer2MB" };
    const b2sum: u64 = try b2.runLoop(readFileBuffer2MB, .{ io, filePath });
    std.debug.assert(b1sum == b2sum);
    std.debug.print("sum: {}\n", .{b2sum});

    var b3 = Bench{ .name = "readFileBufferReuse" };
    const b3sum: u64 = try b3.runLoop(readFileBufferReuse, .{ allocator, io, filePath });
    std.debug.assert(b1sum == b3sum);
    std.debug.print("sum: {}\n", .{b3sum});

    var b4 = Bench{ .name = "readFileMemoryMapped" };
    const b4sum: u64 = try b4.runLoop(readFileMemoryMapped, .{ io, filePath });
    std.debug.assert(b1sum == b4sum);
    std.debug.print("sum: {}\n", .{b4sum});

    // }
}

fn readFileBuffer(bench: *Bench, allocator: std.mem.Allocator, io: std.Io, path: []const u8) !u64 {
    try bench.start();

    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;

    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readPositionalAll(io, buffer, 0);

    if (file_size != buffer.len) return error.ReadFileSizeMismatch;

    var sum: u64 = 0;
    for (0..buffer.len) |i| {
        sum += buffer[i];
    }

    file.close(io);

    bench.bytes = file_size;
    try bench.end();

    return sum;
}

fn readFileBuffer2MB(bench: *Bench, io: std.Io, path: []const u8) !u64 {
    try bench.start();

    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;
    const rounded_file_size = std.mem.alignForward(usize, file_size, 2 * 1024 * 1024);

    const buffer = try std.posix.mmap(
        null,
        rounded_file_size,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );

    defer std.posix.munmap(buffer);

    _ = try file.readPositionalAll(io, buffer, 0);

    if (rounded_file_size != buffer.len) return error.ReadFileSizeMismatch;

    var sum: u64 = 0;
    for (0..buffer.len) |i| {
        sum += buffer[i];
    }

    file.close(io);

    bench.bytes = file_size;
    try bench.end();

    return sum;
}

var bufferSet = false;
var bufferReuse: []u8 = undefined;

fn readFileBufferReuse(bench: *Bench, allocator: std.mem.Allocator, io: std.Io, path: []const u8) !u64 {
    try bench.start();

    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;

    if (!bufferSet) {
        bufferSet = true;
        bufferReuse = try allocator.alloc(u8, file_size);
        std.debug.print("allocating\n", .{});
    }
    const buffer = bufferReuse;

    _ = try file.readPositionalAll(io, buffer, 0);

    if (file_size != buffer.len) return error.ReadFileSizeMismatch;

    var sum: u64 = 0;
    for (0..buffer.len) |i| {
        sum += buffer[i];
    }

    file.close(io);

    bench.bytes = file_size;
    try bench.end();

    return sum;
}

fn readFileMemoryMapped(bench: *Bench, io: std.Io, path: []const u8) !u64 {
    try bench.start();

    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;

    const buffer: []align(4096) const u8 = try std.posix.mmap(
        null,
        file_size,
        .{ .READ = true },
        .{ .TYPE = .PRIVATE },
        file.handle,
        0,
    );
    defer std.posix.munmap(buffer);

    if (file_size != buffer.len) return error.ReadFileSizeMismatch;

    var sum: u64 = 0;
    for (0..buffer.len) |i| {
        sum += buffer[i];
    }

    file.close(io);

    bench.bytes = file_size;
    try bench.end();

    return sum;
}
