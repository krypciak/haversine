const std = @import("std");

inline fn rdtsc() u64 {
    var hi: u32 = 0;
    var low: u32 = 0;

    asm (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

pub inline fn readCpuTimer() u64 {
    return rdtsc();
}

inline fn getOsTimerFreq() u64 {
    return 1000000;
}

inline fn readOsTimer() u64 {
    return @intCast(std.time.microTimestamp());
}

fn estimateCpuTimerFreq() u64 {
    const miliseconds_to_wait: u64 = 100;
    const os_freq: u64 = getOsTimerFreq();

    const cpu_start: u64 = readCpuTimer();
    const os_start: u64 = readOsTimer();
    var os_end: u64 = 0;
    var os_elapsed: u64 = 0;

    const os_wait_time: u64 = os_freq * miliseconds_to_wait / 1000;
    while (os_elapsed < os_wait_time) {
        os_end = readOsTimer();
        os_elapsed = os_end - os_start;
    }

    const cpu_end: u64 = readCpuTimer();
    const cpu_elapsed: u64 = cpu_end - cpu_start;

    var cpu_freq: u64 = 0;
    if (os_elapsed != 0) {
        cpu_freq = os_freq * cpu_elapsed / os_elapsed;
    }

    return cpu_freq;
}

const TimerMapEntry = struct {
    entries: std.ArrayList(*TimerEntry),
};

const TimerEntry = struct { label: []const u8, start: u64, end: u64, depth: usize };

var timer_allocator: std.mem.Allocator = undefined;
var timer_stack: std.ArrayList(*TimerEntry) = undefined;
var timer_entries: std.ArrayList(TimerEntry) = undefined;
// var timer_map: std.StringHashMap(TimerMapEntry) = undefined;
var timer_begin: u64 = undefined;

pub fn initTimer(allocator: std.mem.Allocator) !void {
    timer_allocator = allocator;
    const capacity: usize = 50;
    timer_stack = try std.ArrayList(*TimerEntry).initCapacity(timer_allocator, capacity);
    timer_entries = try std.ArrayList(TimerEntry).initCapacity(timer_allocator, capacity);
    // timer_map = std.StringHashMap(TimerMapEntry).init(timer_allocator);
    timer_begin = readCpuTimer();
}

pub inline fn start(label: []const u8) !void {
    // var last = timer_stack.getLastOrNull();

    const index = timer_entries.items.len;
    try timer_entries.append(.{ .label = label, .start = readCpuTimer(), .end = 0, .depth = timer_stack.items.len });
    const node_ptr = &timer_entries.items[index];
    try timer_stack.append(node_ptr);

    // const map_entry = try timer_map.getOrPutValue(label, .{ .entries = std.ArrayList(*TimerEntry).init(timer_allocator) });
    // try map_entry.value_ptr.entries.append(node_ptr);
    //
    // if (last) |*last_node| {
    //     try last_node.*.children.append(node_ptr);
    // }
}

pub inline fn stop() void {
    var last = timer_stack.pop();
    if (last) |*entry| {
        entry.*.end = readCpuTimer();
    } else unreachable;
}

pub fn finalize() !void {
    const all_elapsed = readCpuTimer() - timer_begin;
    const cpu_freq = estimateCpuTimerFreq();
    const all_elapsed_ms = 1000 * @as(f64, @floatFromInt(all_elapsed)) / @as(f64, @floatFromInt(cpu_freq));

    std.debug.print("total time               : {d} {d:.2}ms (CPU freq: {d})\n", .{ all_elapsed, all_elapsed_ms, cpu_freq });

    for (timer_entries.items) |*entry| {
        const elapsed: u64 = entry.end - entry.start;
        const percent: f64 = 100.0 * (@as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(all_elapsed)));

        var i: usize = 0;
        while (i < entry.depth * 2 + 2) : (i += 2) std.debug.print("  ", .{});

        std.debug.print("{s: <25}: {d: <12} ({d:.2}%)\n", .{ entry.label, elapsed, percent });
    }

    std.debug.assert(timer_stack.items.len == 0);

    timer_stack.deinit();
    timer_entries.deinit();
    // timer_map.deinit();
}
