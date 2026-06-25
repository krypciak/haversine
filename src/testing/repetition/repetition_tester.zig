const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

pub fn wrapBuffer(bench: *Bench, buffer: anytype, comptime func: anytype, args: anytype) !void {
    const bytes = buffer.len * @sizeOf(@TypeOf(buffer[0]));
    bench.bytes = bytes;

    try bench.start();
    _ = @call(.auto, func, .{ buffer.ptr, bytes } ++ args);
    try bench.end();
}

var csv_map: ?std.HashMap([]const u8, std.ArrayList(f64)) = null;

pub const Bench = struct {
    name: []const u8,

    times_run: usize = 0,
    min_time: u64 = std.math.maxInt(u64),
    max_time: u64 = std.math.minInt(u64),
    no_improvement_timeout_ms: u64 = 3 * 1000,
    timeout_start: u64 = 0,
    finished: bool = false,
    bytes: u64 = 0,
    print_on_min_change: bool = true,
    has_printed: bool = false,

    start_time: u64 = 0,
    end_time: u64 = 0,

    start_faults: posix.rusage = undefined,
    end_faults: posix.rusage = undefined,

    pub fn start(self: *Bench) !void {
        self.start_time = timer.readCpuTimer();
        self.end_time = 0;
        self.start_faults = posix.getrusage(posix.rusage.SELF);
    }

    pub fn end(self: *Bench) !void {
        self.end_time = timer.readCpuTimer();
        self.times_run += 1;

        self.end_faults = posix.getrusage(posix.rusage.SELF);

        const elapsed = self.end_time - self.start_time;

        self.max_time = @max(self.max_time, elapsed);

        if (self.min_time > elapsed) {
            self.min_time = elapsed;
            self.timeout_start = timer.readCpuTimer();
            if (self.print_on_min_change) self.print();
        } else {
            if (self.timeout_start <= self.end_time - timer.msToCpuTime(self.no_improvement_timeout_ms)) {
                self.finished = true;
            }
        }
    }

    pub fn print(self: *Bench) void {
        if (self.has_printed) {
            std.debug.print("\x1b[4A\x1b[J", .{});
        }
        self.has_printed = true;
        std.debug.print("{s}\n", .{self.name});
        const min_time_ms = timer.cpuTimeToMs(self.min_time);
        // const max_time_ms = timer.cpuTimeToMs(self.maxTime, cpuFreq);

        std.debug.print("  min: {d:<12} {d:.2}ms", .{ self.min_time, min_time_ms });
        timer.printThroughput(self.bytes, min_time_ms);
        std.debug.print("\n", .{});

        // std.debug.print("  max: {d:<12} {d:.2}ms", .{ self.maxTime, max_time_ms });
        // timer.printThroughput(self.bytes, max_time_ms);
        // std.debug.print("\n", .{});

        const minorFaults = self.end_faults.minflt - self.start_faults.minflt;
        const majorFaults = self.end_faults.majflt - self.start_faults.majflt;

        std.debug.print("  minor major faults: {d:<6} {d:<6}\n", .{ minorFaults, majorFaults });

        std.debug.print("\n", .{});
    }

    pub fn runLoop(self: *Bench, comptime func: anytype, args: anytype) !void {
        while (!self.finished) {
            try @call(.auto, func, .{self} ++ args);
        }
        self.print();
    }

    pub fn throughput(self: *Bench) f64 {
        return timer.throughput(self.bytes, timer.cpuTimeToMs(self.min_time)).throughput_gbps;
    }
};

pub fn run(allocator: std.mem.Allocator, io: std.Io, testType: []const u8) !void {
    if (std.mem.eql(u8, testType, "readFile")) {
        try @import("read_file.zig").repetitionTest(allocator, io);
    } else if (std.mem.eql(u8, testType, "writeBytes")) {
        try @import("write_bytes.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "conditionalNop")) {
        try @import("conditional_nop.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "movReadPort")) {
        try @import("mov_read_port.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "readWidths")) {
        try @import("read_widths.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "cacheSize")) {
        try @import("cache_size.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "cacheMisalignment")) {
        try @import("cache_misalignment.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "cacheIndexing")) {
        try @import("cache_indexing.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "cacheNonTemporal")) {
        try @import("cache_non_temporal.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "cachePrefetching")) {
        try @import("cache_prefetching.zig").repetitionTest(allocator);
    } else if (std.mem.eql(u8, testType, "readFileChunks")) {
        try @import("read_file_chunks.zig").repetitionTest(allocator, io);
    } else return error.UnknownTestType;
}
