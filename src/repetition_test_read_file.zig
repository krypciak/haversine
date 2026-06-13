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

    const filePath = "./data/data_10000000_flex.json";
    const readArgs = ReadArgs{ .filePath = filePath };

    // while (true) {
    try repetition_testser.runTest(allocator, io, cpuFreq, "readFileBuffer", readArgs, readFileBuffer);
    try repetition_testser.runTest(allocator, io, cpuFreq, "readFileBuffer2MB", readArgs, readFileBuffer2MB);
    try repetition_testser.runTest(allocator, io, cpuFreq, "readFileBufferReuse", readArgs, readFileBufferReuse);
    // }
}


const ReadArgs = struct { filePath: []const u8 };

fn readFileBuffer(allocator: std.mem.Allocator, io: std.Io, comptime args: ReadArgs, bench: *Bench) !void {
    const path = args.filePath;

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

fn readFileBuffer2MB(allocator: std.mem.Allocator, io: std.Io, comptime args: ReadArgs, bench: *Bench) !void {
    const path = args.filePath;

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

fn readFileBufferReuse(allocator: std.mem.Allocator, io: std.Io, comptime args: ReadArgs, bench: *Bench) !void {
    const path = args.filePath;

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
