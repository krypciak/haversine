const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;

pub fn repetitionTest(allocator: std.mem.Allocator, io: std.Io) !void {
    const filePath = "./data/data_10000000_flex.json";

    // while (true) {
    var b1 = Bench{ .name = "readFileBuffer" };
    try b1.runLoop(readFileBuffer, .{ allocator, io, filePath });

    var b2 = Bench{ .name = "readFileBuffer2MB" };
    try b2.runLoop(readFileBuffer2MB, .{ allocator, io, filePath });

    var b3 = Bench{ .name = "readFileBufferReuse" };
    try b3.runLoop(readFileBufferReuse, .{ allocator, io, filePath });

    // }
}

fn readFileBuffer(bench: *Bench, allocator: std.mem.Allocator, io: std.Io, path: []const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;

    try bench.start();

    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readPositionalAll(io, buffer, 0);

    if (file_size != buffer.len) return error.ReadFileSizeMismatch;

    file.close(io);

    bench.bytes = file_size;
    try bench.end();
}

fn readFileBuffer2MB(bench: *Bench, allocator: std.mem.Allocator, io: std.Io, path: []const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;
    const rounded_file_size = std.mem.alignForward(usize, file_size, 2 * 1024 * 1024);

    try bench.start();

    // does this actually work? probably no
    const buffer = try allocator.alignedAlloc(u8, std.mem.Alignment.fromByteUnits(4096), rounded_file_size);
    _ = try std.posix.madvise(
        buffer.ptr,
        buffer.len,
        std.posix.MADV.HUGEPAGE,
    );
    defer allocator.free(buffer);

    _ = try file.readPositionalAll(io, buffer, 0);

    if (rounded_file_size != buffer.len) return error.ReadFileSizeMismatch;

    file.close(io);

    bench.bytes = file_size;
    try bench.end();
}

var bufferSet = false;
var bufferReuse: []u8 = undefined;

fn readFileBufferReuse(bench: *Bench, allocator: std.mem.Allocator, io: std.Io, path: []const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    const file_size = (try file.stat(io)).size;

    try bench.start();

    if (!bufferSet) {
        bufferSet = true;
        bufferReuse = try allocator.alloc(u8, file_size);
        std.debug.print("allocating\n", .{});
    }
    const buffer = bufferReuse;

    _ = try file.readPositionalAll(io, buffer, 0);

    if (file_size != buffer.len) return error.ReadFileSizeMismatch;

    file.close(io);

    bench.bytes = file_size;
    try bench.end();
}
