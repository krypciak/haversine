const std = @import("std");
const timer = @import("./timer.zig");

pub fn repetitionTest() !void {
    std.debug.print("\x1B[2J\x1B[H", .{});
    const allocator = std.heap.page_allocator;

    const cpuFreq = timer.estimateCpuTimerFreq();
    std.debug.print("cpuFreq: {d}\n", .{cpuFreq});

    const filePath = "./data/data_10000000_flex.json";
    const readArgs = ReadArgs{ .filePath = filePath };

    try runTest(allocator, cpuFreq, "readFileBuffer", readArgs, readFileBuffer);
    try runTest(allocator, cpuFreq, "readFileBuiltInAlloc", readArgs, readFileBuildInAlloc);
}

fn runTest(allocator: std.mem.Allocator, cpuFreq: u64, name: []const u8, comptime args: anytype, comptime func: anytype) !void {
    var bench = Bench{ .name = name, .cpuFreq = cpuFreq };

    while (!bench.finished) {
        try func(allocator, args, &bench);
    }
    bench.print();
}

const Bench = struct {
    name: []const u8,
    cpuFreq: u64,

    timesRun: usize = 0,
    minTime: u64 = std.math.maxInt(u64),
    maxTime: u64 = std.math.minInt(u64),
    noImprovementTimeoutMs: u64 = 10 * 1000,
    timeoutStart: u64 = 0,
    finished: bool = false,
    bytes: u64 = 0,
    printOnMinChange: bool = false,

    startTime: u64 = 0,
    endTime: u64 = 0,

    pub fn start(self: *Bench) void {
        self.startTime = timer.readCpuTimer();
    }

    pub fn end(self: *Bench) void {
        self.endTime = timer.readCpuTimer();
        self.timesRun += 1;

        const elapsed = self.endTime - self.startTime;

        self.maxTime = @max(self.maxTime, elapsed);

        if (self.minTime > elapsed) {
            self.minTime = elapsed;
            self.timeoutStart = timer.readCpuTimer();
            if (self.printOnMinChange) self.print();
        } else {
            if (self.timeoutStart <= self.endTime - timer.msToCpuTime(self.noImprovementTimeoutMs, self.cpuFreq)) {
                self.finished = true;
            }
        }
    }

    pub fn print(self: *const Bench) void {
        std.debug.print("{s}\n", .{self.name});
        const min_time_ms = timer.cpuTimeToMs(self.minTime, self.cpuFreq);
        // const max_time_ms = timer.cpuTimeToMs(self.maxTime, self.cpuFreq);

        std.debug.print("  min: {d:<12} {d:.2}ms", .{ self.minTime, min_time_ms });
        timer.printBandwidth(self.bytes, min_time_ms);
        std.debug.print("\n", .{});

        // std.debug.print("  max: {d:<12} {d:.2}ms", .{ self.maxTime, max_time_ms });
        // timer.printBandwidth(self.bytes, max_time_ms);
        // std.debug.print("\n", .{});

        std.debug.print("\n", .{});
    }
};

const ReadArgs = struct { filePath: []const u8 };

fn readFileBuffer(allocator: std.mem.Allocator, comptime args: ReadArgs, bench: *Bench) !void {
    const path = args.filePath;

    const file = try std.fs.cwd().openFile(path, .{});
    const file_size = (try file.stat()).size;

    const data = try allocator.alloc(u8, file_size);
    defer allocator.free(data);

    _ = try file.readAll(data);

    if (file_size != data.len) return error.ReadFileSizeMismatch;

    file.close();

    bench.bytes = file_size;
    bench.end();
}

fn readFileBuildInAlloc(allocator: std.mem.Allocator, comptime args: ReadArgs, bench: *Bench) !void {
    const path = args.filePath;

    const file = try std.fs.cwd().openFile(path, .{});
    const file_size = (try file.stat()).size;

    bench.start();

    const data = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(data);

    if (file_size != data.len) return error.ReadFileSizeMismatch;

    file.close();

    bench.bytes = file_size;
    bench.end();
}
