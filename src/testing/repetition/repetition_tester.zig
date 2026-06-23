const std = @import("std");
const timer = @import("timer");
const posix = std.posix;

pub fn wrapBuffer(bench: *Bench, buffer: []u8, comptime func: anytype, args: anytype) !void {
    bench.bytes = buffer.len;
    try bench.start();
    _ = @call(.auto, func, .{ buffer.ptr, buffer.len } ++ args);
    try bench.end();
}

var cpuFreq: u64 = 0;
pub fn setCpuFreq(freq: u64) void {
    cpuFreq = freq;
}

pub const Bench = struct {
    name: []const u8,

    timesRun: usize = 0,
    minTime: u64 = std.math.maxInt(u64),
    maxTime: u64 = std.math.minInt(u64),
    noImprovementTimeoutMs: u64 = 3 * 1000,
    timeoutStart: u64 = 0,
    finished: bool = false,
    bytes: u64 = 0,
    printOnMinChange: bool = true,
    hasPrinted: bool = false,

    startTime: u64 = 0,
    endTime: u64 = 0,

    startFaults: posix.rusage = undefined,
    endFaults: posix.rusage = undefined,

    pub fn start(self: *Bench) !void {
        self.startTime = timer.readCpuTimer();
        self.endTime = 0;
        self.startFaults = posix.getrusage(posix.rusage.SELF);
    }

    pub fn end(self: *Bench) !void {
        self.endTime = timer.readCpuTimer();
        self.timesRun += 1;

        self.endFaults = posix.getrusage(posix.rusage.SELF);

        const elapsed = self.endTime - self.startTime;

        self.maxTime = @max(self.maxTime, elapsed);

        if (self.minTime > elapsed) {
            self.minTime = elapsed;
            self.timeoutStart = timer.readCpuTimer();
            if (self.printOnMinChange) self.print();
        } else {
            if (self.timeoutStart <= self.endTime - timer.msToCpuTime(self.noImprovementTimeoutMs, cpuFreq)) {
                self.finished = true;
            }
        }
    }

    pub fn print(self: *Bench) void {
        if (self.hasPrinted) {
            std.debug.print("\x1b[4A\x1b[J", .{});
        }
        self.hasPrinted = true;
        std.debug.print("{s}\n", .{self.name});
        const min_time_ms = timer.cpuTimeToMs(self.minTime, cpuFreq);
        // const max_time_ms = timer.cpuTimeToMs(self.maxTime, cpuFreq);

        std.debug.print("  min: {d:<12} {d:.2}ms", .{ self.minTime, min_time_ms });
        timer.printBandwidth(self.bytes, min_time_ms);
        std.debug.print("\n", .{});

        // std.debug.print("  max: {d:<12} {d:.2}ms", .{ self.maxTime, max_time_ms });
        // timer.printBandwidth(self.bytes, max_time_ms);
        // std.debug.print("\n", .{});

        const minorFaults = self.endFaults.minflt - self.startFaults.minflt;
        const majorFaults = self.endFaults.majflt - self.startFaults.majflt;

        std.debug.print("  minor major faults: {d:<6} {d:<6}\n", .{ minorFaults, majorFaults });

        std.debug.print("\n", .{});
    }

    pub fn runLoop(self: *Bench, comptime func: anytype, args: anytype) !void {
        while (!self.finished) {
            try @call(.auto, func, .{self} ++ args);
        }
        self.print();
    }
};

pub fn run(allocator: std.mem.Allocator, io: std.Io, testType: []const u8) !void {
    setCpuFreq(timer.estimateCpuTimerFreq(io));
    std.debug.print("cpuFreq: {d}\n", .{cpuFreq});

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
    } else return error.UnknownTestType;
}
