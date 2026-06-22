const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

const repetition_tester = @import("./repetition_tester.zig");
const Bench = repetition_tester.Bench;

pub fn repetitionTest(allocator: std.mem.Allocator, io: std.Io, cpuFreq: u64) !void {
    const filePath = "./data/data_10000000_flex.json";

    // while (true) {
    _ = try repetition_tester.runTest("readFileBuffer", cpuFreq, readFileBuffer, .{ allocator, io, filePath });
    _ = try repetition_tester.runTest("readFileBuffer2MB", cpuFreq, readFileBuffer2MB, .{ allocator, io, filePath });
    _ = try repetition_tester.runTest("readFileBufferReuse", cpuFreq, readFileBufferReuse, .{ allocator, io, filePath });
    // }
}

fn readFileBuffer(allocator: std.mem.Allocator, io: std.Io, path: []const u8, bench: *Bench) !void {
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

fn readFileBuffer2MB(allocator: std.mem.Allocator, io: std.Io, path: []const u8, bench: *Bench) !void {
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

fn readFileBufferReuse(allocator: std.mem.Allocator, io: std.Io, path: []const u8, bench: *Bench) !void {
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
